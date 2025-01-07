/*
  @description       : 
  @author            : Abinsha Basheer
  @group             : 
  @last modified on  : 22-11-2023
  @last modified by  : Abinsha Basheer
*/

// AB_AttachmentForIDClass
public class AB_AttachmentForIDClass {
    @future
    public static void attchmentMethod(String emailDataId, String emailIds) {
        // Query EmailMessage using the provided emailIds
        List<EmailMessage> emailMessages = [SELECT Id, Name FROM EmailMessage WHERE Id = :emailIds];
 Email_Data__c latestEmailData = [SELECT Id FROM Email_Data__c where Id=:emailDataId];
            
        if (!emailMessages.isEmpty()) {
            EmailMessage em = emailMessages[0];
            String emId = em.Id;
            System.debug('the emId: ' + emId);

            // Query Attachment using the emId
            List<Attachment> attach = [SELECT Id, Name, Body, ContentType, ParentId, OwnerId FROM Attachment WHERE ParentId = :emId ];
           System.debug('the attach.sIZE: ' + attach.Size());
            //String attachmentName;
           // String bodyName;
            for(Attachment ats:attach)
            {
                  ContentVersion cVersion = new ContentVersion();
            cVersion.Title = ats.Name;
                System.debug('the cVersion.Title = ats.Name; ats.Name');
            cVersion.PathOnClient = ats.Name;//File name with extention
            cVersion.VersionData = ats.Body;//File content
            
            //cVersion.OwnerId = attach.OwnerId;//Owner of the file
            cVersion.Origin = 'H';//C-Content Origin. H-Chatter Origin.
            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            Insert cVersion;
            
            System.debug('sucessfully insert :'+cVersion);
        
        // After saving the Content Version, get the ContentDocumentId
        Id ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cVersion.Id].ContentDocumentId;
        
        // Loop through idOftheEmailData and create ContentDocumentLink records for each email record
        
            ContentDocumentLink link = new ContentDocumentLink(
                ContentDocumentId = ContentDocumentId,
                LinkedEntityId = latestEmailData.ID,
                ShareType = 'V'
            );
            insert link;
            System.debug('Link: ' + link);
                
            }
            

            // Query  Email_Data__c record
           

            // attachment Insertion
             //Insert ContentVersion
          


            
        }
    }
}