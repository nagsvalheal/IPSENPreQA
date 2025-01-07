/**
 * @description       : Helper class for J_TaskTriggerHandler
 * @author            : Nandhakumar
 * @last modified on  : 17-12-2024
 **/
public with sharing class J_TaskTriggerHelper {
/**
   * @description Filters Task records to get account IDs for validation.
   * @param newTaskList List of new Task records.
   * @return List of account IDs linked to the tasks.
   */
  public static List<String> getRelevantTaskAccountIds(List<Task> newTaskList) {
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
  public static Map<String, String> getAccountPELOwnerMap(
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
   * @param newTaskList   List of Task records to validate.
   * @param mpAccPELOwner Map of account IDs to PEL Owners.
   */
  public static void validateTasks(
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