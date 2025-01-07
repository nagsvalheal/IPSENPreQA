/**
 * @description       : Handles inbound processing for Journey SP orders and updates patient dosing information.
 *                      Includes utility methods for formatting descriptions and updating dosing records.
 * @author            : Vijay
 * @last modified on  : 05-12-2024
 * @version           : 1.0
 */
public with sharing class JourneySPInboundHandlerClass {
    /**
     * @description       : Formats a description based on the fields provided in the J_SP_Inbound__c object.
     *                      The description is segmented into Patient Demographics, Insurance Plan, and Prior Auth Details sections.
     * @param jsp         : The J_SP_Inbound__c record for which the description is to be formatted.
     * @return            : A string representing the formatted description.
     */
    @TestVisible
    private static string formatDescription(J_SP_Inbound__c jsp) {
        String description = '';
        if (hasPatientDemographics(jsp)) {
            description += 'Patient Demographics section ';
        }
        if (hasInsurancePlan(jsp)) {
            description = appendDescription(description, 'Insurance Plan section');
        }
        if (hasPriorAuthDetails(jsp)) {
            description = appendDescription(description, 'Prior Auth Details section.');
        }
        return description;
    }

    /**
     * @description       : Checks if the record has Patient Demographics-related fields populated.
     * @param jsp         : The J_SP_Inbound__c record.
     * @return            : True if any Patient Demographics fields are populated, otherwise false.
     */
    private static Boolean hasPatientDemographics(J_SP_Inbound__c jsp) {
        return jsp.Enrollee_ID__c != '' || jsp.J_HUB_Patient_ID__c != '' || jsp.J_HCP_FirstName__c != '' || jsp.J_HCP_LastName__c != '';
    }

    /**
     * @description       : Checks if the record has Insurance Plan-related fields populated.
     * @param jsp         : The J_SP_Inbound__c record.
     * @return            : True if any Insurance Plan fields are populated, otherwise false.
     */
    private static Boolean hasInsurancePlan(J_SP_Inbound__c jsp) {
        return jsp.J_INS_PP_Type__c != '' || jsp.J_INS_PP_Group_ID__c != '' || jsp.J_INS_PP_ID__c != '' || jsp.J_INS_PP_Name__c != '' || 
               jsp.J_INS_PP_Plan_Name__c != '' || jsp.J_INS_PP_PBM__c != '' || jsp.J_INS_SecP_Type__c != '' || jsp.J_INS_SecP_ID__c != '' || 
               jsp.J_INS_SecP_Name__c != '' || jsp.J_INS_SecP_State__c != '' || jsp.J_INS_SecP_Group_ID__c != '' || jsp.J_INS_SecP_Plan_Name__c != '' || 
               jsp.J_INS_PP_BIN__c != '';
    }

    /**
     * @description       : Checks if the record has Prior Auth Details-related fields populated.
     * @param jsp         : The J_SP_Inbound__c record.
     * @return            : True if any Prior Auth Details fields are populated, otherwise false.
     */
    private static Boolean hasPriorAuthDetails(J_SP_Inbound__c jsp) {
        return jsp.J_PA_Req__c != '' || jsp.J_PA_Date__c != null || jsp.J_PA_Exp_Date__c != null;
    }

    /**
     * @description       : Appends a section description to the existing description string.
     * @param currentDesc : The current description string.
     * @param section     : The section to append.
     * @return            : The updated description string.
     */
    private static String appendDescription(String currentDesc, String section) {
        if (currentDesc.contains('Patient Demographics') || currentDesc.contains('Insurance Plan')) {
            return currentDesc + 'and ' + section;
        }
        return currentDesc + section;
    }
   /**
     * @description       : Updates the "Current Dose Record" flag for patient medication dosage records based on the provided orders.
     *                      Ensures the most recent dosage is marked appropriately for each enrollee.
     * @param newOrder    : List of J_Order__c records representing the newly created or updated orders.
     */
    public static void updateCurrentDosing(List<J_Order__c> newOrder){
        try{
        set<id> enrolleeID = new Set<id>();
        set<id> orderID = new Set<id>();
        Map<id,string> mapOrderPMD = new Map<id,string>();
        for(J_Order__c o:newOrder){
            enrolleeID.add(o.Care_Program_Enrollee__c);
            orderID.add(o.id);
        }
        List<J_Order__c> orders=COM_QueryUtility.executeQuery(
            'J_Order__c',
            'id,Care_Program_Enrollee__c,Patient_Medication_Dosage__c,J_NDC_Number__c',
            'id in:\''+orderID+'\'',
            true
        );
        list<J_Order__c> order = new list<J_Order__c>(orders);
        for(J_Order__c o:order){
            mapOrderPMD.put(o.Patient_Medication_Dosage__c,o.J_NDC_Number__c);
        }
        List<PatientMedicationDosage> dosage = COM_QueryUtility.executeQuery(
          'PatientMedicationDosage',
          'id,Care_Program_Enrollee_Name__c,Care_Program_Enrollee_Product__c,Current_Dose_Record__c,NDC_Code__c',
          'Care_Program_Enrollee_Name__c in:\''+enrolleeID+'\'',
          true
);
        list<PatientMedicationDosage> dose = new list<PatientMedicationDosage>(dosage);
        for(PatientMedicationDosage pmd:dose){
            if(mapOrderPMD.containsKey(pmd.id)){
                pmd.Current_Dose_Record__c= true;
            }
            else{
                pmd.Current_Dose_Record__c= false;
            }
        }
       COM_DatabaseOperationsUtility.updateOperation(dose,'JourneySPInboundHandlerClass',true);
    }catch(Exception ex){
        GenericLogger.exceptionLog('JourneySPInboundHandlerClass', 'updateCurrentDosing', ex);
    }

 }

}