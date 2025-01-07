@IsTest
/** 
* @description       : This is a COM_QueryUtilityTest test class designed to test the functionality of the COM_QueryUtilityTest class,
* History:
* Version  Author      Date            Detail          Description
* 1.0      Harish     25-Nov-2024     Created         Initial development.
 */
private class COM_QueryUtilityTest {

    @TestSetup
    static void setupTestData() {
        // Create test data to use in the tests
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

    

        // Create another Account with the custom record type
        Account accountWithRecordType = new Account(
            Name = 'Account with Record Type'
          
        );
        insert accountWithRecordType;
    }

    @IsTest
    static void testExecuteQuery() {
        // Test execution of a simple SOQL query
        String fields = 'Id, Name';
        String conditions = 'Name = \'Test Account\'';
        
        List<SObject> result = COM_QueryUtility.executeQuery('Account', fields, conditions, true);
        
        Assert.areEqual(1, result.size(), 'Expected one Account record to be returned');
        Assert.areEqual('Test Account', ((Account)result[0]).Name, 'The returned Account name should match');
    }

    @IsTest
    static void testExecuteComplexQuery() {
        // Test execution of a more complex query
        String queryString = 'SELECT Id, Name FROM Account WHERE Name = \'Test Account\'';
        
        List<SObject> result = COM_QueryUtility.executeComplexQuery(queryString, true);
        
        Assert.areEqual(1, result.size(), 'Expected one Account record to be returned');
        Assert.areEqual('Test Account', ((Account)result[0]).Name, 'The returned Account name should match');
    }

    @IsTest
    static void testGetCount() {
        // Test counting records
        String query = 'SELECT COUNT() FROM Account WHERE Name = \'Test Account\'';
        
        Integer count = COM_QueryUtility.getCount(query, true);
        
        Assert.areEqual(1, count, 'Expected count to be 1');
    }

    @IsTest
    static void testRetrieveRecordTypeId() {
        // Test retrieval of Record Type Id
        String sObjectType = 'Account';
        String developerName = 'Patient';
        
        Id recordTypeId = COM_QueryUtility.retrieveRecordTypeId(sObjectType, developerName);
        
        Assert.areNotEqual(null, recordTypeId, 'Record Type Id should not be null');
    }

    @IsTest
    static void testInvalidSObjectType() {
        // Test handling of invalid SObject type
        try {
            COM_QueryUtility.retrieveRecordTypeId('InvalidObject', 'recordTypeId');
           Assert.areEqual(false, 'Expected an exception for invalid SObject type',null);
        } catch (IllegalArgumentException e) {
            Assert.areEqual('Invalid SObject type: InvalidObject', e.getMessage(), 'Expected exception message for invalid SObject type');
        }
    }

    @IsTest
    static void testInvalidRecordType() {
        // Test handling of invalid Record Type
        try {
            COM_QueryUtility.retrieveRecordTypeId('Account', 'InvalidRecordType');
            Assert.areEqual(false, 'Expected an exception for invalid Record Type',null);
        } catch (IllegalArgumentException e) {
            Assert.areEqual('Record Type not found: InvalidRecordType', e.getMessage(), 'Expected exception message for invalid Record Type');
        }
    }
    
      @IsTest
    static void testExecuteQueryWithOutOrderBy() {
        // Test execution of a simple SOQL query
        String fields = 'Id, Name';
        String conditions = 'Name = \'Test Account\'';
        
        List<SObject> result = COM_QueryUtility.executeQueryWithOrderBy('Account', fields, conditions, true,'');
        
        Assert.areEqual(1, result.size(), 'Expected one Account record to be returned');
        Assert.areEqual('Test Account', ((Account)result[0]).Name, 'The returned Account name should match');
    }
      @IsTest
    static void testExecuteQueryWithOrderBy() {
        // Test execution of a simple SOQL query
        String fields = 'Id, Name';
        String conditions = 'Name = \'Test Account\'';
        
        List<SObject> result = COM_QueryUtility.executeQueryWithOrderBy('Account', fields, conditions, true,'Name ASC');
        
        Assert.areEqual(1, result.size(), 'Expected one Account record to be returned');
        Assert.areEqual('Test Account', ((Account)result[0]).Name, 'The returned Account name should match');
    }
     @IsTest
    static void testCoomonQUery() {
        // Test execution of a more complex query
        String queryString = 'SELECT Id, Name FROM Account WHERE Name = \'Test Account\'';
        
        List<SObject> result = COM_QueryUtility.executeComplexQueryWithOrderBy(queryString, true ,'Name ASC');
        
        Assert.areEqual(1, result.size(), 'Expected one Account record to be returned');
        Assert.areEqual('Test Account', ((Account)result[0]).Name, 'The returned Account name should match');
    }
       @IsTest
    static void testExecuteComplexQueryWithOrderByNegative() {
        // Test execution of a more complex query
        String queryString = 'SELECT Id, Name FROM Account WHERE Name = \'Test Account\'';
        
        List<SObject> result = COM_QueryUtility.executeComplexQueryWithOrderBy(queryString, true ,'');
        
        Assert.areEqual(1, result.size(), 'Expected one Account record to be returned');
        Assert.areEqual('Test Account', ((Account)result[0]).Name, 'The returned Account name should match');
    }
}