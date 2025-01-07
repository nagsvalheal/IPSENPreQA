/**
 	@author         SriHari 
 *  @date           11/06/2024
*/



@isTest
private class TaskHandlerTest {

    private static void createTestData() {
        // Create test user
        User testUser1 = new User(
            Username = 'BenAffleck@test.com',
            LastName = 'Affleck',
            Email = 'BenAffleck@test.com',
            Alias = 'Affleck',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User'].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser1;


        // Create test account and care program
        Account testAccount1 = new Account(Name = 'Test Account1');
        insert testAccount1;
		Account testAccount2 = new Account(Name = 'Test Account2');
        insert testAccount2;
        CareProgram testCareProgram = new CareProgram(Name = 'Care Program1', Status= 'Active');
        insert testCareProgram;
        system.debug('testCareProgram'+testCareProgram);
    }

    @isTest
    static void testGetTasksForCareProgramEnrollees() {
        // Create a test CareProgramEnrollee
        createTestData();
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account1' LIMIT 1];
        CareProgram testCareProgram = [SELECT Id FROM CareProgram WHERE Name = 'Care Program1' LIMIT 1];

        CareProgramEnrollee enrollee = new CareProgramEnrollee(
            Name = 'Test Enrollee',
            AccountId = testAccount.Id,
            CareProgramId = testCareProgram.Id
        );
        insert enrollee;

        // Create test tasks related to the enrollee
        Task task1 = new Task(
            Subject = 'Patient Interaction',
            WhatId = enrollee.Id,
            Status = 'Not Started',
            ActivityDate = Date.today()
        );
        Task task2 = new Task(
            Subject = 'HCP Interaction',
            WhatId = enrollee.Id,
            Status = 'Completed',
            ActivityDate = Date.today().addDays(1)
        );
        insert new List<Task>{task1, task2};

        // Call the method to test
        Test.startTest();
        List<Task> tasks = TaskHandler.getTasksForCareProgramEnrollees(enrollee.Id);
        Test.stopTest();

        // Assertions
        System.assertEquals(2, tasks.size(), 'Expected 2 tasks for the enrollee');
        System.assertEquals('Patient Interaction', tasks[0].Subject, 'Unexpected subject for task 1');
        System.assertEquals('HCP Interaction', tasks[1].Subject, 'Unexpected subject for task 2');
    }

    @isTest
    static void testGetAllCareProgramEnrollees() {
        // Setup test data
        createTestData();

        // Retrieve the test data
        Account testAccount1 = [SELECT Id FROM Account WHERE Name = 'Test Account1' LIMIT 1];
        Account testAccount2 = [SELECT Id FROM Account WHERE Name = 'Test Account2' LIMIT 1];
        CareProgram testCareProgram = [SELECT Id FROM CareProgram WHERE Name = 'Care Program1' LIMIT 1];
        
        // Create test CareProgramEnrollee records
        List<CareProgramEnrollee> enrolleesToInsert = new List<CareProgramEnrollee>{
            new CareProgramEnrollee(Name = 'Enrollee 1', CareProgramId = testCareProgram.Id, AccountId = testAccount1.Id),
            new CareProgramEnrollee(Name = 'Enrollee 2', CareProgramId = testCareProgram.Id, AccountId = testAccount2.Id)
        };
        insert enrolleesToInsert;
        List<CareProgramEnrollee> insertedEnrollees = [SELECT Id, Name, CareProgramId, AccountId FROM CareProgramEnrollee WHERE CareProgramId = :testCareProgram.Id];
		System.debug('Inserted Enrollees: ' + insertedEnrollees);
        // Call the method to test
        Test.startTest();
        List<CareProgramEnrollee> enrollees = TaskHandler.getAllCareProgramEnrollees();
        Test.stopTest();
		System.debug('Retrieved Enrollees: ' + enrollees);
        // Assertions
        System.assertNotEquals(0, enrollees.size(), 'Expected at least one enrollee');
        System.assertEquals(2, enrollees.size(), 'Expected 2 enrollees');
        
    }
}