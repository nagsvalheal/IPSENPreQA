/**
 *   @author         Arkadii Sychov
 *   @date           10/21/20
 *   @description    IPSC-213. Interaction Details can't be edited if the related Task or Event has 'Cancelled' or 'Submitted' status
 **/
public with sharing class J_InteractionDetailsTriggerHandler {
  private static final List<String> ACTIVITYSTATUSESFORBIDDEN = new List<String>{
    J_ObjectUtils.TASK_STATUS_PL_SUBMITTED,
    J_ObjectUtils.TASK_STATUS_PL_CANCELLED
  };

  public void checkActivityStatus(
    Map<Id, J_InteractionDetails__c> newInteractionDetails,
    Map<Id, J_InteractionDetails__c> oldInteractionDetails
  ) {
    String journeyUserProfileId = J_ObjectUtils.getProfileIdByName(
      J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER
    );

    if (isInfoFieldsEdited(newInteractionDetails, oldInteractionDetails)) {
      return;
    }

    if (shouldProcessTasks(journeyUserProfileId)) {
      processTasksAndEvents(newInteractionDetails);
    }
  }

  private Boolean isInfoFieldsEdited(
    Map<Id, J_InteractionDetails__c> newInteractionDetails,
    Map<Id, J_InteractionDetails__c> oldInteractionDetails
  ) {
    if (oldInteractionDetails == null) {
      return false;
    }

    String fields = 'MasterLabel';
    String conditions = ''; // No specific filter, fetch all records
    Boolean withUserMode = false;

    List<SObject> metadataRecords = COM_QueryUtility.executeQuery(
      'J_Interaction_Details_Info_Fields__mdt',
      fields,
      conditions,
      withUserMode
    );

    for (Id interactionDetailsId : newInteractionDetails.keySet()) {
      for (SObject metadata : metadataRecords) {
        String fieldName = (String) metadata.get('MasterLabel');
        if (
          newInteractionDetails.get(interactionDetailsId).get(fieldName) !=
          oldInteractionDetails.get(interactionDetailsId).get(fieldName)
        ) {
          return true;
        }
      }
    }

    return false;
  }

  private Boolean shouldProcessTasks(String journeyUserProfileId) {
    return String.isNotBlank(journeyUserProfileId) &&
      journeyUserProfileId.equalsIgnoreCase(UserInfo.getProfileId());
  }

  private void processTasksAndEvents(
    Map<Id, J_InteractionDetails__c> newInteractionDetails
  ) {
    List<Task> tasks = getTasks(newInteractionDetails.keySet());
    List<Event> events = getEvents(newInteractionDetails.keySet());

    if (!tasks.isEmpty()) {
      addErrorsToInteractionDetails(tasks, newInteractionDetails);
    }
  }

  @TestVisible
  private List<Task> getTasks(Set<Id> interactiondetailsides) {
    List<String> interactionDetailsIdsStr = new List<String>();
    for (Id interactionDetailId : interactiondetailsides) {
        interactionDetailsIdsStr.add(interactionDetailId.toString());
    }
    String sObjectType = 'Task';
    String fields = 'Id, Status, J_InteractionDetails__c';
      String conditions = 'J_InteractionDetails__c IN (\'' +
                        String.join(interactionDetailsIdsStr, ',')  +
                        '\'' +') AND Status IN (\'' + ACTIVITYSTATUSESFORBIDDEN + '\'' + ')';

    List<SObject> results = COM_QueryUtility.executeQuery(
      sObjectType,
      fields,
      conditions,
      true
    );

    return (List<Task>) results;
  }

  @TestVisible
  private List<Event> getEvents(Set<Id> interactiondetailsides) {
    List<String> interactionDetailsIdsStr = new List<String>();
    for (Id interactionDetailId : interactiondetailsides) {
        interactionDetailsIdsStr.add(interactionDetailId.toString());
    }
    String sObjectType = 'Event';
    String fields = 'Id, J_ActivityStatus__c, J_InteractionDetails__c';
    String conditions = 'J_InteractionDetails__c IN (\'' +
                        String.join(interactionDetailsIdsStr, ',') + '\'' +
                        ') AND J_ActivityStatus__c IN (\''+ ACTIVITYSTATUSESFORBIDDEN + '\'' + ')';

    List<SObject> results = COM_QueryUtility.executeQuery(
      sObjectType,
      fields,
      conditions,
      true
    );

    return (List<Event>) results;
  }

  private void addErrorsToInteractionDetails(
    List<sObject> activities,
    Map<Id, J_InteractionDetails__c> interactionDetails
  ) {
    for (sObject a : activities) {
      interactionDetails.get(
          (Id) a.get(J_ObjectUtils.ACTIVITY_INTERACTION_DETAILS_API_NAME)
        )
        .addError(
          Label.J_ErrorInteractionDetailsCantBeEditedDoeToActivityStatus
        );
    }
  }

  public void generateCCUserTask(
    Map<Id, J_InteractionDetails__c> interactionDetailsByIds
  ) {
    if (interactionDetailsByIds.isEmpty()) {
      return;
    }

    Map<Id, J_InteractionDetails__c> interactionDetailsToUse = filterInteractionDetails(
      interactionDetailsByIds
    );

    if (interactionDetailsToUse.isEmpty()) {
      return;
    }

    List<Task> relatedTasks = fetchRelatedTasks(
      interactionDetailsToUse.keySet()
    );

    if (relatedTasks.isEmpty()) {
      return;
    }

    List<Task> tasksToInsert = createTasks(
      interactionDetailsToUse,
      relatedTasks
    );

    // Step 4: Insert tasks if permitted
    insertTasksIfAllowed(tasksToInsert);
  }

  private Map<Id, J_InteractionDetails__c> filterInteractionDetails(
    Map<Id, J_InteractionDetails__c> interactionDetailsByIds
  ) {
    Set<String> validTopics = new Set<String>{
      'New Physician',
      'Supply Issue',
      'HCP Issue',
      'Insurance'
    };
    Map<Id, J_InteractionDetails__c> filteredDetails = new Map<Id, J_InteractionDetails__c>();

    for (J_InteractionDetails__c detail : interactionDetailsByIds.values()) {
      if (String.isNotEmpty(detail.J_DiscussionTopics__c)) {
        List<String> topics = detail.J_DiscussionTopics__c.split(';');
        for (String topic : topics) {
         
          if (validTopics.contains(topic)) {
              filteredDetails.put(detail.Id, detail);
              break; 
          }
      }
      }
    }
    return filteredDetails;
  }

 

  private static List<Task> fetchRelatedTasks(Set<Id> interactionDetailIds) {
    // Convert interactionDetailIds to a list of strings
    List<String> interactionDetailIdsList = new List<String>();
    for (Id detailId : interactionDetailIds) {
        interactionDetailIdsList.add(String.valueOf(detailId));
    }
    
    // Create the condition string for the WHERE clause
    String conditionIds = '(\'' + String.join(interactionDetailIdsList, '\', \'') + '\')';
    
    // Define the fields to be selected from Task
    String fields = 'AccountId, Account.J_CCTerritory__r.OwnerId, Account.PersonContactId, J_InteractionDetails__c';
    
    // Define the conditions for the WHERE clause
    String conditions = 'J_InteractionDetails__c IN ' + conditionIds;
    
    // Call the executeQuery method to fetch the tasks
    List<SObject> queriedTasks = COM_QueryUtility.executeQuery(
        'Task',
        fields,
        conditions,
        true // Assuming USER_MODE is needed here, you can change as per your requirements
    );
    
    // Convert the query result to a list of Task objects
    List<Task> relatedTasks = new List<Task>();
    for (SObject sObj : queriedTasks) {
        relatedTasks.add((Task) sObj);
    }
    
    return relatedTasks;
}


  private List<Task> createTasks(
    Map<Id, J_InteractionDetails__c> interactionDetailsToUse,
    List<Task> relatedTasks
  ) {
    String taskRecordTypeId = J_ObjectUtils.getRecordTypeId(
      J_ObjectUtils.TASK_RT_CARE_PLAN_TASK,
      J_ObjectUtils.TASK_API_NAME
    );
    Set<String> validTopics = new Set<String>{
      'New Physician',
      'Supply Issue',
      'HCP Issue',
      'Insurance'
    };
    List<Task> tasksToInsert = new List<Task>();

    for (Task relatedTask : relatedTasks) {
      J_InteractionDetails__c interactionDetails = interactionDetailsToUse.get(
        relatedTask.J_InteractionDetails__c
      );
      if (interactionDetails != null) {
        List<String> topics = interactionDetails.J_DiscussionTopics__c.split(
          ';'
        );
        for (String topic : topics) {
          if (validTopics.contains(topic)) {
            tasksToInsert.add(
              new Task(
                RecordTypeId = taskRecordTypeId,
                ActivityDate = Date.today().addDays(7),
                Subject = topic,
                Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
                Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                WhoId = relatedTask.Account.PersonContactId,
                WhatId = relatedTask.AccountId
              )
            );
          }
        }
      }
    }
    return tasksToInsert;
  }

  private void insertTasksIfAllowed(List<Task> tasksToInsert) {
    try {
      List<SObject> tasksToInsertSObjects = new List<SObject>();
        for (Task task : tasksToInsert) {
            tasksToInsertSObjects.add(task);  // Adding Task objects to a List<SObject>
        }
      Database.SaveResult[] insertResults = COM_DatabaseOperationsUtility.insertOperation(
        tasksToInsertSObjects,
       'J_InteractionDetailsTriggerHandler',
        true
      );

      for (Database.SaveResult result : insertResults) {
        if (!result.isSuccess()) {
          // GenericLogger.exceptionLog(
          //   'J_InteractionDetailsTriggerHandler',
          //   'insertTasksIfAllowed',
          //   result.getErrors()[0].getMessage()
          // );
        }
      }
    } catch (Exception ex) {
      GenericLogger.exceptionLog(
        'J_InteractionDetailsTriggerHandler',
        'insertTasksIfAllowed',
        ex
      );
    
    }
  }

  public void updateTaskRecords(
    Map<Id, J_InteractionDetails__c> newMapInteractionDetails,
    Map<Id, J_InteractionDetails__c> oldMapInteractionDetails
  ) {
    Set<Id> interactionIdsToUpdate = getInteractionIdsToUpdate(
      newMapInteractionDetails,
      oldMapInteractionDetails
    );

    List<Task> tasksToUpdate = getTasksForUpdate(
      interactionIdsToUpdate,
      newMapInteractionDetails
    );

    if (!tasksToUpdate.isEmpty()) {
      updateTasksIfAllowed(tasksToUpdate);
    }
  }

  private Set<Id> getInteractionIdsToUpdate(
    Map<Id, J_InteractionDetails__c> newMapInteractionDetails,
    Map<Id, J_InteractionDetails__c> oldMapInteractionDetails
  ) {
    Set<Id> interactionIds = new Set<Id>();

    for (
      J_InteractionDetails__c newIntDetail : newMapInteractionDetails.values()
    ) {
      J_InteractionDetails__c oldIntDetail = oldMapInteractionDetails.get(
        newIntDetail.Id
      );
      if (
        newIntDetail.J_FollowUpNeeded__c &&
        newIntDetail.Follow_up_Date_Time__c !=
        oldIntDetail.Follow_up_Date_Time__c
      ) {
        interactionIds.add(newIntDetail.Id);
      }
    }

    return interactionIds;
  }


  private static List<Task> getTasksForUpdate(
    Set<Id> interactionIds,
    Map<Id, J_InteractionDetails__c> newMapInteractionDetails
) {
    // Convert interactionIds to a list of strings
    List<String> interactionIdStrings = new List<String>();
    for (Id interactionId : interactionIds) {
        interactionIdStrings.add(interactionId.toString());  
    }
    
    // Create the condition string for the WHERE clause
    String conditionIds = '(\'' + String.join(interactionIdStrings, '\', \'') + '\')';
    
    // Define the fields to be selected from Task
    String fields = 'Id, ActivityDate, Status, J_InteractionDetails__c';
    
    // Define the conditions for the WHERE clause
    String conditions = 'J_InteractionDetails__c IN ' + conditionIds;
    
    // Call the executeQuery method to fetch the tasks
    List<SObject> queriedTasks = COM_QueryUtility.executeQuery(
        'Task',
        fields,
        conditions,
        false // Assuming no need for USER_MODE here
    );
    
    // Convert the query result to a list of Task objects
    List<Task> tasksToUpdate = new List<Task>();
    for (SObject sObj : queriedTasks) {
        Task task = (Task) sObj;
        
        // If the Task is related to an Interaction Detail and the interaction detail exists in the map, update the Task
        if (newMapInteractionDetails.containsKey(task.J_InteractionDetails__c)) {
            task.ActivityDate = Date.valueOf(
                newMapInteractionDetails.get(task.J_InteractionDetails__c)
                    .Follow_up_Date_Time__c
            );
            tasksToUpdate.add(task);
        }
    }
    
    return tasksToUpdate;
}


  private void updateTasksIfAllowed(List<Task> tasksToUpdate) {
    try {
      List<SObject> tasksToUpdateSObjects = new List<SObject>();
for (Task task : tasksToUpdate) {
    tasksToUpdateSObjects.add(task);  // Adding Task to List<SObject>
}
      
      Database.SaveResult[] updateResults = COM_DatabaseOperationsUtility.updateOperation(
        tasksToUpdateSObjects,
        'J_InteractionDetailsTriggerHandler',
        true
      );
      for (Database.SaveResult result : updateResults) {
        if (!result.isSuccess()) {
          System.debug('Failed to update task: ' + result.getErrors());
        }
      }
    } catch (Exception ex) {
      GenericLogger.exceptionLog(
        'J_InteractionDetailsTriggerHandler',
        'updateTasksIfAllowed',
        ex
      );
      
    }
  }
}