/**
 * @description Handler class for Case triggers.
 * This class contains methods for managing Case-related logic in different trigger events.
 */
public with sharing class J_CaseTriggerHandler {
  /**
   * @description Verifies if there are existing cases on the same account as the provided cases.
   * @param caseIdsByCase Map of Case IDs to Case records.
   */
  public void checkOnExistingCaseOnTheSameAccount(Map<Id, Case> caseIdsByCase) {
      
    Map<Id, Case> accountIdsByCase = getAccountIdsByCaseMap(
      caseIdsByCase.values()
    );

    if (!accountIdsByCase.isEmpty()) {
      Map<Id, Case> accountIdsByCaseExisted = getAccountIdsByCaseMapExisted(
        accountIdsByCase.keySet(),
        caseIdsByCase.keySet()
      );
      GenericLogger.debugLog('Existing ids: ' + accountIdsByCaseExisted);
    }
      
  }

  /**
   * @description Creates a map of Account IDs to Case records from a list of Case records.
   * @param cases List of Case records.
   * @return Map of Account IDs to Case records.
   */
  private Map<Id, Case> getAccountIdsByCaseMap(List<Case> cases) {
    Map<Id, Case> accountIdsByCase = new Map<Id, Case>();

    for (Case c : cases) {
      if (String.isNotBlank(c.AccountId)) {
        accountIdsByCase.put(c.AccountId, c);
      }
    }

    return accountIdsByCase;
  }

  /**
   * @description Retrieves existing cases linked to the given account IDs, excluding specific case IDs.
   * @param accountIds Set of Account IDs to search for cases.
   * @param caseIdsToExclude Set of Case IDs to exclude from the results.
   * @return Map of Account IDs to existing Case records.
   */
  private Map<Id, Case> getAccountIdsByCaseMapExisted(
    Set<Id> accountIds,
    Set<Id> caseIdsToExclude
  ) {
      
      
    Map<Id, Case> accountIdsByCaseExisted = new Map<Id, Case>();

    // Ensure the input sets are not null or empty
    if (accountIds == null || accountIds.isEmpty()) {
      return accountIdsByCaseExisted;
    }

    List<String> accountIdsList = new List<String>();
    for (Id accId : accountIds) {
        accountIdsList.add(String.valueOf(accId));
    }

    List<String> caseIdsToExcludeList = new List<String>();
    if (caseIdsToExclude != null && !caseIdsToExclude.isEmpty()) {
        for (Id caseId : caseIdsToExclude) {
            caseIdsToExcludeList.add(String.valueOf(caseId));
        }
    }

    // Build the SOQL fields and conditions
    String sObjectType = 'Case';
    String fields = 'Id, AccountId';
    String conditions =
        'AccountId IN (\'' + String.join(accountIdsList, '\',\'') + '\')';
    if (!caseIdsToExcludeList.isEmpty()) {
        conditions +=
            ' AND Id NOT IN (\'' + String.join(caseIdsToExcludeList, '\',\'') + '\')';
    }

    Boolean withUserMode = true;

    // Execute the query using the executeQuery method
    List<SObject> results = COM_QueryUtility.executeQuery(
      sObjectType,
      fields,
      conditions,
      withUserMode
    );

    // Populate the map with the results
    for (SObject sObj : results) {
      Case c = (Case) sObj;
      accountIdsByCaseExisted.put(c.AccountId, c);
    }

    return accountIdsByCaseExisted;
  }

  /**
   * @description Prevents non-admin users from deleting cases.
   * @param caseList List of Case records being deleted.
   */
  public void beforeDeleteMethod(List<Case> caseList) {
      try{
    String sObjectType = 'Profile';
    String fields = 'Id, Name';
    String conditions = 'Id = \'' + UserInfo.getProfileId() + '\'';
    Boolean withUserMode = true;

    List<SObject> results = COM_QueryUtility.executeQuery(
      sObjectType,
      fields,
      conditions,
      withUserMode
    );

    if (results != null && !results.isEmpty()) {
      Profile usrProfile = (Profile) results[0];

      if (usrProfile.Name != 'System Administrator') {
        for (Case cs : caseList) {
          cs.addError('You are not allowed to delete the case');
        }
      }
    }
          }catch(Exception ex){
        GenericLogger.exceptionLog('FollowupEventsRelatedListController','fetchEventRecords',ex);
       
    }
  }

  /**
   * @description Handles logic after inserting cases, including sharing setup for team collaboration.
   * @param caseList List of Case records that were inserted.
   */
  public void afterInsertMethod(List<Case> caseList) {
      try{
    if (caseList == null || caseList.isEmpty()) {
      return;
    }

    Set<String> lstCaseIds = new Set<String>();
    for (Case cse : caseList) {
      lstCaseIds.add(cse.Id);
    }

    if (lstCaseIds.isEmpty()) {
      return;
    }

    String sObjectType = 'Case';
    String fields = 'Id, OwnerId, Care_Program_Enrollee__r.CareProgramId';
    String conditions =
      'Id IN (\'' +
      String.join(new List<String>(lstCaseIds), '\',\'') +
      '\')';
    Boolean withUserMode = true;

    List<SObject> results = COM_QueryUtility.executeQuery(
      sObjectType,
      fields,
      conditions,
      withUserMode
    );

    if (results != null && !results.isEmpty()) {
      Map<String, Map<String, String>> mpCaseDetails = new Map<String, Map<String, String>>();

      for (SObject sObj : results) {
        Case cse = (Case) sObj;
        String careProgramId = cse.Care_Program_Enrollee__r.CareProgramId;
        Map<String, String> cseDetails = mpCaseDetails.get(careProgramId);
      
          cseDetails = new Map<String, String>();
        

        cseDetails.put(cse.Id, cse.OwnerId);
        mpCaseDetails.put(careProgramId, cseDetails);
      }

      TeamSharing_HelperClass.insertShareRecords(
        'Case',
        'CaseShare',
        mpCaseDetails
      );
    }
          }catch(Exception ex){
        GenericLogger.exceptionLog('FollowupEventsRelatedListController','fetchEventRecords',ex);
       
    }
  }

  /**
   * @description Removes sharing records related to deleted cases.
   * @param caseList List of Case records that were deleted.
   */
  public void afterDeleteMethod(List<Case> caseList) {
    Set<String> lstDeRecords = new Set<String>();
    for (Case cse : caseList) {
      lstDeRecords.add(cse.Id);
    }
    if (lstDeRecords != null && lstDeRecords.size() > 0) {
      TeamSharing_HelperClass.DeleteSharingRecords('CaseShare', lstDeRecords);
    }
  }
}