/**
 * @class          J_AccountTriggerHandler
 * @description    This class handles the logic for updating and processing account-related fields,
 *                 including updating patient demo date, pharmacy email, and triggering care program updates.
 * @author         Arkadii Sychov
 * @date           10/16/2020
 */
public with sharing class J_AccountTriggerHandler {

    
    private final static String ZIP_DEFAULT_VALUE = 'default';
    /**
 * @method         updatePatDate
 * @description    This method updates the `Pat_Demo_Date__c` field if certain fields have changed on the Account.
 * @param          newList (List<Account>) - The list of new Account records.
 * @param          oldMap (Map<Id, Account>) - The map of old Account records.
 */
    public void updatePatDate(List<Account> newList, Map<Id, Account> oldMap){

        
        for(Account patient:newList){
            
            if((patient.FirstName != oldMap.get(patient.Id).FirstName) || (patient.LastName != oldMap.get(patient.Id).LastName) || (patient.J_Sex_Account__c != oldMap.get(patient.Id).J_Sex_Account__c) || (patient.PersonBirthdate != oldMap.get(patient.Id).PersonBirthdate) || (patient.PersonMailingPostalCode != oldMap.get(patient.Id).PersonMailingPostalCode)){
                
                patient.Pat_Demo_Date__c = system.today();
            }
        }
    }
    
    /**
     * @method         newPatDate
     * @description    Sets the `Pat_Demo_Date__c` field to today's date if specific fields are not null.
     * @param          newList (List<Account>) - The list of new Account records.
     */
    public void newPatDate(List<Account> newList){

        
        for(Account patient:newList){
            
            if((patient.FirstName != Null) || (patient.LastName != Null) || (patient.J_Sex_Account__c != Null) || (patient.PersonBirthdate != Null) || (patient.PersonMailingPostalCode != Null)){
                
                patient.Pat_Demo_Date__c = system.today();
            }
        }
    }

    /**
     * @method         updatePharmacyEmail
     * @description    Updates the pharmacy email in the Care Program Enrollee record when the pharmacy email changes.
     * @param          accts (List<Account>) - List of updated Account records.
     * @param          oldAccts (Map<Id, Account>) - Map of old Account records.
     */  
    public void updatePharmacyEmail(List<Account> accts, Map<Id, Account> oldAccts)
    {
        Set<Id> updatedEmailPharmacy = getUpdatedPharmacyEmailAccounts(accts, oldAccts);

    if (updatedEmailPharmacy.isEmpty()) {
        return;
    }

    List<SObject> pmdosages = getPatientMedicationDosages(updatedEmailPharmacy);

    if (pmdosages.isEmpty()) {
        return;
    }

    List<CareProgramEnrollee> enrolleesToUpdate = new List<CareProgramEnrollee>();
    Set<Id> uniqueEnrollees = new Set<Id>();

    for (SObject pmdObj : pmdosages) {
        processPatientMedicationDosage(pmdObj, uniqueEnrollees, enrolleesToUpdate);
    }

    updateCareProgramEnrollees(enrolleesToUpdate);
}

// Helper method to check for updated pharmacy emails
private Set<Id> getUpdatedPharmacyEmailAccounts(List<Account> accts, Map<Id, Account> oldAccts) {
    Set<Id> updatedEmailPharmacy = new Set<Id>();
    for (Account acct : accts) {    
        if (acct.J_Email_payer__c != oldAccts.get(acct.Id).J_Email_payer__c) {
            updatedEmailPharmacy.add(acct.Id);
        }
    }
    return updatedEmailPharmacy;
}
    
    // Helper method to get PatientMedicationDosage records
    private List<SObject> getPatientMedicationDosages(Set<Id> updatedEmailPharmacy) {
    // Convert the Set<Id> to List<String> 
    List<String> pharmacyIds = new List<String>();
    for (Id pharmacyId : updatedEmailPharmacy) {
        pharmacyIds.add(pharmacyId.toString());
    }

    // Define the fields to be selected
    String fields = 'Id, Current_Dose_Record__c, Care_Program_Enrollee_Name__c, Specialty_Pharmacy__r.J_Email_payer__c';
    
    // Define the conditions for the WHERE clause
    String conditions = 'Specialty_Pharmacy__c IN (\'' + String.join(pharmacyIds, '\',\'') + '\') AND Current_Dose_Record__c = TRUE';

    // Call the executeQuery method from COM_QueryUtility class
    return COM_QueryUtility.executeQuery('PatientMedicationDosage', fields, conditions, true);
	}


// Helper method to process PatientMedicationDosage records
private void processPatientMedicationDosage(SObject pmdObj, Set<Id> uniqueEnrollees, List<CareProgramEnrollee> enrolleesToUpdate) {
    PatientMedicationDosage pmd = (PatientMedicationDosage)pmdObj;

    if (pmd.Care_Program_Enrollee_Name__c != null && !uniqueEnrollees.contains(pmd.Care_Program_Enrollee_Name__c)) {
        List<SObject> cpes = getCareProgramEnrollees(pmd.Care_Program_Enrollee_Name__c);

        if (!cpes.isEmpty()) {
            CareProgramEnrollee cpe = (CareProgramEnrollee)cpes[0];
            cpe.Bypass_Apex__c = !cpe.Bypass_Apex__c; // Toggle Bypass_Apex__c flag
            cpe.PharmacyEmail__c = pmd.Specialty_Pharmacy__r.J_Email_payer__c; // Update the pharmacy email

            enrolleesToUpdate.add(cpe); // Add to the list of enrollees to update
            uniqueEnrollees.add(pmd.Care_Program_Enrollee_Name__c); // Track the unique enrollee
        }
    }
}

// Helper method to get CareProgramEnrollee records
private List<SObject> getCareProgramEnrollees(Id careProgramEnrolleeId) {
    String fields = 'Id, Bypass_Apex__c';
    String conditions = 'Id = :careProgramEnrolleeId';
    return COM_QueryUtility.executeQuery('CareProgramEnrollee', fields, conditions, true);
}

// Helper method to update CareProgramEnrollees
private void updateCareProgramEnrollees(List<CareProgramEnrollee> enrolleesToUpdate) {
    if (!enrolleesToUpdate.isEmpty()) {
        try {
            Boolean userModeLevel = true; // Set to true or false based on your use case
            Database.SaveResult[] updateResults = COM_DatabaseOperationsUtility.updateOperation(enrolleesToUpdate, 'CareProgramEnrollee', userModeLevel);

            for (Database.SaveResult result : updateResults) {
                if (!result.isSuccess()) {
                    String errorMessage = 'Error updating record: ' + result.getErrors();
                    GenericLogger.debugLog(errorMessage);
                }
            }
        } catch (DMLException e) {
            GenericLogger.exceptionLog('J_AccountTriggerHandler', 'updatePharmacyEmail', e);
        }
    }
        }

}