/**
* @description       : This controller manages the calculation and retrieval of stage completion percentages for the timeline of a Care Program Enrollee.
*                      It uses JSON-defined configuration and enrollee-related records to determine the status of various stages.
* @author            : Anish
* @group             : 
* @last modified on  : 12-29-2024
*/
public with sharing class J_TimelineController {
    
    public static Map<String, Map<String, Integer>> referenceMap = new Map<String, Map<String, Integer>>();
    public static Map<String, Integer> mapStageCompletion = new Map<String, Integer>();
    public static Map<String, String> mapStageSubStatus = new Map<String, String>();
    
    /**
* @description Retrieves a map of stage completion percentages for the given enrollee.
* @param enrolleeId The ID of the Care Program Enrollee record.
* @return A map containing stage names as keys and their completion percentages as values.
*/
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getTimelineMap(Id enrolleeId) {
        try { 
            
            String sObjectType = 'J_Timeline_Configuration__mdt';
            String fields = 'TimelineConfig__c';
            List<J_Timeline_Configuration__mdt> configRecord = COM_QueryUtility.executeQuery(sObjectType, fields, '', true);
            // Use the retrieved JSON data
            String fullJsonData = configRecord[0].TimelineConfig__c;
            // Process the JSON to create the reference map
            referenceMap = processJSONForReferenceMap(fullJsonData);
            
            CareProgramEnrollee enrollee = queryEnrolleeRecords(enrolleeId);
            EnrolleeDataWrapper enrolleeData = new EnrolleeDataWrapper(enrollee);
            
            calculateEnrolment(enrolleeData);
            
            finalizeStageCompletion();
            
            return mapStageCompletion;
        } catch (Exception e) {
            throw new AuraHandledException('An unexpected error occurred. Please contact support.');
        }
    }
    
    private static CareProgramEnrollee queryEnrolleeRecords(Id enrolleeId) {
        
        return [
            SELECT 
            (SELECT Status__c, Sub_Status__c FROM Enrollee_History__r ORDER BY CreatedDate DESC),
            (SELECT J_ConsentStatus__c FROM Authorization_Form_Consents__r WHERE J_TypeOfConsent__c = 'Patient Authorization' ORDER BY CreatedDate DESC LIMIT 1),
            (SELECT J_Outcome__c, (SELECT Outcome__c FROM Authorizations__r WHERE Status = 'Active' ORDER BY CreatedDate DESC) FROM Coverage_Benefits__r WHERE J_CoverageBenefitStatus__c = 'Active' ORDER BY CreatedDate DESC LIMIT 1),
            (SELECT Status__c FROM Appeals__r ORDER BY CreatedDate DESC LIMIT 1),
            (SELECT J_Program_Type__c FROM Orders__r ORDER BY CreatedDate DESC LIMIT 1),
            (SELECT J_CharitableStatus__c FROM PAP_TPAPs__r ORDER BY CreatedDate DESC LIMIT 1)
            FROM CareProgramEnrollee
            WHERE Id = :enrolleeId WITH USER_MODE
        ];
    }
    
    private static void calculateEnrolment(
        EnrolleeDataWrapper enrolleeData
    ) {
        mapStageSubStatus.clear();
        
        for (String stage : referenceMap.keySet()) {
            for (Enrollee_History__c history : enrolleeData.historyRecords) {
                String statusSubStatusKey = generateStatusSubStatusKey(stage, enrolleeData, history);
                
                if (referenceMap.get(stage).containsKey(statusSubStatusKey)) {
                    mapStageSubStatus.put(stage, statusSubStatusKey);
                    break;
                }
            }
        }
    }
    
    private static String generateStatusSubStatusKey(
        String stage, EnrolleeDataWrapper enrolleeData, Enrollee_History__c history
    ) {
        if (stage == 'Patient Consent' && hasValidConsentRecords(enrolleeData)) {
            return buildKey(getPrimaryValue(enrolleeData.consentRecords[0].J_ConsentStatus__c), history);
        } else if (stage == 'Initial Benefit Verification' && hasValidCoverageBenefits(enrolleeData)) {
            return buildKey(getPrimaryValue(enrolleeData.coverageBenefits[0].J_Outcome__c), history);
        } else if (isPAPendingStage(stage) && hasValidCarePreauths(enrolleeData)) {
            return buildKey(getPrimaryValue(enrolleeData.carePreauths[0].Outcome__c), history);
        } else if (isPAApprovedOrShipmentStage(stage) && hasValidOrderRecords(enrolleeData)) {
            return buildKey(getPrimaryValue(enrolleeData.orderRecords[0].J_Program_Type__c), history);
        } else if (stage == 'PAP/TPAP Enrollment' && hasValidPAPRecords(enrolleeData)) {
            return buildKey(getPrimaryValue(enrolleeData.papRecords[0].J_CharitableStatus__c), history);
        } else {
            return buildKey(null, history);
        }
    }
    
    private static String buildKey(String primaryValue, Enrollee_History__c history) {
        return (primaryValue != null ? primaryValue : '') 
            + '_' + history.Status__c 
            + '_' + (history.Sub_Status__c != null ? history.Sub_Status__c : '');
    }
    
    private static boolean hasValidConsentRecords(EnrolleeDataWrapper enrolleeData) {
        return !enrolleeData.consentRecords.isEmpty();
    }
    
    private static boolean hasValidCoverageBenefits(EnrolleeDataWrapper enrolleeData) {
        return !enrolleeData.coverageBenefits.isEmpty();
    }
    
    private static boolean hasValidCarePreauths(EnrolleeDataWrapper enrolleeData) {
        return !enrolleeData.carePreauths.isEmpty();
    }
    
    private static boolean hasValidOrderRecords(EnrolleeDataWrapper enrolleeData) {
        return !enrolleeData.orderRecords.isEmpty();
    }
    
    private static boolean hasValidPAPRecords(EnrolleeDataWrapper enrolleeData) {
        return !enrolleeData.papRecords.isEmpty();
    }
    
    private static boolean isPAPendingStage(String stage) {
        return stage == 'PA-Pending-HCP' || stage == 'PA Submitted - Pending Payer';
    }
    
    private static boolean isPAApprovedOrShipmentStage(String stage) {
        return stage == 'PA Approved - Triaged to SP' || stage == 'PAP/TPAP Shipment';
    }
    
    private static String getPrimaryValue(String value) {
        return value != null ? value : '';
    }
    
    private static void finalizeStageCompletion() {
        for (String stage : referenceMap.keySet()) {
            if (mapStageSubStatus.containsKey(stage)) {
                String subStatusKey = mapStageSubStatus.get(stage);
                if (referenceMap.get(stage).containsKey(subStatusKey)) {
                    mapStageCompletion.put(stage, referenceMap.get(stage).get(subStatusKey));
                }
            }
        }
        
        // Default any missing stages to 0% completion
        for (String stage : referenceMap.keySet()) {
            if (!mapStageCompletion.containsKey(stage)) {
                mapStageCompletion.put(stage, 0);
            }
        }
    }
    /**
* @description Processes the given JSON configuration string into a reference map.
* @param fullJsonData A JSON string containing stage and sub-status completion data.
* @return A map containing stage names as keys and sub-status maps as values.
*/
    public static Map<String, Map<String, Integer>> processJSONForReferenceMap(String fullJsonData) {
        //System.debug('Processing JSON for Reference Map: ' + fullJsonData);
        return (Map<String, Map<String, Integer>>) JSON.deserialize(fullJsonData, Map<String, Map<String, Integer>>.class);
    }
    /**
* @description This class serves as a wrapper for enrollee data, aggregating various 
*              records related to an enrollee's history, consents, coverage benefits, 
*              pre-authorizations, appeals, orders, and charitable programs.
*/
    public class EnrolleeDataWrapper {
        public List<Enrollee_History__c> historyRecords;
        public List<AuthorizationFormConsent> consentRecords;
        public List<CoverageBenefit> coverageBenefits;
        public List<CarePreauth> carePreauths;
        public List<Appeal__c> appealRecords;
        public List<J_Order__c> orderRecords;
        public List<J_Charitable__c> papRecords;
        /**
* @description Constructs an instance of EnrolleeDataWrapper using the provided 
*              CareProgramEnrollee object. Initializes all relevant lists 
*              by extracting data from the enrollee object.
* 
* @param enrollee The CareProgramEnrollee object containing enrollee-related data.
*/
        public EnrolleeDataWrapper(CareProgramEnrollee enrollee) {
            this.historyRecords = enrollee.Enrollee_History__r;
            this.consentRecords = enrollee.Authorization_Form_Consents__r;
            this.coverageBenefits = enrollee.Coverage_Benefits__r;
            this.carePreauths = extractCarePreauths(coverageBenefits);
            this.appealRecords = enrollee.Appeals__r;
            this.orderRecords = enrollee.Orders__r;
            this.papRecords = enrollee.PAP_TPAPs__r;
        }
        /**
* @description Extracts a list of CarePreauth records from the given list of 
*              CoverageBenefit records by aggregating the Authorizations associated 
*              with each CoverageBenefit.
* 
* @param coverageBenefits A list of CoverageBenefit records from which to extract 
*                        CarePreauth records.
* @return A list of CarePreauth records extracted from the coverage benefits.
*/
        private List<CarePreauth> extractCarePreauths(List<CoverageBenefit> coverageBenefits) {
            List<CarePreauth> carePreauths = new List<CarePreauth>();
            for (CoverageBenefit cb : coverageBenefits) {
                carePreauths.addAll(cb.Authorizations__r);
            }
            return carePreauths;
        }
    }
}