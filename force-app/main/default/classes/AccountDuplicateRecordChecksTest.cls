@isTest
public class AccountDuplicateRecordChecksTest {

    @testSetup
    static void setup() {
        // Creating a sample Lead record for the test
        Lead ld = new Lead(
            FirstName = 'test',
            LastName = 'journeyLead1',
            Status = 'New',
            J_Date_of_Birth__c = Date.today() - 7600, // Age 21+ years (around 7600 days ago)
            PostalCode = '10000'
        );
        insert ld;
    }

    @isTest
    static void findDuplicatesTest() {
        // Fetch the Lead record that was inserted in the test setup
        Lead ld = [SELECT Id FROM Lead WHERE LastName = 'journeyLead1' LIMIT 1];

        // Creating a list with the Lead ID to pass to the method
        List<Id> lstLead = new List<Id>();
        lstLead.add(ld.Id);

        // Insert RecordTypes that are required for Account creation
        List<RecordType> lstRectype = [
            SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true
        ];

        Test.startTest();

        // Calling the method under test
        List<ID> lstDuplicateIds = AccountDuplicateRecordChecks.FindDuplicates(lstLead);

        // Assertions to validate the behavior
        System.assertNotEquals(lstRectype.size(), 0, 'There should be at least one Account RecordType for Person accounts.');
        System.assertNotEquals(lstDuplicateIds, null, 'The result should not be null.');
        System.assert(lstDuplicateIds.isEmpty(), 'The list should be empty, no duplicates found.');

        Test.stopTest();
    }
}