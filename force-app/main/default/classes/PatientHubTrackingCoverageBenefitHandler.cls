/**
 * @description Handles operations related to patient hub tracking for coverage benefits.
 *              Provides methods to set coverage benefits, charitable program details, default values,
 *              create hub tracking records, and publish events.
 * @author Vijay
 * @date 09-12-2024
 */
public with sharing class PatientHubTrackingCoverageBenefitHandler { 
    /**
     * @description Creates a hub tracking instance based on the count. 
     *              If the count is 1, the existing populated hub tracking is returned, 
     *              otherwise a clone is created.
     * @param populatedHubTracking The populated instance of T_Hub_Tracking__c to be cloned or returned.
     * @param count The number determining whether to clone or return the instance.
     * @return The created or cloned instance of T_Hub_Tracking__c.
     */
public static T_Hub_Tracking__c createHubTrackingInstance(T_Hub_Tracking__c populatedHubTracking, Integer count) {
    return (count == 1) ? populatedHubTracking : populatedHubTracking.clone(false, true, false, false);
}
/**
     * @description Clears existing field values in the provided hub tracking record.
     *              The values are cleared based on the field mappings for order and referral.
     * @param hubTracking The T_Hub_Tracking__c instance whose fields need to be cleared.
     * @param hubTrackingMappingsForOrder List of field mappings for order data.
     * @param hubTrackingMappingsForReferral List of field mappings for referral data.
     */
public static void clearExistingFieldValues(T_Hub_Tracking__c hubTracking, List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForOrder, List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForReferral) {
    for (Hub_Tracking_Field_Mapping__mdt hubTrackingmapping : hubTrackingMappingsForOrder) {
        hubTracking.put(hubTrackingmapping.Target_Field__r.QualifiedAPIName, '');
    }
    for (Hub_Tracking_Field_Mapping__mdt hubTrackingmapping : hubTrackingMappingsForReferral) {
        hubTracking.put(hubTrackingmapping.Target_Field__r.QualifiedAPIName, '');
    }
}
/**
     * @description Maps patient medication dosage data to the hub tracking instance. 
     *              This also updates the NDC code in the provided variable.
     * @param sourceObject The source object containing the data to be mapped.
     * @param hubTracking The T_Hub_Tracking__c instance where the mapped data will be placed.
     * @param hubTrackingMappingsForPatientMedication List of field mappings for patient medication data.
     * @param ndcCode A variable that will hold the NDC code from the source object.
     */
public static void setPatientMedicationDosageValues(SObject sourceObject, T_Hub_Tracking__c hubTracking, List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForPatientMedication, String ndcCode) {
    for (Hub_Tracking_Field_Mapping__mdt hubTrackingmapping : hubTrackingMappingsForPatientMedication) {
        String fieldValue = PatientHubTrackingQueryTriggerHandler.getFieldValue(sourceObject, hubTrackingmapping.SourceField__c);
        hubTracking.put(hubTrackingmapping.Target_Field__r.QualifiedAPIName, fieldValue);

        if (hubTrackingmapping.SourceField__c == 'NDC_Code__c') {
            ndcCode = fieldValue;
        }
    }
}
/**
     * @description Maps referral data to the hub tracking instance. 
     *              The method loops through the mappings and assigns the values to the appropriate fields.
     * @param referral The referral record to be mapped.
     * @param hubTracking The T_Hub_Tracking__c instance where the referral data will be placed.
     * @param hubTrackingMappingsForReferral List of field mappings for referral data.
     */
public static void mapReferralData(SObject referral, T_Hub_Tracking__c hubTracking, List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForReferral) {
    for (Hub_Tracking_Field_Mapping__mdt hubTrackingmapping : hubTrackingMappingsForReferral) {
        hubTracking.put(hubTrackingmapping.Target_Field__r.QualifiedAPIName, PatientHubTrackingQueryTriggerHandler.getFieldValue(referral, hubTrackingmapping.SourceField__c));
    }
}
/**
     * @description Maps order data to the hub tracking instance and sets the RX Received field to 'Y'.
     * @param order The order record to be mapped.
     * @param hubTracking The T_Hub_Tracking__c instance where the order data will be placed.
     * @param hubTrackingMappingsForOrder List of field mappings for order data.
     */
public static void mapOrderData(SObject order, T_Hub_Tracking__c hubTracking, List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappingsForOrder) {
    for (Hub_Tracking_Field_Mapping__mdt hubTrackingmapping : hubTrackingMappingsForOrder) {
        hubTracking.put(hubTrackingmapping.Target_Field__r.QualifiedAPIName, PatientHubTrackingQueryTriggerHandler.getFieldValue(order, hubTrackingmapping.SourceField__c));
        hubTracking.RX_Recieved__c = 'Y';
    }
}
/**
     * @description Creates a map of NDC codes to referral records based on the enrollee ID and patient ID. 
     *              The map is built using a list of field mappings.
     * @param enrolleeId The enrollee ID to filter the referrals.
     * @param patientId The patient ID to filter the referrals.
     * @param mappings The field mappings used to query and map the data.
     * @return A map where the keys are NDC codes and the values are the corresponding referral records.
     */    
    public static Map<String, SObject> createReferralMap(String enrolleeId, String patientId, List<Hub_Tracking_Field_Mapping__mdt> mappings) {
    Map<String, SObject> ndcToReferralMap = new Map<String, SObject>();
    for (SObject referralRecord : PatientHubTrackingQueryTriggerHandler.querySourceObject(enrolleeId, patientId, 'J_Referral__c', mappings)) {
        ndcToReferralMap.put(PatientHubTrackingQueryTriggerHandler.getFieldValue(referralRecord, 'NDC_Code__c'), referralRecord);
    }
    return ndcToReferralMap;
}
/**
     * @description Creates a map of medication dosage IDs to order records based on the enrollee ID and patient ID.
     *              The map is constructed using the provided mappings.
     * @param enrolleeId The enrollee ID to filter the orders.
     * @param patientId The patient ID to filter the orders.
     * @param mappings The field mappings used to query and map the data.
     * @return A map where the keys are medication dosage IDs and the values are the corresponding order records.
     */
public static Map<String, SObject> createOrderMap(String enrolleeId, String patientId, List<Hub_Tracking_Field_Mapping__mdt> mappings) {
    Map<String, SObject> medicationDosageIdToOrderMap = new Map<String, SObject>();
    for (SObject orderRecord : PatientHubTrackingQueryTriggerHandler.querySourceObject(enrolleeId, patientId, 'J_Order__c', mappings)) {
        medicationDosageIdToOrderMap.put(PatientHubTrackingQueryTriggerHandler.getFieldValue(orderRecord, 'Patient_Medication_Dosage__c'), orderRecord);
    }
    return medicationDosageIdToOrderMap;
}
/**
     * @description Maps the fields of a source object to the hub tracking instance based on field mappings.
     *              This includes handling specific mappings for MemberPlan and J_Charitable__c objects.
     * @param hubTracking The T_Hub_Tracking__c instance to which the source data will be mapped.
     * @param sourceObject The source object containing the data to be mapped.
     * @param hubTrackingMappings The list of field mappings used to map the data.
     * @param sourceObjectName The name of the source object (e.g., MemberPlan, J_Charitable__c).
     */
public static void mapSourceObjectToHubTracking(T_Hub_Tracking__c hubTracking, SObject sourceObject, List<Hub_Tracking_Field_Mapping__mdt> hubTrackingMappings, String sourceObjectName) {
    for (Hub_Tracking_Field_Mapping__mdt hubTrackingMapping : hubTrackingMappings) {
        String fieldName = hubTrackingMapping.Target_Field__r.QualifiedAPIName;
        
        // Handle MemberPlan SourceObject
        if (sourceObjectName == 'MemberPlan') {
            PatientHubTrackingQueryTriggerHandler.mapMemberPlanFields(hubTracking, sourceObject, hubTrackingMapping, fieldName);
        } 
        // Handle J_Charitable__c SourceObject
        else if (sourceObjectName == 'J_Charitable__c') {
            PatientHubTrackingQueryTriggerHandler.mapJCharitableFields(hubTracking, sourceObject, hubTrackingMapping, fieldName);
        } 
        // For other SourceObjects
        else {
            hubTracking.put(fieldName, PatientHubTrackingQueryTriggerHandler.getFieldValue(sourceObject, hubTrackingMapping.SourceField__c));
        }
    }
}

}