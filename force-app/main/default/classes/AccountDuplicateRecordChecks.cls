/**
 * @author         None
 * @date           25/11/2024
 * @description    This class checks for duplicate Account records based on the provided Lead records.
 *                 It runs the duplicate rules on a Lead record and identifies potential matching Account records.
 * @invocableMethod This method can be called from a flow to check for duplicate accounts based on a list of Lead IDs.
 * @param lstLeadID List of Lead IDs to check for duplicates.
 * @return List<ID> Returns a list of Account IDs that are duplicates of the provided Leads.
 */
public with sharing class AccountDuplicateRecordChecks {

    /**
     * @description This method checks for duplicate Accounts based on Lead information.
     *              It compares provided Lead information (like name, DOB, contact details) to existing Accounts.
     * @param lstLeadID List of Lead IDs to check for duplicates.
     * @return List<ID> List of Account IDs that match the given Lead's details.
     */
    @InvocableMethod(
        label='Check for Account Duplicate Records'
        description='Runs the duplicate rules on a particular record or recordId to see if a duplicate record exists.'
        category='Account'
    )
    public static List<ID> findDuplicates(List<ID> lstLeadID) {
        List<ID> accountIds = new List<ID>();

        try {
        // Fetch the lead details to create Account records for matching
        List<Lead> lstLead = getLeadDetails(lstLeadID);

        if (lstLead != null && lstLead.size() > 0) {
            // Create Account records based on Lead data
            List<Account> lstAccount = createAccountRecordsFromLead(lstLead);

            // Run duplicate rules to find matching records
            List<Datacloud.findDuplicatesResult> results = Datacloud.findDuplicates.findDuplicates(lstAccount);

            // Process the duplicate results and add the duplicate Account ID to the list
            accountIds = processDuplicateResults(results);
        }
        }
        
        catch (DMLException e) {
            GenericLogger.exceptionLog('AccountDuplicateRecordChecks', 'findDuplicates', e);
        }
        return accountIds;
    }

    /**
     * @description Fetches Lead details for the provided Lead IDs.
     * @param lstLeadID List of Lead IDs to fetch the Lead records.
     * @return List<Lead> List of Lead records.
     */
    private static List<Lead> getLeadDetails(List<ID> lstLeadID) {
        
        List<String> leadIdStrings = new List<String>();
        for (ID leadId : lstLeadID) {
            leadIdStrings.add(leadId.toString());  
        }
        String conditionIds = '(\'' + String.join(leadIdStrings, '\', \'') + '\')';
        // Define the fields to be selected
        String fields = 'Id, FirstName, LastName, J_Date_of_Birth__c, PostalCode, Email, J_Home_Phone__c, J_Cell_Phone__c, J_Work_Phone__c';
        
        // Define the conditions for the WHERE clause
        String conditions = 'Id IN' +conditionIds;
        
        // Call the executeQuery method to fetch the data
        List<SObject> leadResults = COM_QueryUtility.executeQuery('Lead', fields, conditions, true);
        
        // Return the results as a List of Lead records
        return (List<Lead>) leadResults;
    }
    /**
     * @description Creates Account records based on the provided Lead details.
     * @param lstLead List of Lead records.
     * @return List<Account> List of Account records created from the Lead data.
     */
    private static List<Account> createAccountRecordsFromLead(List<Lead> lstLead) {
        List<Account> lstAccount = new List<Account>();
    
        // Define the fields and conditions for querying the RecordType
        String fields = 'Id';
        String conditions = 'SObjectType = \'Account\' AND IsPersonType = true';
        
        // Call executeQuery to fetch the RecordType for Person Account
        List<SObject> lstRecordTypes = COM_QueryUtility.executeQuery('RecordType', fields, conditions, true);
        
        // Check if we have a valid RecordTypeId
        if (lstRecordTypes != null && lstRecordTypes.size() > 0) {
            // Assuming only one RecordType for Person Account, so we take the first record
            Id personAccountRecordTypeId = (Id)lstRecordTypes[0].get('Id');
            
            for (Lead lead : lstLead) {
                Account acc = new Account();
                acc.FirstName = lead.FirstName;
                acc.LastName = lead.LastName;
                acc.Birthdate_in_Text__c = DateTime.newInstance(lead.J_Date_of_Birth__c, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
                acc.PersonMailingPostalCode = lead.PostalCode;
                acc.PersonMobilePhone = lead.J_Cell_Phone__c;
                acc.PersonHomePhone = lead.J_Home_Phone__c;
                acc.PersonOtherPhone = lead.J_Work_Phone__c;
                acc.PersonEmail = lead.Email;
                acc.RecordTypeId = personAccountRecordTypeId; // Set the RecordTypeId
                lstAccount.add(acc);
            }
        }
    
        return lstAccount;
    }
    

    /**
     * @description This method processes the results from the duplicate checks and returns the duplicate Account IDs.
     *              It iterates over the duplicate results, extracts the duplicate Account IDs, and adds them to a list.
     * @param results List of duplicate results from the Datacloud.findDuplicates call.
     * @return List<ID> List of duplicate Account IDs.
     */
    private static List<ID> processDuplicateResults(List<Datacloud.findDuplicatesResult> results) {
        List<ID> accountIds = new List<ID>();

        for (Datacloud.findDuplicatesResult findDupeResult : results) {
            for (Datacloud.DuplicateResult dupeResult : findDupeResult.getDuplicateResults()) {
                for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
                    for (Datacloud.MatchRecord matchRecord : matchResult.getMatchRecords()) {
                        accountIds.add(matchRecord.getRecord().Id);
                    }
                }
            }
        }

        return accountIds;
    }
}