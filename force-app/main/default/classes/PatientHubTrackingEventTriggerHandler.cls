/**
* @description       : Handles Patient Hub Tracking Event Trigger operations, including processing
*                      events, creating hub tracking records, mapping fields, and publishing events.
* @author            : Ipsen
* @last modified on  : 08-12-2023
**/
public without sharing class PatientHubTrackingEventTriggerHandler {
    public static List<T_Hub_Tracking__c> hubTrackings = new List<T_Hub_Tracking__c>();
    public static List<String> sourceObjectNames = new List<String>{'Account','Case','CareProgramEnrollee','MemberPlan','J_Copay__c','J_Charitable__c','CarePreauth','PatientMedicationDosage','CareProgramProduct'};
        public static List<String> sourceObjectNamesForMultipleRecords = new List<String>{'J_Referral__c','PatientMedicationDosage'};
            /**
* @description       : Processes a list of Patient Hub Tracking Event Platform Events
*                      to create and insert hub tracking records.
* @param events      : List of Patient_Hub_Tracking_Event__e events to be processed.
**/ 
            public static void process(List<Patient_Hub_Tracking_Event__e> events){
                try{
                    // Iterate through each notification.
                    for (Patient_Hub_Tracking_Event__e event : events) {
                        //List<String> sourceObjects = getTrackinObjects(event.Patient_Status_Code__c);
                        populateHubTracking(event.Enrollee_Id__c, event.Patient_Id__c);
                    }
                    if(hubTrackings.size()>0){
                        insert hubTrackings; 
                    }
                }
                catch(Exception ex){
                    GenericLogger.exceptionLog('PatientHubTrackingEventTriggerHandler','process',ex);
                }
            }
    /**
* @description       : Populates a T_Hub_Tracking__c record for a given enrollee and patient.
* @param enrolleeId  : The ID of the Care Program Enrollee.
* @param patientId   : The ID of the Patient.
**/  
    public static void populateHubTracking(String enrolleeId, String patientId) {
        
        String sObjectType = 'RecordType';
        String fields = 'Id';
        String conditions = 'SObjectType = \'Case\' AND Name = \'CarePlan\'';
        
        List<RecordType> recordTypeResults = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
        
        Id carePlanRecordTypeId = recordTypeResults[0].id;
        
        T_Hub_Tracking__c hubTracking = new T_Hub_Tracking__c();
        hubTracking.PHI_Consent__c = 'N';
        hubTracking.HIPPA_Consent__c = 'N';
        hubTracking.Referral_Source__c = 'HUB';
        hubTracking.RX_Recieved__c = 'N';
        hubTracking.Primary_Prior_Authorization_Required__c = 'N';
        
        String enrolleeSObjectType = 'CareProgramEnrollee';
        String enrolleeFields = 'Id, HCP_Lead__c, HCP_Lead__r.Lead_ID__c, Lead.Lead_ID__c, LeadId, Status, Sub_Status__c, CareProgramId';
        String enrolleeConditions = 'Id = \'' + enrolleeId + '\'';
        List<CareProgramEnrollee> enrollee = COM_QueryUtility.executeQuery(enrolleeSObjectType, enrolleeFields, enrolleeConditions, true);
        
        // Process CareProgramProduct
        String cppSObjectType = 'CareProgramProduct';
        String cppFields = 'Id, Product.Name, CareProgramId';
        String cppConditions = 'CareProgramId = \'' + enrollee[0].CareProgramId + '\' LIMIT 1';
        List<CareProgramProduct> cpp = COM_QueryUtility.executeQuery(cppSObjectType, cppFields, cppConditions, true);
        
        hubTracking.Brand_Name__c = cpp[0].Product.Name;
        
        // Collect all source object names to query mappings in one go
        Map<String, List<Hub_Tracking_Field_Mapping__mdt>> sourceObjectToMappings = new Map<String, List<Hub_Tracking_Field_Mapping__mdt>>();
        
        String mdtSObjectType = 'Hub_Tracking_Field_Mapping__mdt';
        String mdtFields = 'Id, SourceField__c, Target_Object__r.QualifiedAPIName, Target_Field__r.QualifiedAPIName, Source_Object__r.QualifiedAPIName';
        String mdtConditions = 'Source_Object__r.QualifiedAPIName IN \'' + sourceObjectNames + '\'';
        List<Hub_Tracking_Field_Mapping__mdt> allHubTrackingMappings = COM_QueryUtility.executeQuery(mdtSObjectType, mdtFields, mdtConditions, true);
        
        // Query all necessary Hub Tracking Field Mappings at once
        /*List<Hub_Tracking_Field_Mapping__mdt> allHubTrackingMappings = [
SELECT Id, SourceField__c, Target_Object__r.QualifiedAPIName, Target_Field__r.QualifiedAPIName, 
Source_Object__r.QualifiedAPIName
FROM Hub_Tracking_Field_Mapping__mdt
WHERE Source_Object__r.QualifiedAPIName IN :sourceObjectNames
];*/
        
        // Group mappings by Source Object name
        for (Hub_Tracking_Field_Mapping__mdt mapping : allHubTrackingMappings) {
            String sourceObjectName = mapping.Source_Object__r.QualifiedAPIName;
            if (!sourceObjectToMappings.containsKey(sourceObjectName)) {
                sourceObjectToMappings.put(sourceObjectName, new List<Hub_Tracking_Field_Mapping__mdt>());
            }
            sourceObjectToMappings.get(sourceObjectName).add(mapping);
        }
        
        // Process each source object
        for (String sourceObjectName : sourceObjectNames) {
            List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappings = sourceObjectToMappings.get(sourceObjectName);
            SObject[] sourceObjectRecords = PatientHubTrackingQueryTriggerHandler.querySourceObject(enrolleeId, patientId, sourceObjectName, hubTrackingMappings);
            
            for (SObject sourceObject : sourceObjectRecords) {
                PatientHubTrackingCoverageBenefitHandler.mapSourceObjectToHubTracking(hubTracking, sourceObject, hubTrackingMappings, sourceObjectName);
            }
        }
        
        // Process Authorization Form Consent
        PatientHubTrackingQueryTriggerHandler.processAuthorizationFormConsent(enrolleeId, hubTracking);
        
        // Process Case and Coverage Benefit
        processCaseAndCoverageBenefit(enrolleeId, carePlanRecordTypeId, hubTracking);
        
        // Process J Charitable
        PatientHubTrackingQueryTriggerHandler.processJCharitable(enrolleeId, hubTracking);
        
        if (String.isBlank(hubTracking.Patient_State__c)) {
            hubTracking.Patient_State__c = 'NA';
        }
        
        if (String.isBlank(hubTracking.Referral_Source__c)) {
            hubTracking.Referral_Source__c = 'HUB';
        }
        
        hubTrackings.add(hubTracking);
        createMultipleRecords(enrolleeId, patientId);
    }
    
    // Helper method to handle J_Charitable specific field mappings
    
    
    /**
* @description       : Processes case and coverage benefit details for hub tracking.
* @param enrolleeId  : The ID of the Care Program Enrollee.
* @param carePlanRecordTypeId : Record Type ID for CarePlan.
* @param hubTracking : The T_Hub_Tracking__c record to update.
**/
    public static void processCaseAndCoverageBenefit(String enrolleeId, Id carePlanRecordTypeId, T_Hub_Tracking__c hubTracking) {
        
        String caseSObjectType = 'Case';
        String caseFields = 'Id, Disease__c';
        String caseConditions = 'Care_Program_Enrollee__c = ' + enrolleeId + ' AND RecordTypeId = \'' + carePlanRecordTypeId + '\'';
        List<Case> cs = COM_QueryUtility.executeQuery(caseSObjectType, caseFields, caseConditions, true);
        for (Case Tp : cs) {
            if (Tp.Disease__c == 'Fibrodysplasia Ossificans Progressiva (FOP)') {
                hubTracking.Indication__c = 'FOP';
            } else {
                hubTracking.Indication__c = Tp.Disease__c;
            }
        }
        String cbSObjectType = 'CoverageBenefit';
        String cbFields = 'Id, J_PriorAuthorizationRequired__c, J_BenefitType__c, MemberPlan.Status, MemberPlan.J_Role__c, J_CoPay__c, J_OOPMax__c';
        String cbConditions = 'Care_Program_Enrollee__c = \'' + enrolleeId + '\' AND J_CoverageBenefitStatus__c = \'Active\' LIMIT 3';
        
        // Pass the corrected parameters to the query utility
        List<CoverageBenefit> cb = COM_QueryUtility.executeQuery(cbSObjectType, cbFields, cbConditions, true);
        
        for (CoverageBenefit coverageBenefit : cb) {
            if (coverageBenefit.MemberPlan.Status == 'Active' && coverageBenefit.MemberPlan.J_Role__c == 'Primary') {
                if (coverageBenefit.J_PriorAuthorizationRequired__c == 'Yes') {
                    hubTracking.Primary_Prior_Authorization_Required__c = 'Y';
                }
                hubTracking.PRIMARY_BENEFIT_TYPE__c = coverageBenefit.J_BenefitType__c;
                hubTracking.PRIMARY_COPAY_AMOUNT__c = coverageBenefit.J_CoPay__c;
                hubTracking.FINAL_PATIENT_OUT_OF_POCKET_COST__c = coverageBenefit.J_OOPMax__c;
            }
            if (coverageBenefit.MemberPlan.Status == 'Active' && coverageBenefit.MemberPlan.J_Role__c == 'Secondary') {
                hubTracking.SECONDARY_BENEFIT_TYPE__c = coverageBenefit.J_BenefitType__c;
                hubTracking.SECONDARY_CO_PAY_AMOUNT__c = coverageBenefit.J_CoPay__c;
            }
        }
    }
    
    
    /**
* @description       : Creates multiple hub tracking records based on mappings for referrals and orders.
* @param enrolleeId  : The ID of the Care Program Enrollee.
* @param patientId   : The ID of the Patient.
**/
    public static void createMultipleRecords(String enrolleeId, String patientId) {
        List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForReferral = PatientHubTrackingQueryTriggerHandler.getHubTrackingMappings('J_Referral__c');
        List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForOrder = PatientHubTrackingQueryTriggerHandler.getHubTrackingMappings('J_Order__c');
        List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForPatientMedication = PatientHubTrackingQueryTriggerHandler.getHubTrackingMappings('PatientMedicationDosage');
        
        Map<String, SObject> ndcToReferralMap = PatientHubTrackingCoverageBenefitHandler.createReferralMap(enrolleeId, patientId, hubTrackingMappingsForReferral);
        Map<String, SObject> medicationDosageIdToOrderMap = PatientHubTrackingCoverageBenefitHandler.createOrderMap(enrolleeId, patientId, hubTrackingMappingsForOrder);
        SObject[] patientMedicationDosageRecords = PatientHubTrackingQueryTriggerHandler.querySourceObject(enrolleeId, patientId, 'PatientMedicationDosage', hubTrackingMappingsForPatientMedication);
        
        List<T_Hub_Tracking__c> hubTrackingList = new List<T_Hub_Tracking__c>(hubTrackings);
        
        for (T_Hub_Tracking__c populatedHubTracking : hubTrackingList) {
            processPatientMedicationDosageRecords(patientMedicationDosageRecords, populatedHubTracking, hubTrackingMappingsForReferral, hubTrackingMappingsForOrder, hubTrackingMappingsForPatientMedication, ndcToReferralMap, medicationDosageIdToOrderMap);
        }
    }
    
    
    
    private static void processPatientMedicationDosageRecords(SObject[] patientMedicationDosageRecords, T_Hub_Tracking__c populatedHubTracking, List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForReferral, List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForOrder, List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForPatientMedication, Map<String, SObject> ndcToReferralMap, Map<String, SObject> medicationDosageIdToOrderMap) {
        Integer count = 1;
        for (SObject sourceObject : patientMedicationDosageRecords) {
            T_Hub_Tracking__c hubTracking = PatientHubTrackingCoverageBenefitHandler.createHubTrackingInstance(populatedHubTracking, count);
            String ndcCode = null;
            String medicationDosageId = PatientHubTrackingQueryTriggerHandler.getFieldValue(sourceObject, 'Id');
            
            // Clear existing values
            PatientHubTrackingCoverageBenefitHandler.clearExistingFieldValues(hubTracking, hubTrackingMappingsForOrder, hubTrackingMappingsForReferral);
            
            // Set new field values
            PatientHubTrackingCoverageBenefitHandler.setPatientMedicationDosageValues(sourceObject, hubTracking, hubTrackingMappingsForPatientMedication, ndcCode);
            
            // Map referral data if applicable
            if (String.isNotBlank(ndcCode) && ndcToReferralMap.containsKey(ndcCode)) {
                PatientHubTrackingCoverageBenefitHandler.mapReferralData(ndcToReferralMap.get(ndcCode), hubTracking, hubTrackingMappingsForReferral);
            }
            
            // Map order data if applicable
            if (String.isNotBlank(medicationDosageId) && medicationDosageIdToOrderMap.containsKey(medicationDosageId)) {
                PatientHubTrackingCoverageBenefitHandler.mapOrderData(medicationDosageIdToOrderMap.get(medicationDosageId), hubTracking, hubTrackingMappingsForOrder);
            } else {
                hubTracking.RX_Recieved__c = 'N';
            }
            
            if (count > 1) {
                hubTrackings.add(hubTracking);
            }
            
            count++;
        }
    }
    /**
* @description       : Publishes Patient Hub Tracking Events for the provided enrollees.
* @param enrollees   : List of CareProgramEnrollee records to create events for.
**/
    public static void triggerEvent(List<CareProgramEnrollee> enrollees){
        
        List<Patient_Hub_Tracking_Event__e> trackingEvents = new List<Patient_Hub_Tracking_Event__e>();
        for(CareProgramEnrollee enrollee : enrollees){
            trackingEvents.add(new Patient_Hub_Tracking_Event__e(Enrollee_Id__c = enrollee.Id, Patient_Id__c = enrollee.AccountId));
        }
        
        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(trackingEvents);
        
        // Inspect publishing result for each event
        for (Database.SaveResult sr : results) {
            if (sr.isSuccess()) {
                GenericLogger.debugLog('Successfully published Hub.');
                
            } else {
                for(Database.Error err : sr.getErrors()) {
                    GenericLogger.debugLog('Error returned: ' +
                                           err.getStatusCode() +
                                           ' - ' +
                                           err.getMessage());
                }
            }       
        }
    }
}