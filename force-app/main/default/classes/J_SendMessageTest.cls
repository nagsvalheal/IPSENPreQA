/**
 * @description       : Test class for `SendMessage` class. This class provides various test methods to verify the functionality of the `getCareProgramTeamMember`, `sendMessagedata`, `getMessageAttachments`, and `contentSize` methods.
 * @author            : Vijay
 * @last modified on  : 09-12-2024
 */
@isTest
public class J_SendMessageTest {

    /**
     * @description       : Helper method to create test data for the test class. This method creates test users, accounts, care programs, and team members to be used in the test cases.
     */
    private static void createTestData() { 
        // Create test User
        User testUser1 = new User(
            Username = 'HenryCavill@test.com',
            LastName = 'Cavill',
            Email = 'HenryCavill@test.com',
            Alias = 'Cavill',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name='Standard User'].Id,
            LanguageLocaleKey = 'en_US'
        );
        insert testUser1;
        User testUser2 = new User(
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
        insert testUser2;
        // Create test CareProgramTeamMember records
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        CareProgram testCareProgram = new CareProgram(Name = 'Test Care Program', Status= 'Active');
        insert testCareProgram;
        
       // Create CareProgramTeamMembers
        List<CareProgramTeamMember> teamMembers = new List<CareProgramTeamMember>();
        teamMembers.add(new CareProgramTeamMember(Name = 'Member 1', UserId = testUser1.Id, CareProgramId = testCareProgram.Id));
        teamMembers.add(new CareProgramTeamMember(Name = 'Member 3', UserId = testUser2.Id, CareProgramId = testCareProgram.Id));
        insert teamMembers;
    }
    /**
     * @description       : Test method for `getCareProgramTeamMember` in the `sendMessage` class. This method verifies that the correct team members are returned for a given user.
     */
    @isTest
    static void testGetCareProgramTeamMember() {
        // Setup test data
        createTestData();
        User testUser = [SELECT Id FROM User WHERE Username = 'HenryCavill@test.com' LIMIT 1];
        
        // Test method
        Test.startTest();
        List<CareProgramTeamMember> result = J_SendMessage.getCareProgramTeamMember(testUser.Id);
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result,'The result list should not be null');
        System.assertEquals(2, result.size(),'Two team members should be present in the list.');
        System.AssertEquals(testUser.Id, result[0].UserId, 'User ID does not match user ID from user record.');
    }
  /**
     * @description       : Test method for `sendMessagedata` in the `sendMessage` class. This method ensures that a message is created successfully with the given parameters and verifies the contents.
     */  
 @isTest
    static void testSendMessagedata() {
        // Setup test data
        createTestData();
        User testUser = [SELECT Id FROM User WHERE Username = 'HenryCavill@test.com' LIMIT 1];
        CareProgram testCareProgram = [SELECT Id FROM CareProgram WHERE Name = 'Test Care Program' LIMIT 1];
        
        // Create test task
        Task testTask = new Task(
            Subject = 'Call',
            WhatId = testCareProgram.Id
        );
        insert testTask; 
        
        // Create test ContentVersion
    ContentVersion testContentVersion = new ContentVersion(
        Title = 'Test Content',
        PathOnClient = 'test.pdf',
        VersionData = Blob.valueOf('Test Content'),
        IsMajorVersion = true
    );
    insert testContentVersion;

    // Retrieve the ContentDocumentId associated with the ContentVersion
    Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id].ContentDocumentId;
        List<String> attachmentIds = new List<String>{ contentDocumentId };

        // Test method
        String subject = 'Test Message';
        Test.startTest();
        try {
            J_SendMessage.sendMessagedata(testUser.Id, subject, attachmentIds, testUser.Id, testTask.Id);
            
            // Verify results
            List<J_Send_Message__c> messages = [SELECT Id, J_Message__c, J_From__c FROM J_Send_Message__c WHERE J_Task__c = :testTask.Id];
            System.assertEquals(2, messages.size(), 'Two messages should be created.');
            for (J_Send_Message__c message : messages) {
                System.assertEquals(subject, message.J_Message__c,'The subject should be copied to the message field. ');
                System.assertEquals(testUser.Id, message.J_From__c,'The user ID should be copied to the "From" field. ');
            }
        } catch (Exception e) {
            System.assert(false, 'An unexpected error occurred: ' + e.getMessage());
        } 
        Test.stopTest();
    }
    /**
     * @description       : Test method for `getMessageAttachments` in the `sendMessage` class. This method verifies that the correct attachments for a given message are returned.
     */
    @isTest
    static void testGetMessageAttachments() {
        // Setup test data
        createTestData();
        User testUser = [SELECT Id FROM User WHERE Username = 'HenryCavill@test.com' LIMIT 1];
        CareProgram testCareProgram = [SELECT Id FROM CareProgram WHERE Name = 'Test Care Program' LIMIT 1];
         // Create test task
        Task testTask = new Task(
            Subject = 'Call',
            WhatId = testCareProgram.Id
        );
        insert testTask; 
        // Create test message
        J_Send_Message__c testMessage = new J_Send_Message__c(
            J_Sent_To__c = testUser.Id,
            J_Message__c = 'Test Message',
            J_From__c = testUser.Id,
            J_Task__c = testTask.Id
        );
        insert testMessage;
        
        // Create test ContentDocument and ContentDocumentLink
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test file content')
        );
        insert contentVersion;
        ContentVersion contentDocument = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        
        ContentDocumentLink contentLink = new ContentDocumentLink(
            ContentDocumentId = contentDocument.ContentDocumentId,
            LinkedEntityId = testMessage.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert contentLink;
        
        // Test method
        Test.startTest();
        Map<Id, String> result = J_SendMessage.getMessageAttachments(testMessage.Id);
        Test.stopTest();
        
        // Verify results
        System.assertNotEquals(null, result,'The result list should not be null');
        System.assertEquals(1, result.size(),'One file should be present in the list.');
        System.assert(result.containsKey(contentDocument.ContentDocumentId),'The ContentDocumentLink should be present in the map.');
    }
    
    @isTest
    static void testContentSize() {
        // Setup test data
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.txt',
            VersionData = Blob.valueOf('Test file content')
        );
        insert contentVersion;
        ContentVersion contentDocument = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        
        // Test method
        Test.startTest();
        String result = J_SendMessage.contentSize(contentDocument.ContentDocumentId);
        Test.stopTest();
        
        // Verify results
        System.assertEquals('SUCCESS', result,'The file size should be returned with SUCCESS status.');
    }
}