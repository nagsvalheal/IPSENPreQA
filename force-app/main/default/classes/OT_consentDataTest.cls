@isTest
private class OT_consentDataTest {
    @isTest static void testGetPurposeID() {
		// Test Values
		string testPurpose = 'Mail';
		string expectedId = '4e5f8f35-2421-45cc-a9a9-4e3d0d2bcdff';
		
		// Run the test
		OT_consentData consentData = new OT_consentData();
        string purposeID = consentData.getPurposeID(testPurpose);
		
		// Validate the result
        System.assertEquals(expectedId, purposeID, 'IDs dont match!');
    }

    @isTest static void testBuildSchema() {
		// Test Values
		string status = 'WITHDRAWN';
		string testPurpose = 'Email';
		string expectedId = 'b4cdc483-c84f-41cd-9961-5285a0593d1a';
		string testString = '{"Id": "' + expectedId + '", "transactionType": "' + status + '"}';
		
		// Prepare the objects
		OT_consentData consentData = new OT_consentData();
		List<OT_consentPurpose> selectedPurposeIDs = new List<OT_consentPurpose>();
		
		// Create the purpose and withdraw consent
		OT_consentPurpose consentPurpose = new OT_consentPurpose();
		consentPurpose.purposeId = consentData.getPurposeID(testPurpose);
		consentPurpose.transactionType = status;
		selectedPurposeIDs.add(consentPurpose);
		
		// Run the test
        string schema = consentData.buildPurposesSchema(selectedPurposeIDs);
		
		// Validate the result
        System.assert(schema.indexOf(testString)!=-1, 'Invalid Schema!');
    }

    @isTest static void testSFDC_Collection_Point() {
		// Test Values
		string status = 'CONFIRMED';
		string testDataSubject = 'test@test.com';
		string testPurpose = 'Phone';
		string expectedId = '2caab5e4-8be6-4599-ad2a-9718f680f8e6';
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
        string collectionPoint = consentData.SFDC_Collection_Point(testDataSubject, selectedPurposeIDs);
		
		// Validate the results
        System.assert(collectionPoint.indexOf(testString1)!=-1, 'Invalid Data Subject!');
        System.assert(collectionPoint.indexOf(testString2)!=-1, 'Invalid Schema!');
    }
}