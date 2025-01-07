/**
 * @description Utility class for managing share records associated with Care Program Team Members in Salesforce.
 *              It provides methods for creating, batch processing, and inserting share records efficiently using dynamic SOQL queries and batch processing.
 *              The `createShareRecords` method handles share record creation and error logging, while `recordInsertion` manages batch inserts.
 */
public with sharing class J_TeamShareRecordsHelper {
  /**
   * @description This method creates and inserts share records for the given Care Program Team Member IDs
   *              based on the provided Team Sharing Criteria instance. It dynamically retrieves relevant
   *              fields and objects, processes the data, and enqueues jobs if required for large datasets.
   *
   * @param setCareProgTeamMemIds A Set of IDs representing Care Program Team Members.
   *                              These IDs are used to fetch relevant team member records.
   * @param tscInstanceName The DeveloperName of the Team Sharing Criteria custom metadata instance
   *                        used to determine fields, objects, and where clauses for processing.
   *
   * @throws Exception If any error occurs during processing, it will be logged using the GenericLogger utility.
   */
  public static void createShareRecords(
    set<id> setCareProgTeamMemIds,
    string tscInstanceName
  ) {
    try {
      string careProgram;
      list<sObject> lstsObjects = new List<sObject>();
      Team_Sharing_Criteria__mdt tsc = Team_Sharing_Criteria__mdt.getInstance(
        tscInstanceName
      );

      String fields = 'id,CareProgramId,Role,UserId';
      set<string> stringSetCareProgTeamID = new Set<string>();
      for (Id id : setCareProgTeamMemIds) {
        stringSetCareProgTeamID.add((String) id);
      }
      String conditions =
        'Id in ' + COM_QueryUtility.buildWhereClause(stringSetCareProgTeamID);
      List<CareProgramTeamMember> teamMemberList = (List<CareProgramTeamMember>) COM_QueryUtility.executeQuery(
        'CareProgramTeamMember',
        fields,
        conditions,
        false
      );

            for (CareProgramTeamMember teamMember : teamMemberList) {
                careProgram = teamMember.CareProgramId;
                break;
            }
            list<object> teamObjects = TeamSharing_HelperClass.getSelectedFieldsByDynamicSOQL(
                tsc.Query_Fields__c,
                tsc.Object_Name__c,
                tsc.Where_Clause__c + '= \'' + careProgram + '\'',
                Integer.valueOf(System.Label.J_QueryLimit)
            );

      for (CareProgramTeamMember teamMember : teamMemberList) {
        lstsObjects.addAll(
          TeamSharing_HelperClass.initializeShareObject(
            teamMember,
            teamObjects,
            tsc
          )
        );
      }

      recordInsertion(lstsObjects, teamObjects);
    } catch (Exception ex) {
      GenericLogger.exceptionLog(
        TeamSharing_HelperClass.class.toString(),
        'createShareRecords',
        ex
      );
    }
  }

  private static void recordInsertion(
    list<sObject> lstsObjects,
    list<object> teamObjects
  ) {
    try {
      COM_DatabaseOperationsUtility.insertOperationForBatch(
        lstsObjects,
        false,
        false
      );
    } catch (Exception ex) {
      GenericLogger.exceptionLog(
        J_TeamShareRecordsHelper.class.toString(),
        'recordInsertion',
        ex
      );
    }
  }

  private static void enqueueJob(list<sObject> lstsObjects) {
    try {
      System.enqueueJob(new J_CreateTeamSharingQueueable(lstsObjects));
    } catch (Exception ex) {
      GenericLogger.exceptionLog(
        J_TeamShareRecordsHelper.class.toString(),
        'enqueueJob',
        ex
      );
    }
  }
}