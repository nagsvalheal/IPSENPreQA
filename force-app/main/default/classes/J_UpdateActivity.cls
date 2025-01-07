/**
 * This class provides functionality to update an activity record.
 * 
 * @description The `J_UpdateActivity` class contains a static method that updates an activity based on the record ID and object type provided.
 */
public with sharing class J_UpdateActivity {
/**
     * @description  Updates an activity record based on the provided record ID and sObject type.
     *
     * @param recId The ID of the record to update.
     * @param sObjectType The type of sObject to update (e.g., 'Task', 'Event').
     * @return A string message indicating the outcome of the update.
     */
    public static string updateActivity(Id recId, String sObjectType) {
        string recStatus = '';

        String query = 'SELECT Id, Subject, WhatId, ActivityDate ' +
                       'FROM ' + sObjectType +
                       ' WHERE Id = :recId AND J_InteractionDetails__c = null';

        List<sObject> activities = Database.query(query);

        if (activities.isEmpty()) {
            recStatus = 'Interaction Record is already created for this task record';
            return recStatus;
        }
            UserRole currentUserRole = getCurrentUserRole();

            if (currentUserRole == null || String.isEmpty(currentUserRole.DeveloperName)) {
                recStatus = 'Interaction Record cannot be created for this user';
                return recStatus;
            }
                Map<String, J_Interaction_Details_Map__mdt> interactionDetailsMap =
                    getInteractionDetailsMap(currentUserRole.DeveloperName);

                if (interactionDetailsMap.isEmpty() || !isInteractionValid(activities[0], currentUserRole, interactionDetailsMap, sObjectType)) {
                    recStatus = 'Interaction Record cannot be created for this user';
                    return recStatus;
                }
                    String recordTypeName = interactionDetailsMap.get(
                        generateInteractionKey(activities[0], currentUserRole, sObjectType)
                    ).J_InteractionDetailsRecordType__c;

                    if (String.isBlank(recordTypeName)) {
                        recStatus = 'Interaction Record cannot be created for this user';
                        return recStatus;
                    }
                        recStatus = createInteractionRecord(recId, sObjectType, activities[0], recordTypeName);
                    
                
            
        

        return recStatus;
    }

    private static UserRole getCurrentUserRole() {
        Id userRoleId = UserInfo.getUserRoleId();
        if (String.isNotEmpty(userRoleId)) {
            return [SELECT DeveloperName FROM UserRole WHERE Id = :userRoleId WITH SECURITY_ENFORCED];
        }
        return null;
    }

    private static Map<String, J_Interaction_Details_Map__mdt> getInteractionDetailsMap(String currentUserRole) {
        List<J_Interaction_Details_Map__mdt> interactionDetailsList = [
            SELECT J_ActivitySubject__c, J_InteractionDetailsRecordType__c, User_Role__c, Object_Name__c
            FROM J_Interaction_Details_Map__mdt
            WHERE User_Role__c = :currentUserRole
        ];

        Map<String, J_Interaction_Details_Map__mdt> interactionDetailsMap = new Map<String, J_Interaction_Details_Map__mdt>();
        for (J_Interaction_Details_Map__mdt detail : interactionDetailsList) {
            String key = detail.J_ActivitySubject__c + detail.User_Role__c + detail.Object_Name__c;
            interactionDetailsMap.put(key, detail);
        }
        return interactionDetailsMap;
    }

    private static Boolean isInteractionValid(sObject activity, UserRole currentUserRole,
                                            Map<String, J_Interaction_Details_Map__mdt> interactionDetailsMap,
                                            String sObjectType) {
        String subject = (String) activity.get('Subject');
        return !String.isBlank(subject) &&
            interactionDetailsMap.containsKey(subject + currentUserRole.DeveloperName + sObjectType);
    }

    private static String generateInteractionKey(sObject activity, UserRole currentUserRole, String sObjectType) {
        return (String) activity.get('Subject') + currentUserRole.DeveloperName + sObjectType;
    }

    private static String createInteractionRecord(Id recId, String sObjectType, sObject activity, String recordTypeName) {
        try {
            String recordTypeId = J_ObjectUtils.getRecordTypeId(recordTypeName, 'J_InteractionDetails__c');
            Id whatId = (Id) activity.get('WhatId');
            String subject = (String) activity.get('Subject');
            Date dueDate = (Date) activity.get('ActivityDate');

            CareProgramEnrollee enrollee = [SELECT Id FROM CareProgramEnrollee WHERE Id = :whatId];

            J_InteractionDetails__c interactionDetail = new J_InteractionDetails__c(
                RecordTypeId = recordTypeId,
                J_Date__c = dueDate,
                Parent_Activity_Id__c = recId,
                Care_Program_Enrollee__c = enrollee.Id,
                J_Task_Subject__c = subject
            );

            if (Schema.sObjectType.J_InteractionDetails__c.fields.J_Date__c.isCreateable()) {
                insert interactionDetail;
            }

            sObject activityToUpdate = Schema.getGlobalDescribe().get(sObjectType).newSObject();
            activityToUpdate.put('Id', recId);
            activityToUpdate.put('J_InteractionDetails__c', interactionDetail.Id);
            update activityToUpdate;

            return 'Interaction Record created successfully';
        } catch (Exception ex) {
            return handleException(ex);
        }
    }

    private static String handleException(Exception ex) {
        String errorMessage = ex.getMessage();
        if (errorMessage.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION,')) {
            Integer index = errorMessage.indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
            if (index != -1) {
                errorMessage = errorMessage.substring(index + 34).replace('.: []', '');
            }
        }
        return errorMessage;
    }
}