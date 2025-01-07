/**
 * @description This class handles the logic for querying and processing patient hub tracking data. 
 * It contains methods for dynamic queries, field mapping, and processing specific objects like MemberPlan, 
 * J_Charitable, AuthorizationFormConsent, and more, based on specific enrollee and patient conditions.
 */
public with sharing class PatientHubTrackingQueryTriggerHandler {
    /**
     * @description Queries the source object based on provided parameters, including enrolleeId, patientId, 
     * and field mappings. Dynamically builds the query with source fields and WHERE conditions.
     * @param enrolleeId The enrollee ID to filter results.
     * @param patientId The patient ID to filter results.
     * @param sourceObjectName The source object name to query data from.
     * @param hubTrackingMappings List of Hub_Tracking_Field_Mapping__mdt metadata records used to map fields.
     * @return A list of SObjects representing the query results.
     */
     public static SObject[] querySourceObject(String enrolleeId, String patientId, String sourceObjectName, List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappings) {
    String query = 'SELECT Id';

    // Collect source fields dynamically, ensuring no duplicates
    Set<String> sourceFields = new Set<String>();
    for (Hub_Tracking_Field_Mapping__mdt hubTrackingMapping : hubTrackingMappings) {
        if (hubTrackingMapping.SourceField__c != 'Id') {
            sourceFields.add(hubTrackingMapping.SourceField__c);
        }
    }

    // Add source fields to the query
    query += buildSourceFieldsQuery(sourceFields, sourceObjectName);

    // Build the main object name and conditions
    query += ' FROM ' + sourceObjectName + buildWhereClause(sourceObjectName, enrolleeId, patientId);

    // Order by CreatedDate
    query += ' ORDER BY CreatedDate ASC';

    return Database.query(query);
}
/**
     * @description Builds the SELECT clause of the query dynamically, adding relevant fields based on the source object.
     * @param sourceFields A set of field names to include in the SELECT clause.
     * @param sourceObjectName The source object name to customize the query for specific fields.
     * @return A string representing the fields part of the query.
     */
// Helper function to add source fields to the query
private static String buildSourceFieldsQuery(Set<String> sourceFields, String sourceObjectName) {
    String fieldsQuery = '';
    
    // Add fields from sourceFields set
    for (String sourceField : sourceFields) {
        fieldsQuery += ', ' + sourceField;
    }

    // Add specific fields for particular objects
    Map<String, String> specificFields = new Map<String, String> {
        'MemberPlan' => ', J_Role__c',
        'J_Charitable__c' => ', J_CharitableProgramType__c',
        'J_Referral__c' => ', NDC_Code__c',
        'J_Order__c' => ', Patient_Medication_Dosage__c',
        'PatientMedicationDosage' => ', Unit_Daily_Dose__c, Patients_Current_Prescribed_Dose__c'
    };

    if (specificFields.containsKey(sourceObjectName)) {
        fieldsQuery += specificFields.get(sourceObjectName);
    }

    return fieldsQuery;
}
/**
     * @description Builds the WHERE clause of the query based on the source object and enrollee or patient IDs.
     * @param sourceObjectName The name of the source object to construct appropriate WHERE conditions.
     * @param enrolleeId The enrollee ID for filtering.
     * @param patientId The patient ID for filtering.
     * @return A string representing the WHERE clause of the query.
     */
// Helper function to build the WHERE clause based on the source object
private static String buildWhereClause(String sourceObjectName, String enrolleeId, String patientId) {
    String whereClause = '';
    
    // Map of source object names and their respective WHERE conditions
    Map<String, String> whereConditions = new Map<String, String> {
        'CareProgramEnrollee' => ' WHERE Id = :enrolleeId',
        'Account' => ' WHERE Id = :patientId',
        'J_Referral__c' => ' WHERE Care_Program_Enrollee__c = :enrolleeId AND Status__c = \'Active\'',
        'MemberPlan' => ' WHERE MemberId = :patientId AND Status = \'Active\'',
        'J_Copay__c' => ' WHERE Care_Program_Enrollee__c = :enrolleeId AND J_CurrentCopayStatus__c = \'Active\'',
        'J_Charitable__c' => ' WHERE Care_Program_Enrollee__c = :enrolleeId',
        'J_Order__c' => ' WHERE Care_Program_Enrollee__c = :enrolleeId',
        'PatientMedicationDosage' => ' WHERE Care_Program_Enrollee_Name__c = :enrolleeId AND Current_Dose_Record__c = True',
        'CarePreauth' => ' WHERE Care_Program_Enrollee__c = :enrolleeId AND Status = \'Active\'',
        'CoverageBenefit' => ' WHERE Care_Program_Enrollee__c = :enrolleeId',
        'Case' => ' WHERE Care_Program_Enrollee__c = :enrolleeId'
    };

    if (whereConditions.containsKey(sourceObjectName)) {
        whereClause = whereConditions.get(sourceObjectName);
    }

    return whereClause;
}

  /**
     * @description Retrieves the value of a specific field from an SObject, including handling nested fields (e.g., Account.Name).
     * @param obj The SObject to retrieve the field value from.
     * @param inputFieldName The field name or nested field name (e.g., Account.Name).
     * @return The value of the field as a String, formatted for dates if applicable.
     */  
    public static String getFieldValue(SObject obj, String inputFieldName){
        Object fieldValue;
        if(inputFieldName.contains('.')){
            String objectName = inputFieldName.substringBefore('.');
            String fieldName = inputFieldName.substringAfter('.');
            fieldValue = obj.getSobject(objectName)?.get(fieldName);
        }
        else{
            fieldValue = obj.get(inputFieldName);
        }
        
        if(inputFieldName.containsIgnoreCase('date')){
            Date dateValue = Date.valueOf(fieldValue);
            return String.valueOf(dateValue)?.replaceAll('-','');
        }
        
        else{
            return String.valueOf(fieldValue);
        }
    }
    // Method to process J Charitable
    /**
     * @description Processes the J_Charitable object and updates the hub tracking record with relevant data.
     * @param enrolleeId The enrollee ID to filter J_Charitable records.
     * @param hubTracking The T_Hub_Tracking__c record to update with processed data.
     */
public static void processJCharitable(String enrolleeId, T_Hub_Tracking__c hubTracking) {
    	String cbSObjectType = 'J_Charitable__c';
        String cbFields = 'Id, J_CharitableProgramType__c, J_Enrollment_End_Date__c';
        String cbConditions = 'Care_Program_Enrollee__c = \'' + enrolleeId + '\' AND J_CharitableStatus__c = \'Active\'';
        
        // Pass the corrected parameters to the query utility
        List<J_Charitable__c> papRecords = COM_QueryUtility.executeQuery(cbSObjectType, cbFields, cbConditions, true);
    	J_Charitable__c papTpap=papRecords[0];
        if (papTpap.J_CharitableProgramType__c == 'TPAP') {
            hubTracking.TPAP_Expiration_Date__c = String.valueOf(papTpap.J_Enrollment_End_Date__c)?.replaceAll('-', '');
        }
}
    /**
     * @description Retrieves field mappings for a given object to assist in dynamic field mapping in queries.
     * @param objectName The object name to retrieve field mappings for.
     * @return A list of Hub_Tracking_Field_Mapping__mdt records for the specified object.
     */
    public static List<Hub_Tracking_Field_Mapping__mdt> getHubTrackingMappings(String objectName) {
        String cbSObjectType = 'Hub_Tracking_Field_Mapping__mdt';
        String cbFields = 'Id, SourceField__c, Target_Object__r.QualifiedAPIName, Target_Field__r.QualifiedAPIName ';
        String cbConditions = 'Source_Object__r.QualifiedAPIName = :\'' + objectName + '\'';
        
        // Pass the corrected parameters to the query utility
        List<Hub_Tracking_Field_Mapping__mdt> hub = COM_QueryUtility.executeQuery(cbSObjectType, cbFields, cbConditions, true);
    	return hub;
}
    /**
     * @description Maps fields from the MemberPlan object to the hub tracking record based on the role.
     * @param hubTracking The T_Hub_Tracking__c record to update.
     * @param sourceObject The MemberPlan source object to extract data from.
     * @param hubTrackingMapping The field mapping metadata.
     * @param fieldName The field name in the hub tracking record to update.
     */
    // Helper method to handle MemberPlan specific field mappings
public static void mapMemberPlanFields(T_Hub_Tracking__c hubTracking, SObject sourceObject, Hub_Tracking_Field_Mapping__mdt hubTrackingMapping, String fieldName) {
    String role = (String) sourceObject.get('J_Role__c');
     
    // Check if the mapping corresponds to 'Primary' or 'Secondary' role
    if (role == 'Primary' && fieldName.containsIgnoreCase('Primary')) {
        hubTracking.put(fieldName, PatientHubTrackingQueryTriggerHandler.getFieldValue(sourceObject, hubTrackingMapping.SourceField__c));
    } else if (role == 'Secondary' && fieldName.containsIgnoreCase('Secondary')) {
        hubTracking.put(fieldName, PatientHubTrackingQueryTriggerHandler.getFieldValue(sourceObject, hubTrackingMapping.SourceField__c));
    }
}
/**
 * @description Maps fields from a source object to a T_Hub_Tracking__c object based on the program type and field name.
 * 
 * @param hubTracking The target T_Hub_Tracking__c object where the field value will be mapped.
 * @param sourceObject The source SObject from which field values are retrieved.
 * @param hubTrackingMapping The Hub_Tracking_Field_Mapping__mdt metadata object that provides the mapping configuration.
 * @param fieldName The name of the field to be mapped.
 */
    public static void mapJCharitableFields(T_Hub_Tracking__c hubTracking, SObject sourceObject, Hub_Tracking_Field_Mapping__mdt hubTrackingMapping, String fieldName) {
    String programType = (String) sourceObject.get('J_CharitableProgramType__c');
    
    // Map based on TPAP program type
    if (programType == 'TPAP' && fieldName.containsIgnoreCase('TPAP')) {
        hubTracking.put(fieldName, PatientHubTrackingQueryTriggerHandler.getFieldValue(sourceObject, hubTrackingMapping.SourceField__c));
    } 
    // Map based on non-TPAP program type 
    else if (programType != 'TPAP' && !fieldName.containsIgnoreCase('TPAP')) {
        hubTracking.put(fieldName, PatientHubTrackingQueryTriggerHandler.getFieldValue(sourceObject, hubTrackingMapping.SourceField__c));
    }
}
/**
     * @description Processes the AuthorizationFormConsent object and updates the hub tracking record with relevant consent data.
     * @param enrolleeId The enrollee ID to filter AuthorizationFormConsent records.
     * @param hubTracking The T_Hub_Tracking__c record to update with processed consent data.
     */

// Method to process Authorization Form Consent
public static void processAuthorizationFormConsent(String enrolleeId, T_Hub_Tracking__c hubTracking) {
    	String cbSObjectType = 'AuthorizationFormConsent';
        String cbFields = 'Id, J_ConsentExpirationDate__c, J_ConsentStatus__c, Signatured_Date_PHI__c';
        String cbConditions = 'Care_Program_Enrollee__c = \'' + enrolleeId + '\' AND J_TypeOfConsent__c = \'Patient Authorization\'';
        
        // Pass the corrected parameters to the query utility
        List<AuthorizationFormConsent> auth = COM_QueryUtility.executeQuery(cbSObjectType, cbFields, cbConditions, true);
    for (AuthorizationFormConsent consent : auth) {
        hubTracking.Consent_Expiration_Date__c = String.valueOf(consent.J_ConsentExpirationDate__c)?.replaceAll('-', '');
        if (consent.J_ConsentStatus__c == 'Active') {
            hubTracking.PHI_Consent__c = 'Y';
            hubTracking.HIPPA_Consent__c = 'Y';
            Date hippaConsentDate = consent.J_ConsentExpirationDate__c;
            hubTracking.HIPPA_Consent_Date__c = String.valueOf(hippaConsentDate)?.replaceAll('-', '');
        }
    }
}
}