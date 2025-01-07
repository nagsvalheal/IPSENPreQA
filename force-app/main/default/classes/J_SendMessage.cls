/**
 * @description The SendMessage class provides utility methods for managing messaging 
 * functionality in Salesforce, including fetching team members, sending messages 
 * with attachments, fetching message attachments, and validating file size.
 * 
 * @class SendMessage
 * @scope public with sharing
 */
public with sharing class J_SendMessage {
    /**
     * @description Stores error messages for debugging purposes.
     */

    private static String errorMsg = '';

    /**
     * @description Fetches team members for the provided user ID. 
     * It retrieves the team members associated with the logged-in user and their 
     * care programs, excluding the logged-in user.
     * 
     * @param userId The ID of the current logged-in user.
     * @return A list of unique CareProgramTeamMember records excluding the logged-in user.
     * @AuraEnabled This method can be accessed from Lightning components and supports caching.
     */
    @AuraEnabled(cacheable=true)
    public static List<CareProgramTeamMember> getCareProgramTeamMember(String userId) {
        try {
            // Fetch the current user's team members
             List<CareProgramTeamMember> teamlist = (List<CareProgramTeamMember>) COM_QueryUtility.executeQuery(
                'CareProgramTeamMember', 
                'Id, AccountId, CareProgramId, Name, UserId', 
                'UserId = \'' + userId + '\'', 
                true
            );

            Set<Id> careProgramIds = new Set<Id>();
            for (CareProgramTeamMember member : teamlist) {
                careProgramIds.add(member.CareProgramId);
            }

            // Fetch all other team members in the same care programs
            List<CareProgramTeamMember> teamlistMain = COM_QueryUtility.executeQuery(
            'CareProgramTeamMember',
            'Id, AccountId, CareProgramId, Name, UserId',
            'CareProgramId IN ' +careProgramIds + 
            ' AND UserId != \'' +userId+ '\'',
            true
        );

            Map<Id, CareProgramTeamMember> uniqueUserIds = new Map<Id, CareProgramTeamMember>();
            for (CareProgramTeamMember member : teamlistMain) {
                uniqueUserIds.put(member.UserId, member);
            }

            return uniqueUserIds.values();
        } catch (Exception e) {
            logException('getCareProgramTeamMember', e);
            throw new AuraHandledException('Error fetching team members: ' + e.getMessage());
        }
    }
/**
 * @description Wrapper class to hold parameters for creating a J_Send_Message__c record.
 */
    public class MessageWrapper {
        /** @description The ID of the recipient. */
            public String recipientId { get; set; }
        /** @description The message content. */
            public String message { get; set; }
         /** @description The sender of the message. */
            public String sender { get; set; }
        /** @description The task ID associated with the message. */
            public String taskId { get; set; }
         /** @description The record type developer name for the J_Send_Message__c record. */
            public String recordType { get; set; }
        /** @description List of attachment IDs associated with the message. */
            public List<String> attachmentIds { get; set; }
        
        /**
         * @description No-argument constructor that initializes the attachmentIds list.
         */        
        public MessageWrapper() {
                this.attachmentIds = new List<String>(); // Initialize the list to avoid null reference
            }
        }
    /**
     * @description Sends messages to a recipient, creates corresponding message records,
     * and handles associated attachments.
     * 
     * @param recipientId The ID of the recipient user.
     * @param message The message content.
     * @param attachmentIds A list of attachment document IDs.
     * @param sender The ID of the sender user.
     * @param taskId The associated task ID for the message.
     * @AuraEnabled This method can be accessed from Lightning components.
     */
    @AuraEnabled
    public static void sendMessagedata(String recipientId, String message, List<String> attachmentIds, String sender, String taskId) {
        try {
        MessageWrapper senderWrapper = new MessageWrapper();
        senderWrapper.recipientId = recipientId;
        senderWrapper.message = message;
        senderWrapper.sender = sender;
        senderWrapper.taskId = taskId;
        senderWrapper.recordType = J_ObjectUtils.SEND_MESSAGE_SENDER_RECORDTYPE;
        senderWrapper.attachmentIds = attachmentIds;

        MessageWrapper receiverWrapper = new MessageWrapper();
        receiverWrapper.recipientId = recipientId;
        receiverWrapper.message = message;
        receiverWrapper.sender = sender;
        receiverWrapper.taskId = taskId;
        receiverWrapper.recordType = J_ObjectUtils.SEND_MESSAGE_RECEIVER_RECORDTYPE;
        receiverWrapper.attachmentIds = attachmentIds;
            // Insert sender and receiver messages
            J_Send_Message__c senderMessage = createMessageRecord(senderWrapper);
            J_Send_Message__c receiverMessage = createMessageRecord(receiverWrapper);

            // Insert attachment links if provided
            if (!attachmentIds.isEmpty()) {
                insertAttachmentLinks(senderMessage.Id, attachmentIds);
                insertAttachmentLinks(receiverMessage.Id, attachmentIds);
            }
        } catch (Exception e) {
            logException('sendMessagedata', e);
            throw new AuraHandledException('Error sending message: ' + e.getMessage());
        }
    }

    private static J_Send_Message__c createMessageRecord(MessageWrapper messageWrapper) {
        try {
            Id recordTypeId = Schema.SObjectType.J_Send_Message__c.getRecordTypeInfosByDeveloperName().get(messageWrapper.recordType).getRecordTypeId();
            J_Send_Message__c newMessage = new J_Send_Message__c(
                J_Sent_To__c = messageWrapper.recipientId,
                J_Message__c = messageWrapper.message,
                J_From__c = messageWrapper.sender,
                J_Task__c = messageWrapper.taskId,
                RecordTypeId = recordTypeId,
                J_Attachments__c = !messageWrapper.attachmentIds.isEmpty()
            );

            Database.SaveResult saveResult = Database.insert(newMessage, false);
            if (!saveResult.isSuccess()) {
                for (Database.Error error : saveResult.getErrors()) {
                    errorMsg += 'Error inserting message: ' + error.getFields() + '--' + error.getMessage() + '\n';
                }
                throw new AuraHandledException('Error saving message: ' + errorMsg);
            }
            return newMessage;
        } catch (Exception e) {
            logException('createMessageRecord', e);
            throw e;
        }
    }
/**
     * @description Associates attachment documents with a specific message record.
     * 
     * @param messageId The ID of the message record to link attachments to.
     * @param attachmentIds A list of attachment document IDs.
     */
    private static void insertAttachmentLinks(Id messageId, List<String> attachmentIds) {
        try {
            List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();
            for (String attachmentId : attachmentIds) {
                documentLinks.add(new ContentDocumentLink(
                    ContentDocumentId = attachmentId,
                    LinkedEntityId = messageId,
                    ShareType = 'I',
                    Visibility = 'AllUsers'
                ));
            }
            Database.SaveResult[] results = Database.insert(documentLinks, false);
            for (Database.SaveResult result : results) {
                if (!result.isSuccess()) {
                    for (Database.Error error : result.getErrors()) {
                        errorMsg += 'Error inserting attachment link: ' + error.getFields() + '--' + error.getMessage() + '\n';
                    }
                    throw new AuraHandledException('Error saving attachments: ' + errorMsg);
                }
            }
        } catch (Exception e) {
            logException('insertAttachmentLinks', e);
            throw e;
        }
    }

   /**
     * @description Fetches a map of attachment IDs and their titles for a specific message.
     * 
     * @param messageId The ID of the message to retrieve attachments for.
     * @return A map of attachment document IDs to their titles.
     * @AuraEnabled This method can be accessed from Lightning components and supports caching.
     */
    @AuraEnabled(cacheable=true)
    public static Map<Id, String> getMessageAttachments(String messageId) {
        try {
            List<ContentDocumentLink> files = COM_QueryUtility.executeQuery(
                'ContentDocumentLink', 
                'ContentDocumentId', 
                'LinkedEntityId = \'' + messageId + '\'', 
                true
            );

            Set<Id> fileIds = new Set<Id>();
            for (ContentDocumentLink docLink : files) {
                fileIds.add(docLink.ContentDocumentId);
            }
             List<ContentVersion> docs = COM_QueryUtility.executeQuery(
                 'ContentVersion',
                 'ContentDocumentId, FileExtension, Title', 
                 'ContentDocumentId IN = \'' + fileIds + '\'', 
                true
            );

            Map<Id, String> mapIdTitle = new Map<Id, String>();
            for (ContentVersion doc : docs) {
                mapIdTitle.put(doc.ContentDocumentId, doc.Title);
            }
            return mapIdTitle;
        } catch (Exception e) {
            logException('getMessageAttachments', e);
            throw new AuraHandledException('Error fetching attachments: ' + e.getMessage());
        }
    }

    /**
     * @description Validates the size of a given document and deletes it if it exceeds the allowed size.
     * 
     * @param contentDocumentId The ID of the document to validate.
     * @return 'SUCCESS' if the size is valid; 'ERROR' if the document is deleted due to size.
     * @AuraEnabled This method can be accessed from Lightning components.
     */
    @AuraEnabled
    public static String contentSize(String contentDocumentId) {
        try {
             List<ContentDocument> docs = (List<ContentDocument>) COM_QueryUtility.executeQuery(
                'ContentDocument', 
                'Id, ContentSize', 
                'Id = \'' + contentDocumentId + '\'', 
                true
            );     
            if(docs!=null && !docs.isEmpty()){
            ContentDocument doc=docs[0];
           if (doc.ContentSize > 10485760) { // 10 MB
                List<SObject> recordsToDelete = new List<SObject>{ doc };
                COM_DatabaseOperationsUtility.deleteOperation(
                recordsToDelete,
                'J_SendMessage', // className
                false // userModeLevel
            );
            }
           }
            return 'SUCCESS';
        } catch (Exception e) {
            logException('contentSize', e);
            throw new AuraHandledException('Error validating file size: ' + e.getMessage());
        }
    }
/**
     * @description Logs exceptions in a generic logging framework for tracking and debugging.
     * 
     * @param methodName The name of the method where the exception occurred.
     * @param e The exception to be logged.
     */
    private static void logException(String methodName, Exception e) {
        GenericLogger.exceptionLog('J_SendMessage', methodName, e);
    }
}