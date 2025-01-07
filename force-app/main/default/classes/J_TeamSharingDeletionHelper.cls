/**
 * @description
 * `J_TeamSharingDeletionHelper` is a utility class designed to manage the deletion of team-sharing records
 * dynamically based on metadata-driven criteria. It constructs SOQL queries, processes records, and handles deletions
 * efficiently by performing direct operations for small datasets or enqueuing batch jobs for larger ones.
 * The class ensures compliance with Salesforce limits and provides robust error handling and logging for traceability.
 */

public class J_TeamSharingDeletionHelper {
  /**
   * @description Deletes share records for team members based on the given criteria and team member IDs.
   * This method dynamically constructs and executes a SOQL query to retrieve records that meet the criteria,
   * and deletes them either directly or using a batch process, depending on the record count.
   *
   * @param teamMemberIds A map of team member keys to their respective values in the format "UserId,CareProgramId".
   *                      The keys are custom identifiers, and the values contain the user ID and care program ID.
   * @param criteriaName The API name of the Team_Sharing_Criteria__mdt record, which contains metadata such as
   *                     object name, parent field, and where clause for fetching share records.
   *
   * @throws Exception If any unexpected error occurs during the process, it is logged using the GenericLogger utility.
   */

  public static void deleteShareRecords(
    Map<String, String> teamMemberIds,
    String criteriaName
  ) {
    try {
      if (teamMemberIds == null || teamMemberIds.isEmpty()) {
        return;
      }

      // Fetch the sharing criteria metadata
      Team_Sharing_Criteria__mdt criteria = Team_Sharing_Criteria__mdt.getInstance(
        criteriaName
      );
      String shareObjectName = criteria.Object_Name_Share__c;
      String parentField = criteria.ShareParentId__c;
      String teamUserId = '';
      String teamCPId = '';
      string filerString = '';

      if (criteria == null) {
        return; // Exit if no criteria found
      }

      // Construct dynamic SOQL query to fetch share records

      for (String teamMemKey : teamMemberIds.keySet()) {
        String[] details = teamMemberIds.get(teamMemKey).split(',');

        // UserId
        teamUserId = details[0];
        // CareProgramId
        teamCPId = details[1];
        String condition =
          parentField.replace('Id', '.') +
          criteria.Where_Clause__c +
          ' = \'' +
          teamCPId +
          '\'' +
          ' AND UserOrGroupId = \'' +
          teamUserId +
          '\'' +
          ' AND ' +
          parentField.replace('Id', '.') +
          'OwnerId != \'' +
          teamUserId +
          '\'';
        if (filerString == '') {
          filerString = '(' + condition + ')';
        } else {
          filerString += ' OR (' + condition + ')';
        }
      }

            list<object> teamObjects = TeamSharing_HelperClass.getSelectedFieldsByDynamicSOQL(
                'Id',
                shareObjectName,
                filerString,
                Integer.valueOf(System.Label.J_QueryLimit)
            );

      //This is because we have less data. So we dont get any limit exceptions.
      List<SObject> queriedRecords = getQueriedRecords(
        teamObjects,
        shareObjectName
      );

            if (!queriedRecords.isEmpty()) {
                COM_DatabaseOperationsUtility.deleteOperationForBatch(
                        queriedRecords,
                        false,
                        false
                    );
            }
        } catch (Exception ex) {
            J_ErrorDetailsWrapper errorDetails = new J_ErrorDetailsWrapper(
                'J_TeamSharingDeletionHelper',
                'deleteShareRecords',
                ex
            );
            GenericLogger.logAndThrowError(errorDetails, true);
        }
    }
	@TestVisible
    private static List<SObject> getQueriedRecords(
        list<object> teamObjects,
        String shareObjectName
    ) {
        List<SObject> queriedRecords = new List<SObject>();
        sObject sObj;
        string jsonStr = '';
        string recId = '';
        Map<String, Object> teamRecord = new Map<String, Object>();
        for (object obj : teamObjects) {
            sObj = Schema.getGlobalDescribe().get(shareObjectName).newSObject();
            jsonStr = JSON.serialize(obj);
            teamRecord = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);
            recId = (string) teamRecord.get('Id');
            sObj.put('Id', recId);
            queriedRecords.add(sObj);
        }
        return queriedRecords;
    }

  private static void enqueueJob(
    list<SObject> queriedRecords,
    String objectName
  ) {
    try {
      System.enqueueJob(
        new TeamSharing_DeleteBatch(queriedRecords, objectName)
      );
    } catch (Exception ex) {
      GenericLogger.exceptionLog(
        J_TeamSharingDeletionHelper.class.toString(),
        'enqueueJob',
        ex
      );
    }
  }
}