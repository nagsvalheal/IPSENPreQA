/**
 *  @author         Anand S
 *  @date           04/02/2024
 *  @description    This is a class used for 1 to 1 Messaging LWC component for Viewing the messages
 **/

 public with sharing class J_SendMessageController {
/**
 * @description Represents a message object with detailed metadata, including sender, recipient, content, and associated task details.
 *              This class is used to transfer message data between the server and client-side Lightning/Aura components.
 *              
 * @usage This wrapper class is primarily used in Apex controllers to encapsulate message-related data
 *        and make it accessible to Lightning components via AuraEnabled annotations.
 * 
 * @example
 * // Example of creating a MessageWrapper instance:
 * MessageWrapper message = new MessageWrapper();
 * message.messageId = '00Q8A0000012abc';
 * message.messageName = 'Approval Request';
 * message.sentToId = '0058A000002abc';
 * message.sentToName = 'John Doe';
 * message.fromId = '0058A000003def';
 * message.fromName = 'Jane Smith';
 * message.messageContent = 'Your request has been approved.';
 * message.taskId = '00T8A0000012ghi';
 * message.recordTypeId = '0128A0000012jkl';
 * message.createdDate = System.now();
 */
    public class MessageWrapper {
        /**
     * @description The ID of the message.
     */

        @AuraEnabled public Id messageId { get; set; }
        /**
     * @description The ID of the message.
     */
        @AuraEnabled public String messageName { get; set; }
        /**
     * @description The ID of the recipient (sent-to) of the message.
     */
        @AuraEnabled public Id sentToId { get; set; }
        /**
     * @description The name of the recipient (sent-to) of the message.
     */
        @AuraEnabled public String sentToName { get; set; }
/**
     * @description The ID of the sender (from) of the message. 
     */
        @AuraEnabled public Id fromId { get; set; }
        /**
     * @description The name of the sender (from) of the message.
     */
        @AuraEnabled public String fromName { get; set; }
        /**
     * @description The content of the message.
     */
        @AuraEnabled public String messageContent { get; set; }
        /**
     * @description The ID of the related task associated with the message.
     */
        @AuraEnabled public Id taskId { get; set; }
        /**
     * @description The record type ID of the message.
     */
        @AuraEnabled public String recordTypeId { get; set; }
        /**
     * @description The date and time when the message was created.
     */
        @AuraEnabled public Datetime createdDate { get; set; }
/**
         * @description Constructor to initialize the MessageWrapper with data from the J_Send_Message__c object.
         * @param message The message record used to populate the wrapper.
         * @param recordTypeId The record type ID for the message.
         */

        public MessageWrapper(J_Send_Message__c message, String recordTypeId) {
            this.messageId = message.Id;
            this.messageName = message.Name;
            this.sentToId = message.J_Sent_To__r != null ? message.J_Sent_To__r.Id : null;
            this.sentToName = message.J_Sent_To__r != null ? message.J_Sent_To__r.Name : null;
            this.fromId = message.J_From__r != null ? message.J_From__r.Id : null;
            this.fromName = message.J_From__r != null ? message.J_From__r.Name : null;
            this.messageContent = message.J_Message__c;
            this.taskId = message.J_Task__c;
            this.createdDate = message.CreatedDate;
            this.recordTypeId = recordTypeId;
        }
    }

    /**
 * @description Retrieves a list of messages based on the provided record ID and user ID.
 *              The messages fetched depend on the user's role and the record types.
 * @param recordId The ID of the record for which messages are to be retrieved.
 * @param userId The ID of the user requesting the messages.
 * @return List of MessageWrapper objects containing message details.
 * @throws AuraHandledException If an error occurs while fetching messages.
 * @notes Uses role-based logic to filter messages for PEL, JM, and CC users.
 */
    @AuraEnabled(cacheable=true)
    public static List<MessageWrapper> getMessages(String recordId, String userId) {
        List<MessageWrapper> messages = new List<MessageWrapper>();
        try {
            UserRole currentUserRole = getCurrentUserRole(userId);
            String userRoleDeveloperName = currentUserRole != null ? currentUserRole.DeveloperName : null;

            Id recordTypeId1 = getRecordTypeId(J_ObjectUtils.SEND_MESSAGE_SENDER_RECORDTYPE);
            Id recordTypeId2 = getRecordTypeId(J_ObjectUtils.SEND_MESSAGE_RECEIVER_RECORDTYPE);

            if (userRoleDeveloperName == J_ObjectUtils.ROLE_NAME_PEL_USER) {
                messages = getMessagesForPELUser(recordId, userId, recordTypeId1, recordTypeId2);
            } else if (userRoleDeveloperName == J_ObjectUtils.ROLE_NAME_JM_USER || userRoleDeveloperName == J_ObjectUtils.ROLE_NAME_CC_USER) {
                messages = getMessagesForJMOrCCUser(recordId, recordTypeId1, recordTypeId2);
            }
        } catch (Exception e) {
            GenericLogger.exceptionLog(e);
            throw new AuraHandledException('Error fetching messages: ' + e.getMessage());
        }
        return messages;
    }

    private static UserRole getCurrentUserRole(String userId) {
            List<User> users=COM_QueryUtility.executeQuery('User','UserRoleId','Id = :\''+userId+'\'',true);
            List<UserRole> roles = COM_QueryUtility.executeQuery('UserRole', 'Id, Name, DeveloperName ','Id IN \''+users+'\'',true);
            if(roles.size()>0) {
                return roles[0];
            }
            return null;
        }

    private static Id getRecordTypeId(String developerName) {
        return Schema.SObjectType.J_Send_Message__c.getRecordTypeInfosByDeveloperName()
            .get(developerName)
            .getRecordTypeId();
    }

    private static List<MessageWrapper> getMessagesForPELUser(String recordId, String userId, Id recordTypeId1, Id recordTypeId2) {
        List<J_Send_Message__c> sendMessages = COM_QueryUtility.executeComplexQueryWithOrderBy('[SELECT Id, Name, J_Sent_To__r.Id, J_Sent_To__r.Name, J_From__r.Id, J_From__r.Name, J_Message__c, J_Task__c, CreatedDate  FROM J_Send_Message__c WHERE J_Task__c = :recordId AND (J_Sent_To__r.Id = :userId OR J_From__r.Id = :userId) AND RecordTypeId = :recordTypeId1',true,'CreatedDate DESC NULLS LAST');
        List<MessageWrapper> messages = new List<MessageWrapper>();
        for (J_Send_Message__c message : sendMessages) {
            String recordTypeId = message.J_Sent_To__r.Id == userId ? recordTypeId2 : recordTypeId1;
            messages.add(new MessageWrapper(message, recordTypeId));
        }
        return messages;
    }

    private static List<MessageWrapper> getMessagesForJMOrCCUser(String recordId, Id recordTypeId1, Id recordTypeId2) {
        List<J_Send_Message__c> sendMessages = COM_QueryUtility.executeComplexQueryWithOrderBy('[SELECT Id, Name, J_Sent_To__r.Id, J_Sent_To__r.Name, J_From__r.Id, J_From__r.Name, J_Message__c, J_Task__c, CreatedDate  FROM J_Send_Message__c[SELECT Id, Name, J_Sent_To__r.Id, J_Sent_To__r.Name, J_From__r.Id, J_From__r.Name, J_Message__c, J_Task__c, CreatedDate FROM J_Send_Message__c WHEREJ_Task__c = :recordId AND RecordTypeId = :recordTypeId1',true,'CreatedDate DESC NULLS LAST');
        List<MessageWrapper> messages = new List<MessageWrapper>();
        for (J_Send_Message__c message : sendMessages) {
            messages.add(new MessageWrapper(message, recordTypeId2));
        }
        return messages;
    }
}