/**
 * @description       :
 * @author            :
 * @group             :
 * @last modified on  : 10-20-2022
 **/
public with sharing class J_TaskTriggerHandler {
    /**
 * @description Verifies if the current user has delete access for Task records and adds an error message
 *              to the Task records if the user lacks the necessary permissions.
 *
 * @param tasksToDelete A list of Task records that the user is attempting to delete.
 *
 * @throws SObjectException Thrown if an error occurs while querying the user's profile or if the user does not have delete permissions.
 *
 * @notes
 * - This method checks two levels of access:
 *   1. General delete permission on the Task object.
 *   2. Specific profile-based restrictions for users with the "Standard Journeys User" profile.
 * - If the user lacks delete access at either level, an error is added to the Task records, preventing their deletion.
 * - The `Label.J_YouDontHavePermissionToDeleteTasks` custom label is used to provide user-friendly error messages.
 */
  public void checkDeleteAccess(List<Task> tasksToDelete) {
    if (!Schema.sObjectType.Task.isDeletable()) {
      for (Task taskItem : tasksToDelete) {
        taskItem.addError(Label.J_YouDontHavePermissionToDeleteTasks);
      }
      return;
    }

    String fields = 'Name';
    String conditions = 'Id = \'' + UserInfo.getProfileId() + '\'';
    Boolean withUserMode = false;

    List<SObject> profileRecords = COM_QueryUtility.executeQuery(
      'Profile',
      fields,
      conditions,
      withUserMode
    );

    if (profileRecords.isEmpty()) {
      return;
    }

    Profile userProfile = (Profile) profileRecords[0];

    if (userProfile.Name == J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER) {
      for (Task taskItem : tasksToDelete) {
        taskItem.addError(Label.J_YouDontHavePermissionToDeleteTasks);
      }
    }
  }

  /**
   * @description Updates the interaction due date based on changes to task due dates,
   *              ensuring compliance with Salesforce governor limits and security rules.
   * @param tasks List of new Task records from the trigger.
   * @param oldTaskCopy List of old Task records from the trigger.
   */

  public void updateInteractionDueDate(
    List<Task> tasks,
    List<Task> oldTaskCopy
  ) {
    if (tasks == null || tasks.isEmpty() || Trigger.oldMap == null) {
      return;
    }

    Map<Id, Date> interactionDetailIdToNewDateMap = prepareInteractionDetailsMap(
      tasks
    );

    if (interactionDetailIdToNewDateMap.isEmpty()) {
      return;
    }

    List<J_InteractionDetails__c> detailToUpdate = fetchAndUpdateInteractionDetails(
      interactionDetailIdToNewDateMap
    );

    updateInteractionDetails(detailToUpdate);
  }

  private Map<Id, Date> prepareInteractionDetailsMap(List<Task> tasks) {
    Map<Id, Date> interactionDetailIdToNewDateMap = new Map<Id, Date>();

    for (Task task : tasks) {
      Task oldTask = (Task) Trigger.oldMap.get(task.Id);

      if (shouldUpdateInteractionDate(task, oldTask)) {
        interactionDetailIdToNewDateMap.put(
          task.J_InteractionDetails__c,
          task.ActivityDate
        );
      }
    }

    return interactionDetailIdToNewDateMap;
  }

  private Boolean shouldUpdateInteractionDate(Task task, Task oldTask) {
    return task != null &&
      oldTask != null &&
      task.ActivityDate != null &&
      task.J_InteractionDetails__c != null &&
      !task.ActivityDate.isSameDay(oldTask.ActivityDate);
  }

  public static List<J_InteractionDetails__c> fetchAndUpdateInteractionDetails(
    Map<Id, Date> interactionDetailIdToNewDateMap
  ) {
    List<J_InteractionDetails__c> detailToUpdate = new List<J_InteractionDetails__c>();

    if (!interactionDetailIdToNewDateMap.isEmpty()) {
      String sObjectType = 'J_InteractionDetails__c';
      String fields = 'Id, J_Date__c'; List<String> idList = new List<String>();
      for (Id recordId : interactionDetailIdToNewDateMap.keySet()) { idList.add((String) recordId);}
      String conditions = 'Id IN (\'' + String.join(idList, '\',\'') + '\')';
      Boolean withUserMode = true;

      // Execute query using the executeQuery method
      List<SObject> results = COM_QueryUtility.executeQuery( sObjectType,fields, conditions, withUserMode );

      for (SObject result : results) {
        J_InteractionDetails__c detail = (J_InteractionDetails__c) result;
        if ( Schema.sObjectType.J_InteractionDetails__c.fields.J_Date__c.isUpdateable()) {
          detail.J_Date__c = interactionDetailIdToNewDateMap.get(detail.Id); detailToUpdate.add(detail);
        }
      }
    }

    return detailToUpdate;
  }

  public static void updateInteractionDetails( List<J_InteractionDetails__c> detailToUpdate ) {
    if (detailToUpdate != null && !detailToUpdate.isEmpty()) {
      try {
        if (Schema.sObjectType.J_InteractionDetails__c.isUpdateable()) {
       
          COM_DatabaseOperationsUtility.updateOperation(detailToUpdate, 'J_InteractionDetailsTriggerHandler', true);
        }
       
      } catch (Exception ex) {
        GenericLogger.exceptionLog( 'J_TaskTriggerHandler','updateInteractionDueDate', ex );
      }
    }
  }

  /**
   * @description Validates if PEL Owner is assigned before a Task is submitted.
   *              Refactored to avoid deeply nested if statements.
   *
   * @param newTaskList List of new Task records being processed.
   */
  public void checkPELOwner(List<Task> newTaskList) {
    List<String> lstAccountIds = getRelevantTaskAccountIds(newTaskList);

    if (lstAccountIds.isEmpty()) {
      return;
    }

    Map<String, String> mpAccPELOwner = getAccountPELOwnerMap(lstAccountIds);

    validateTasks(newTaskList, mpAccPELOwner);
  }

  /**
   * @description Filters Task records to get account IDs for validation.
   *
   * @param newTaskList List of new Task records.
   * @return List of account IDs linked to the tasks.
   */
  private List<String> getRelevantTaskAccountIds(List<Task> newTaskList) {
    List<String> lstAccountIds = new List<String>();
    for (Task tsk : newTaskList) {
      if (
        tsk.Status == 'Submitted' &&
        tsk.Subject == 'Welcome Call' &&
        tsk.WhatId != null
      ) {
        lstAccountIds.add(tsk.WhatId);
      }
    }
    return lstAccountIds;
  }

  /**
   * @description Retrieves a map of account IDs to PEL Owner values.
   *
   * @param lstAccountIds List of account IDs to query.
   * @return Map of account IDs to their corresponding PEL Owners.
   */
  private Map<String, String> getAccountPELOwnerMap(
    List<String> lstAccountIds
  ) {
    Map<String, String> mpAccPELOwner = new Map<String, String>();

    if (lstAccountIds == null || lstAccountIds.isEmpty()) {
      return mpAccPELOwner;
    }

    String conditions =
      'Id IN (\'' +
      String.join(lstAccountIds, '\',\'') +
      '\')';
    String sObjectType = 'CareProgramEnrollee';
    String fields = 'Id, PEL_Owner__c';
    Boolean withUserMode = true;

    List<SObject> results = COM_QueryUtility.executeQuery(
      sObjectType,
      fields,
      conditions,
      withUserMode
    );

    for (SObject record : results) {
      CareProgramEnrollee enrollee = (CareProgramEnrollee) record;
      if (enrollee.PEL_Owner__c != null) {
        mpAccPELOwner.put(enrollee.Id, enrollee.PEL_Owner__c);
      }
    }

    return mpAccPELOwner;
  }

  /**
   * @description Validates tasks and adds error messages if PEL Owner is not assigned.
   *
   * @param newTaskList   List of Task records to validate.
   * @param mpAccPELOwner Map of account IDs to PEL Owners.
   */
  private void validateTasks(
    List<Task> newTaskList,
    Map<String, String> mpAccPELOwner
  ) {
    for (Task tsk : newTaskList) {
      if (
        tsk.Status == 'Submitted' &&
        tsk.Subject == 'Welcome Call' &&
        tsk.WhatId != null &&
        !mpAccPELOwner.containsKey(tsk.WhatId)
      ) {
        tsk.addError(
          'You should select PEL Enrollee Owner before submitting the task'
        );
      }
    }
  }
}