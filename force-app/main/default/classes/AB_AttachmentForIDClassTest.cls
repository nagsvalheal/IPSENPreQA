/*
  @description       : 
  @author            : Abinsha Basheer
  @group             : 
  @last modified on  : 22-11-2023
  @last modified by  : Abinsha Basheer
*/

@isTest
public class AB_AttachmentForIDClassTest {

    @isTest
    static void testAttachmentMethod() {
        // Create a test EmailMessage
        EmailMessage testEmail = new EmailMessage();
        testEmail.Subject = 'Test Email';
        // Add other required fields as needed
        insert testEmail;

        // Create a test Email_Data__c
        Email_Data__c testEmailData = new Email_Data__c();
        // Add other required fields as needed
        insert testEmailData;

        // Create a test Attachment
        Attachment testAttachment = new Attachment();
        testAttachment.ParentId = testEmail.Id;
        testAttachment.Name = 'TestAttachment.txt';
        testAttachment.Body = Blob.valueOf('Test attachment content');
        // Add other required fields as needed
        insert testAttachment;

        Test.startTest();
        // Call the future method
        AB_AttachmentForIDClass.attchmentMethod(testEmailData.Id, testEmail.Id);
        Test.stopTest();

        // Query ContentVersion records
        List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId FROM ContentVersion];
        System.assertEquals(1, contentVersions.size(), 'Expected one ContentVersion record to be created');

        // Query ContentDocumentLink records based on ContentDocumentId
        List<ContentDocumentLink> contentDocumentLinks = [SELECT Id FROM ContentDocumentLink WHERE ContentDocumentId = :contentVersions[0].ContentDocumentId];
        System.assertEquals(2, contentDocumentLinks.size(), 'Expected one ContentDocumentLink record to be created');
    }
}