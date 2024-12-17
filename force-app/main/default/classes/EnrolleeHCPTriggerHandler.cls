/**
 * @description Handler class for managing operations on Enrollee_HCP__c trigger events.
 * This class contains methods to handle after-insert and after-update operations for Enrollee_HCP__c records.
 */
public with sharing class EnrolleeHCPTriggerHandler {

    /**
     * @description Handles the after-insert trigger event for Enrollee_HCP__c records.
     * Updates associated CareProgramEnrollee records when Enrollee_HCP__c records are inserted with 'Active' status.
     *
     * @param triggerNew List of newly inserted Enrollee_HCP__c records.
     */
    public void afterInsertMethod(List<Enrollee_HCP__c> triggerNew) {
        // Map to store CareProgramEnrollee IDs and corresponding Enrollee_HCP__c records
        Map<Id, Enrollee_HCP__c> enrolleeHcpMap = new Map<Id, Enrollee_HCP__c>();
        List<CareProgramEnrollee> enrolleesToUpdate = new List<CareProgramEnrollee>();

        // Populate the map with Enrollee_HCP__c records having 'Active' status
        for (Enrollee_HCP__c enrolleeHCP : triggerNew) {
            if (enrolleeHCP.Status__c == 'Active') {
                if (enrolleeHCP.Care_Program_Enrollee__c != null && enrolleeHCP.HCP__c != null) {
                    enrolleeHcpMap.put(enrolleeHCP.Care_Program_Enrollee__c, enrolleeHCP);
                }
            }
        }

        // Retrieve associated CareProgramEnrollee records for updates
        if (enrolleeHcpMap.size() > 0) {
            for (CareProgramEnrollee enrollee : [
                SELECT Id, ProviderEmail__c, Physician__c, Bypass_Apex__c 
                FROM CareProgramEnrollee 
                WHERE Id = :enrolleeHcpMap.keySet()
                WITH SECURITY_Enforced           
                 ]) {
                // Update the CareProgramEnrollee record fields based on Enrollee_HCP__c data
                //Contact hcp = [Select Id, J_Email_ListView__c from Contact where Id =: enrolleeHCP.HCP__c LIMIT 1];
                //System.debug('Provider Email is:' + enrolleeHCP.HCP__r.J_Email_ListView__c);
                enrollee.ProviderEmail__c = enrolleeHcpMap.get(enrollee.Id).HCP_Email__c;
                enrollee.Physician__c = enrolleeHcpMap.get(enrollee.Id).HCP__c;
                enrollee.Bypass_Apex__c = !enrollee.Bypass_Apex__c; // Toggle the Bypass_Apex__c value
                enrolleesToUpdate.add(enrollee);
            }
        }

        // Perform DML update on CareProgramEnrollee records if there are updates to process
        if (!enrolleesToUpdate.isEmpty()) {
            try {
                Map<Id, CareProgramEnrollee> enrolleeMap = new Map<Id, CareProgramEnrollee>();
                enrolleeMap.putAll(enrolleesToUpdate);

                if (!enrolleeMap.isEmpty()) {
                    update enrolleeMap.values();
                }
            } catch (DMLException e) {
                System.Debug('Error while updating enrollee record with Physician email information: ' + e.getMessage());
            }
        }
    }

    /**
     * @description Handles the after-update trigger event for Enrollee_HCP__c records.
     * Updates associated CareProgramEnrollee records based on changes to the Enrollee_HCP__c Status__c field.
     *
     * @param triggerNew List of updated Enrollee_HCP__c records.
     * @param triggeroldMap Map of old Enrollee_HCP__c records with their corresponding IDs.
     */
    public void afterUpdateMethod(List<Enrollee_HCP__c> triggerNew, Map<Id, Enrollee_HCP__c> triggeroldMap) {
        // Map to store CareProgramEnrollee IDs and corresponding Enrollee_HCP__c records
        Map<Id, Enrollee_HCP__c> enrolleeHcpMap = new Map<Id, Enrollee_HCP__c>();
        List<CareProgramEnrollee> enrolleesToUpdate = new List<CareProgramEnrollee>();

        // Identify records with changes in Status__c or with 'Active' status
        for (Enrollee_HCP__c enrolleeHCP : triggerNew) {
            if ((enrolleeHCP.Status__c != triggeroldMap.get(enrolleeHCP.Id).Status__c) || enrolleeHCP.Status__c == 'Active') {
                enrolleeHcpMap.put(enrolleeHCP.Care_Program_Enrollee__c, enrolleeHCP);
            }
        }

        // Retrieve and update associated CareProgramEnrollee records based on Enrollee_HCP__c status
        if (enrolleeHcpMap.size() > 0) {
            for (CareProgramEnrollee enrollee : [
                SELECT Id, ProviderEmail__c, Physician__c, Bypass_Apex__c 
                FROM CareProgramEnrollee 
                WHERE Id = :enrolleeHcpMap.keySet()
                WITH SECURITY_Enforced
            ]) {
                if (enrolleeHcpMap.get(enrollee.Id).Status__c == 'Active') {
                    //Contact hcp = [Select Id, J_Email_ListView__c from Contact where Id =: enrolleeHCP.HCP__c LIMIT 1];
                    //System.debug('Provider Email is:' + enrolleeHCP.HCP__r.J_Email_ListView__c);
                    enrollee.ProviderEmail__c = enrolleeHcpMap.get(enrollee.Id).HCP_Email__c;
                    enrollee.Physician__c = enrolleeHcpMap.get(enrollee.Id).HCP__c;
                    enrollee.Bypass_Apex__c = !enrollee.Bypass_Apex__c; // Toggle the Bypass_Apex__c value
                } else {
                    // Clear ProviderEmail__c and Physician__c fields for inactive records
                    enrollee.ProviderEmail__c = '';
                    enrollee.Physician__c = null;
                }
                enrolleesToUpdate.add(enrollee);
            }
        }

        // Perform DML update on CareProgramEnrollee records if there are updates to process
        if (!enrolleesToUpdate.isEmpty()) {
            Map<Id, CareProgramEnrollee> enrolleeMap = new Map<Id, CareProgramEnrollee>();
            enrolleeMap.putAll(enrolleesToUpdate);

            if (!enrolleeMap.isEmpty()) {
                update enrolleeMap.values();
            }
        }
    }
}