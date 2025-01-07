/**
 * @description This class is responsible for managing the creation and validation of Care Plan records 
 *              associated with a Lead and a specific Care Program Enrollee. It checks for existing Care Plans 
 *              and creates new ones if none exist.
 * @class J_HCPLeadCarePlanHelper
 * @sharing This class is declared as `without sharing`, meaning it runs in system context and ignores 
 *          the user's sharing rules to ensure all required data is accessible for processing.
 * @author [Nandha]
 * @date [17/12/2023]
 */
public without sharing class J_HCPLeadCarePlanHelper {
      /**
     * @description Processes the Care Plan for a given Lead and Care Program Enrollee.
     *              If a Care Plan does not exist, it creates a new one.
     * @param lead The Lead object containing details for Care Plan creation.
     * @param careProgramEnrolleeId The ID of the Care Program Enrollee associated with the Care Plan.
     * @return The ID of the existing or newly created Care Plan Case.
     */
     public static Id processCarePlan(Lead lead, Id careProgramEnrolleeId) {
        Id caseId;
        try{
       // RecordType treatmentRecType = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Case' AND Name = 'CarePlan' WITH SECURITY_ENFORCED LIMIT 1];
        Id treatmentRecType = COM_QueryUtility.retrieveRecordTypeId('Case', 'CarePlan');
        caseId = checkCarePlanExist(treatmentRecType, careProgramEnrolleeId);
        if (caseId == null) {
            Case c = new Case(
                Care_Program_Enrollee__c = careProgramEnrolleeId,
                Status = 'Pending',
                RecordTypeId = treatmentRecType,
                J_PreferredSpecialtyPharmacy__c = lead.PreferredSpecialtyPharmacy0__c,
                J_RXSent__c = lead.RxSent__c,
                Other_Diagnosis__c = lead.Other_diagnosis__c,
                J_Other_ICD_10_Code__c = lead.J_Secondary_ICD_10_Code__c,
                J_SpecialtyPharmacyName__c = lead.SpecialtyPharmacyName__c,
                Weight_at_Enrollment_in_Kg__c = lead.Kg_weight__c,
                Date_of_Patient_Weight__c = lead.J_Date_Measured__c,
                Disease__c = lead.J_Primary_Diagnosis__c,
                J_Primary_ICD_10_Code__c = lead.J_Primary_ICD_10_Code__c,
                Diagnosis_Date__c = lead.DateofDiagnosisMMDDYY__c,
                Pruritus__c = lead.J_Pruritus__c ? 'Yes' : 'No',
                J_PFIC_Type__c = lead.PFIC_type__c
            );
            Database.SaveResult[] insertResults = COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{c}, 'Case', false);

            if (insertResults != null && insertResults.size() > 0 && insertResults[0].isSuccess()) {
                caseId = insertResults[0].getId();
            }
        }
    }catch(Exception e){
        // Log any errors to the debug log
        GenericLogger.exceptionLog('J_HCPLeadCarePlanHelper','processCarePlan',  e);
    }
        return caseId;
    }
    /**
     * @description Checks if a Care Plan exists for a given Record Type and Care Program Enrollee. 
     *              If a matching Care Plan is found, its ID is returned; otherwise, null is returned.
     * @method checkCarePlanExist
     * @param recTypeId The RecordType object representing the Care Plan record type.
     * @param patient The ID of the Care Program Enrollee to check for an existing Care Plan.
     * @return Id The ID of the existing Care Plan, or null if no matching Care Plan exists.
     */
    public static Id checkCarePlanExist(Id recTypeId, String patient) {
        try{
        // Check if the RecordTypeId is not null
        if (recTypeId != null) {
            // Define fields and conditions for the Case query
            String caseFields = 'Id, CaseNumber';
            String caseConditions = 'RecordTypeId = \'' + recTypeId + '\' AND Care_Program_Enrollee__c = \'' + patient + '\'';
            
            Boolean withUserMode = false;  // Set to true if you want to enforce user mode (sharing rules)
        
            // Call the executeQuery method to retrieve cases
            List<SObject> caseResult = COM_QueryUtility.executeQuery('Case', caseFields, caseConditions, withUserMode);
        
            // Convert the result to a Case list
            Case[] cs = (List<Case>)caseResult;
        
            // Return the ID of the first matching Case, or null if no Case found
            return cs.isEmpty() ? null : cs[0].Id;
        }
     } catch(Exception e){
            // Log any errors to the debug log
            GenericLogger.exceptionLog('J_HCPLeadCarePlanHelper','checkCarePlanExist',  e);
        }
        // Return null if the RecordTypeId is null
        return null;
    }
    
    

}