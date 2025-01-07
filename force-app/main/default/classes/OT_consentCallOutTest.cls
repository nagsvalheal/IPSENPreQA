@isTest
private class OT_consentCallOutTest {
    @isTest static void testCreateConsentTransaction() {
		// Test Values
		string status = 'CONFIRMED';
		string testDataSubject = 'test@test.com';
		string testPurpose = 'SMS';
		string expectedId = '7bdd6f95-4fdf-45ee-9e34-159a85f4a0f2';
		string testString1 = '"identifier": "'+ testDataSubject +'",\n';
		string testString2 = '{"Id": "' + expectedId + '", "transactionType": "' + status + '"}';
		
		// Prepare the objects
		OT_consentData consentData = new OT_consentData();
		List<OT_consentPurpose> selectedPurposeIDs = new List<OT_consentPurpose>();
		
		// Create the purpose and withdraw consent
		OT_consentPurpose consentPurpose = new OT_consentPurpose();
		consentPurpose.purposeId = consentData.getPurposeID(testPurpose);
		consentPurpose.transactionType = status;
		selectedPurposeIDs.add(consentPurpose);
		
		// Run the test
		OT_consentCallOut.createConsentTransaction(consentData.SFDC_Collection_Point(testDataSubject, selectedPurposeIDs));

		// Validate the results
		System.assert(true, 'An error occured while creating the transaction');
    }
}