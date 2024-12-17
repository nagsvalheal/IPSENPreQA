/**
 * @class ContactUpdateTriggerHandler
 * @description This class contains logic for handling updates to physician contact records. 
 *              It is triggered when a physician's email is updated and subsequently updates 
 *              related Enrollee_HCP__c and PatientMedicationDosage records with the new email.
 * @author Isha
 * @date 25/11/2024 modified
 */
public with sharing class ContactUpdateTriggerHandler {

    /**
     * @method updatePhysicianEmail
     * @description This method checks if a physician's email has been updated. If so, it updates the 
     *              related Enrollee_HCP__c and PatientMedicationDosage records with the new email address.
     * @param physicians List<Contact> - A list of Contact records representing physicians.
     * @param oldValues Map<Id, Contact> - A map of the old values of the Contact records before the update.
     * @returns void
     */
    public void updatePhysicianEmail(List<Contact> physicians, Map<Id, Contact> oldValues) {
        Set<Id> updatedEmailContacts = getUpdatedEmailContacts(physicians, oldValues);
        
        if (updatedEmailContacts.isEmpty()) {
            return;  // Exit early if no contacts were updated
        }

        List<Enrollee_HCP__c> updatedHCPs = getUpdatedHCPs(updatedEmailContacts);
        if (updatedHCPs.isEmpty()) {
            return;  // Exit early if no HCP records found
        }

        List<PatientMedicationDosage> pmdosages = getPatientMedicationDosages(updatedHCPs);
        if (pmdosages.isEmpty()) {
            return;  // Exit early if no PMDosages found
        }

        Set<Id> enrolleeIdsToQuery = getEnrolleeIds(pmdosages);
        Map<Id, CareProgramEnrollee> careProgramEnrollees = getCareProgramEnrollees(enrolleeIdsToQuery);

        List<CareProgramEnrollee> enrolleesToUpdate = getEnrolleesToUpdate(pmdosages, careProgramEnrollees);
        if (!enrolleesToUpdate.isEmpty()) {
            // Validate CRUD permissions before update
            if (Schema.sObjectType.CareProgramEnrollee.fields.ProviderEmail__c.isUpdateable()) {
                updateCareProgramEnrollees(enrolleesToUpdate);
            } 
        }
    }

    // Helper Methods

    private Set<Id> getUpdatedEmailContacts(List<Contact> physicians, Map<Id, Contact> oldValues) {
        Set<Id> updatedEmailContacts = new Set<Id>();
        for (Contact provider : physicians) {
            if (provider.Email != null && (oldValues.get(provider.Id).Email == null || provider.Email != oldValues.get(provider.Id).Email)) {
                updatedEmailContacts.add(provider.Id);
            }
        }
        return updatedEmailContacts;
    }

    private List<Enrollee_HCP__c> getUpdatedHCPs(Set<Id> updatedEmailContacts) {

        List<String> hcpIdStrings = new List<String>();
        for (ID hcpId : updatedEmailContacts) {
            hcpIdStrings.add(hcpId.toString());  
        }
        // Define the fields to be selected
        String fields = 'Id';
        String conditionsids =  '(\'' + String.join(new List<String>(hcpIdStrings), '\', \'') + '\')';
        // Build the conditions for the WHERE clause dynamically based on the updatedEmailContacts set
        String conditions = 'HCP__c IN' +  conditionsids;
    
        // Call the executeQuery method to fetch the Enrollee_HCP__c records
        List<Enrollee_HCP__c> enrolleeHCPResults = COM_QueryUtility.executeQuery('Enrollee_HCP__c',fields,conditions,true);
        return enrolleeHCPResults;
    }

    private List<PatientMedicationDosage> getPatientMedicationDosages(List<Enrollee_HCP__c> updatedHCPs) {
        
    // Initialize a Set<Id> to hold the Ids from updatedHCPs
    Set<Id> updatedHCPIds = new Set<Id>();
    
    // Extract the Ids from the Enrollee_HCP__c records
    for (Enrollee_HCP__c hcp : updatedHCPs) {
        updatedHCPIds.add(hcp.Id);
    }
    
    // Convert the Set<Id> to a List<String> to use in the query
    List<String> hcpIdList = new List<String>();
    for (Id hcpId : updatedHCPIds) {
        hcpIdList.add(hcpId);
    }

    // Defining the fields to retrieve in the query
    String fields = 'Id, Current_Dose_Record__c, Care_Program_Enrollee_Name__c, Care_Program_Enrollee_Name__r.Status, Enrollee_HCP__r.HCP__r.Email';
    String conditionids =  '(\'' + String.join(new List<String>(hcpIdList), '\', \'') + '\')';
    // Constructing the condition for the WHERE clause
    String conditions = 'Enrollee_HCP__c IN' + conditionids  + 'AND Current_Dose_Record__c = true';
    
    // Calling the executeQuery method to fetch the PatientMedicationDosage records
    List<PatientMedicationDosage> medicationDosageResults = COM_QueryUtility.executeQuery('PatientMedicationDosage',fields,conditions,true);
    return medicationDosageResults;
    }

    private Set<Id> getEnrolleeIds(List<PatientMedicationDosage> pmdosages) {
        Set<Id> enrolleeIdsToQuery = new Set<Id>();
        for (PatientMedicationDosage pmd : pmdosages) {
            if (pmd.Care_Program_Enrollee_Name__c != null) {
                enrolleeIdsToQuery.add(pmd.Care_Program_Enrollee_Name__c);
            }
        }
        return enrolleeIdsToQuery;
    }

    private Map<Id, CareProgramEnrollee> getCareProgramEnrollees(Set<Id> enrolleeIdsToQuery) {
        Map<Id, CareProgramEnrollee> careProgramEnrollees = new Map<Id, CareProgramEnrollee>();

        List<String> enrolleeIdStrings = new List<String>();
        for (ID hcpId : enrolleeIdsToQuery) {
            enrolleeIdStrings.add(hcpId.toString());  
        }
    // Check if there are enrolleeIds to query
    if (!enrolleeIdsToQuery.isEmpty()) {
        // Define the fields to be retrieved
        String fields = 'Id, ProviderEmail__c, Bypass_Apex__c';
        String conditionIds =  '(\'' + String.join(new List<String>(enrolleeIdStrings), '\', \'') + '\')';
        // Construct the conditions for the WHERE clause
        String conditions = 'Id IN' +conditionIds; 

        // Call the executeQuery method to fetch the CareProgramEnrollee records
        List<CareProgramEnrollee> enrolleeResults = COM_QueryUtility.executeQuery('CareProgramEnrollee',fields,conditions,true);

        // Convert the results into a Map<Id, CareProgramEnrollee>
        for (CareProgramEnrollee enrollee : enrolleeResults) {
            careProgramEnrollees.put(enrollee.Id, enrollee);
        }
    }

    return careProgramEnrollees;
    }

    private List<CareProgramEnrollee> getEnrolleesToUpdate(List<PatientMedicationDosage> pmdosages, Map<Id, CareProgramEnrollee> careProgramEnrollees) {
        List<CareProgramEnrollee> enrolleesToUpdate = new List<CareProgramEnrollee>();
        for (PatientMedicationDosage pmd : pmdosages) {
            if (pmd.Care_Program_Enrollee_Name__c != null) {
                CareProgramEnrollee cpe = careProgramEnrollees.get(pmd.Care_Program_Enrollee_Name__c);
                if (cpe != null) {
                    cpe.Bypass_Apex__c = !cpe.Bypass_Apex__c;
                    cpe.ProviderEmail__c = pmd.Enrollee_HCP__r.HCP__r.Email;
                    enrolleesToUpdate.add(cpe);
                }
            }
        }
        return enrolleesToUpdate;
    }

    private void updateCareProgramEnrollees(List<CareProgramEnrollee> enrolleesToUpdate) {
        try {
            // Perform the DML operation using the COM_DatabaseOperationsUtility.updateOperation method
            Database.SaveResult[] updateResults = COM_DatabaseOperationsUtility.updateOperation(enrolleesToUpdate, 'ContactUpdateTriggerHandler', true);
            
            // Check if the update was successful
            for (Database.SaveResult result : updateResults) {
                if (!result.isSuccess()) {
                    String errorMessage = 'Error updating record: ' + result.getErrors();
                    GenericLogger.debugLog(errorMessage);
                }
            }
        } catch (DMLException e) {
            GenericLogger.exceptionLog('ContactUpdateTriggerHandler', 'updateCareProgramEnrollees', e);
        }
    }
}