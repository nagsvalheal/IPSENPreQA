/**
* @description This class handles the functionality for sending an email summary for Coverage Benefits.
*/
public with sharing class CoverageBenefitEmailSummary {
    @InvocableMethod(label='Coverage Benefit Email Summary' description='Coverage Benefit Email summary' category='Coverage Benefit Email summary')
    /**
* @description Sends an email summary for a coverage benefit to the specified contact.
* 
* @param request A list of EmailInputs containing the contact email, coverage benefit ID, and contact ID.
*/ 
public static void emailSummary(List<EmailInputs> request) {
    try {
        String contactEmail = request[0].contactEmail;
        String coverageId   = request[0].coverageBenefitId;
        String contactId    = request[0].contactId;

        // Fetch the email template to be used
        String sObjectType1 = 'EmailTemplate';
        String fields1 = 'Id';
        String conditions1 = 'Name = \'Journey HCP Office Coverage Benefit Template\'';

        List<EmailTemplate> templateId = (List<EmailTemplate>) COM_QueryUtility.executeQuery(sObjectType1, fields1, conditions1, true);
        
        // Check if template exists
        if (templateId == null || templateId.isEmpty()) {
            GenericLogger.debugLog('Error: Email template not found.');
            return;
        }
        
        // Create and configure the email message
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateID(templateId[0].Id);
        mail.setSaveAsActivity(false);
        mail.setWhatId(coverageId);
        mail.setTargetObjectId(contactId);
        mail.setToAddresses(new String[] {contactEmail});
        
        // Fetch related files linked to the coverage benefit
        String sObjectType = 'ContentDocumentLink';
        String fields = 'ContentDocumentId';
        String conditions = 'LinkedEntityId = \'' + coverageId + '\'';

        List<ContentDocumentLink> cdlList = (List<ContentDocumentLink>) COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
        
        // Ensure there is at least one ContentDocumentLink found
        if (cdlList.isEmpty()) {
            GenericLogger.debugLog('Error: No ContentDocumentLink found for the given Coverage Benefit.');
            return;
        }
        
        // Fetch the latest version of the file from ContentVersion
        String sObjectType2 = 'ContentVersion';
        String fields2 = 'Title, VersionData, FileExtension';
        String conditions2 = 'ContentDocumentId = \'' + cdlList[0].ContentDocumentId + '\' AND IsLatest = true';
        
        List<ContentVersion> cvList = (List<ContentVersion>) COM_QueryUtility.executeQuery(sObjectType2, fields2, conditions2, true);
        
        // Ensure the ContentVersion exists
        if (cvList.isEmpty()) {
            GenericLogger.debugLog('Error: No ContentVersion found for the given ContentDocument.');
            return;
        }
        
        // Prepare the email file attachment
        Blob fileData = cvList[0].VersionData;
        Messaging.EmailFileAttachment emlAtt = new Messaging.EmailFileAttachment();
        emlAtt.setFilename(cvList[0].Title /*+ cvList[0].FileExtension*/);
        emlAtt.setBody(fileData);
        mail.setFileAttachments(new Messaging.EmailFileAttachment[]{emlAtt});
        
        // Send the email
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {mail};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        // Display if the email was sent successfully
        if (results[0].success) {
            GenericLogger.debugLog('Email sent successfully.');
        } else {
            GenericLogger.debugLog('Email delivery failed.');
        }
    } catch (Exception e) {
        // Log the exception
        GenericLogger.exceptionLog('CoverageBenefitEmailSummary', 'emailSummary', e);
    }
}
    /**
* @description Class representing the input parameters required for sending the email summary.
*/
    public class EmailInputs{
        /** The email address of the contact to send the email to. */
        @InvocableVariable
        public String contactEmail;
        
        /** The ID of the coverage benefit related to the email. */
        @InvocableVariable
        public String coverageBenefitId;
        /** The ID of the contact to send the email to. */
        @InvocableVariable
        public String contactId;
        
    }
}