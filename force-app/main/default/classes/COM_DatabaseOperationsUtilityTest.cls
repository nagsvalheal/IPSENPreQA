/**
 * @description       : BI_PSP_DatabaseOperationsUtility Test class.
 * History:
 * Version  Author      Date            Detail          Description
 * 1.0      Abinsha     10-Jul-2024     Created         Initial development.
 */
@IsTest
private class COM_DatabaseOperationsUtilityTest {

    @TestSetup
    static void setupTestData() {
        // Setup necessary test data before running the tests
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;
    }

    @IsTest
    static void testInsertOperationWithUserMode() {
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'New Test Account'));

        Test.startTest();
        Database.SaveResult[] results = COM_DatabaseOperationsUtility.insertOperation(accounts, 'COM_DatabaseOperationsUtility', true);
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One record should be inserted.');
        System.assert(results[0].isSuccess(), 'The insert operation should be successful.');
    }

    @IsTest
    static void testInsertOperationWithoutUserMode() {
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(Name = 'New Test Account'));

        Test.startTest();
        Database.SaveResult[] results = COM_DatabaseOperationsUtility.insertOperation(accounts, 'COM_DatabaseOperationsUtility', false);
        Test.stopTest();

        Assert.areEqual(1, results.size(), 'One record should be inserted.');
        System.assert(results[0].isSuccess(), 'The insert operation should be successful.');
    }

    @IsTest
    static void testUpdateOperationWithUserMode() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];
        for (Account acc : accounts) {
            acc.Name = 'Updated ' + acc.Name;
        }

        Test.startTest();
        Database.SaveResult[] results = COM_DatabaseOperationsUtility.updateOperation(accounts, 'COM_DatabaseOperationsUtility', true);
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Two records should be updated.');
        System.assert(results[0].isSuccess(), 'The update operation should be successful.');
    }

    @IsTest
    static void testUpdateOperationWithoutUserMode() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];
        for (Account acc : accounts) {
            acc.Name = 'Updated ' + acc.Name;
        }

        Test.startTest();
        Database.SaveResult[] results = COM_DatabaseOperationsUtility.updateOperation(accounts, 'COM_DatabaseOperationsUtility', false);
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Two records should be updated.');
        System.assert(results[0].isSuccess(), 'The update operation should be successful.');
    }

    @IsTest
    static void testUpsertOperationWithUserMode() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];
        for (Account acc : accounts) {
            acc.Name = 'Upserted ' + acc.Name;
        }

        Test.startTest();
        List<Database.UpsertResult> results = COM_DatabaseOperationsUtility.upsertOperation(accounts, 'COM_DatabaseOperationsUtility', true);
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Two records should be upserted.');
        System.assert(results[0].isSuccess(), 'The upsert operation should be successful.');
    }

    @IsTest
    static void testUpsertOperationWithoutUserMode() {
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 2];
        for (Account acc : accounts) {
            acc.Name = 'Upserted ' + acc.Name;
        }

        Test.startTest();
        List<Database.UpsertResult> results = COM_DatabaseOperationsUtility.upsertOperation(accounts, 'COM_DatabaseOperationsUtility', false);
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Two records should be upserted.');
        System.assert(results[0].isSuccess(), 'The upsert operation should be successful.');
    }

    @IsTest
    static void testDeleteOperationWithUserMode() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 2];

        Test.startTest();
        List<Database.DeleteResult> results = COM_DatabaseOperationsUtility.deleteOperation(accounts, 'COM_DatabaseOperationsUtility', true);
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Two records should be deleted.');
        System.assert(results[0].isSuccess(), 'The delete operation should be successful.');
    }

    @IsTest
    static void testDeleteOperationWithoutUserMode() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 2];

        Test.startTest();
        List<Database.DeleteResult> results = COM_DatabaseOperationsUtility.deleteOperation(accounts, 'COM_DatabaseOperationsUtility', false);
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Two records should be deleted.');
        System.assert(results[0].isSuccess(), 'The delete operation should be successful.');
    }

    @IsTest
    static void testInsertOperationWithDmlException() {
        List<Account> accounts = new List<Account>();
        // Adding an account with a missing required field to cause an exception
        accounts.add(new Account());

        try {
            Test.startTest();
            COM_DatabaseOperationsUtility.insertOperation(accounts, 'COM_DatabaseOperationsUtility', false);
            Test.stopTest();
            System.assert(false, 'A DMLException should have been thrown.');
        } catch (DMLException e) {
            System.assert(e.getMessage().contains('Required fields are missing'), 'The exception should indicate that required fields are missing.');
        }
    }

    @IsTest
    static void testUpdateOperationWithDmlException() {
        List<Account> accounts = new List<Account>();
        // Trying to update a non-existing record to cause an exception
        accounts.add(new Account(Id = '001000000000000000', Name = 'Non-existing Account'));

        try {
            Test.startTest();
            COM_DatabaseOperationsUtility.updateOperation(accounts, 'COM_DatabaseOperationsUtility', false);
            Test.stopTest();
            System.assert(false, 'A DMLException should have been thrown.');
        } catch (DMLException e) {
            System.assert(e.getMessage().contains(e.getMessage()), 'The exception should indicate that the entity is deleted or non-existing.');
        }
    }

    @IsTest
    static void testDeleteOperationWithDmlException() {
        List<Account> accounts = new List<Account>();
           String currentUserName = 'Test User';
        String currentUserEmail = 'testusernew@example.com';
        // Trying to delete a non-existing record to cause an exception
      Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('PersonAccount')
            .getRecordTypeId();
        Account testAccountFirst = new Account(
            Lastname = currentUserName,
            PersonEmail = currentUserEmail,
            RecordTypeId = personAccountRecordTypeId
        );
        insert testAccountFirst;
        
        String currentUserNameSecond = 'Test User2';
        String currentUserEmailSecond = 'testUserSecondnew@example.com';
        Account testAccountSecond = new Account(
            Lastname = currentUserNameSecond,
            PersonEmail = currentUserEmailSecond,
            RecordTypeId = personAccountRecordTypeId
           
        );
        insert testAccountSecond;
        accounts.add(testAccountFirst);
        accounts.add(testAccountSecond);

        try {
            Test.startTest();
            COM_DatabaseOperationsUtility.deleteOperation(accounts, 'COM_DatabaseOperationsUtility', false);
            Test.stopTest();
            System.assert(true, 'A DMLException should have been thrown.');
        } catch (DMLException e) {
            System.assert(e.getMessage().contains('entity is deleted'), 'The exception should indicate that the entity is deleted or non-existing.');
        }
    }
}