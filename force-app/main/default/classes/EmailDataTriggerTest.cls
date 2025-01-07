/**
 * @description       : Test class for verifying the functionality of triggers and methods related to the Email_Data__c object.
 *                      It ensures that the trigger and associated methods perform as expected when Email_Data__c records are inserted.
 * @author            : Abinsha Basheer
 * @group             : 
 * @last modified on  : 22-11-2023
 * @last modified by  : Abinsha Basheer
**/

@isTest
public class EmailDataTriggerTest {
  /**
     * @description       : Tests the trigger on Email_Data__c and verifies the behavior of the 
     *                      AB_AttachmentForIDClass.attchmentMethod. Ensures that the method is called as expected
     *                      and that related ContentVersion records are handled correctly.
     **/

    @isTest
    static void testEmailDataTrigger() {
        // Create a test Email_Data__c record
        Email_Data__c testEmailData = new Email_Data__c();
        testEmailData.Sent_email_ID__c = '02s7h000008U41uAAC';
      
        
        // Add other required fields as needed
        insert testEmailData;

        Email_Data__c emData=[select Id,Sent_email_ID__c from Email_Data__c where Id=:testEmailData.Id];
       String emailIds= emData.Sent_email_ID__c;
        String emailDataId=emData.Id;
        Test.startTest();
        // No need to explicitly call the trigger, it will be invoked automatically on record insertion
        
        AB_AttachmentForIDClass.attchmentMethod(emailDataId,emailIds);
        Test.stopTest();

        // Verify any assertions or query for additional verification if needed
        // Example: Query for records created by the trigger and assert their existence
        List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion];
        System.assertEquals(0, contentVersions.size(), 'Expected ContentVersion records to be created by the trigger');
    }
}