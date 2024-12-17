public class J_HCPLeadPrescriptionProcessor {
    
    // public static void processPrescription(Id leadId, Map<Id, Lead> mapLead, Id careProgramEnrolleeId, List<Id> accountIds, Id enrolleeHcpId) {
    public static void processPrescription(J_HCPCaregiverConsentWrapper wrapper, List<Id> accountIds, Id enrolleeHcpId)  {
    Lead lead = wrapper.mapLead.get(wrapper.leadId);
        
        List<Lead_Prescription_Information__c> lstPrescription = J_HCPLeadPrescriptionHelper.fetchPrescriptions(wrapper.leadId);

        if ((lstPrescription != null && !lstPrescription.isEmpty())) {
            // Process Care Plan
            Id caseId = J_HCPLeadCarePlanHelper.processCarePlan(lead, wrapper.careProgramEnrolleeId);

            // Process Enrollee Products and Medication Dosages
            if (lstPrescription != null && !lstPrescription.isEmpty()) {
                J_HCPLeadPrescriptionHelper.processPrescriptions(lstPrescription, wrapper.careProgramEnrolleeId, caseId, accountIds[0], enrolleeHcpId);
            }	

            // Process Prior Authorization
            J_HCPLeadPriorAuthHelper.processPriorAuthorization(lead, wrapper.careProgramEnrolleeId, accountIds[0]);
        }
    }

}