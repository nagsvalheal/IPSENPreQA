/**
 * @description This is Team helper class used to create and delete Team records.
 */
public with sharing class TeamSharing_HelperClass {
    public static map<string, string> mpTeamMemAccess = getTeamSharingObjects(true, null);
    /**
     * @description This method processes team sharing criteria and enqueues jobs for sharing records.
     *              It filters the active team sharing criteria records based on the provided standard flag.
     * 
     * @param setCareProgTeamMemIds A Set of Ids representing Care Program Team Member records. 
     *                              If null or empty, the method will return early.
     * @param bstandard A Boolean flag to filter team sharing criteria. 
     *                  TRUE for standard criteria, FALSE for custom criteria.
     * 
     * @throws Exception If an error occurs during the job enqueuing process, it will be logged using GenericLogger.
     */
    public static void createTeamSharing(Set<Id> setCareProgTeamMemIds, boolean bstandard) {
        List<Team_Sharing_Criteria__mdt> lstTeamShareCriteria = new List<Team_Sharing_Criteria__mdt>();
        try {
            Boolean bActive = true;
            if (setCareProgTeamMemIds == null || setCareProgTeamMemIds.isEmpty()) {
                return;
            }
            if (setCareProgTeamMemIds != null && setCareProgTeamMemIds.size() > 0) {
                lstTeamShareCriteria = getTeamShareCriteria(bActive,bstandard);
                for (Team_Sharing_Criteria__mdt tsc : lstTeamShareCriteria) {
                    enqueueJobForCreate(setCareProgTeamMemIds, tsc.DeveloperName);
                }
            }
        } catch (Exception ex) {
            GenericLogger.exceptionLog(TeamSharing_HelperClass.class.toString(), 'CreateTeamSharing', ex);
        }
    }
   

    /**
     * @description This method retrieves a map of object names and roles with their corresponding accessibility 
     *              from the Access_to_Team_Sharing_Objects custom metadata. It filters results based on the 
     *              provided boolean flag or a specific object name.
     * 
     * @param bCheck A boolean flag that determines whether to bypass the object name filter.
     *               If TRUE, all team sharing objects are included.
     * @param sObjName The API name of the object to filter the team sharing records. 
     *                 Only records matching this object name will be included if bCheck is FALSE.
     * 
     * @return A map where the key is a concatenation of the Object Name and Role, and the value 
     *         is the corresponding Accessibility defined in the metadata.
     */
    public static map<string, string> getTeamSharingObjects(boolean bCheck, string sObjName) {
        map<string, string> mpTeamMemAccess = new Map<string, string>();
        map<string, Access_to_Team_Sharing_Objects__mdt> mapTeamSharingRecords = Access_to_Team_Sharing_Objects__mdt.getAll();
        for (string accessKey : mapTeamSharingRecords.keyset()) {
            Access_to_Team_Sharing_Objects__mdt teamShare = mapTeamSharingRecords.get(accessKey);
            if (bCheck || sObjName == teamShare.Object_Name__c) {
                mpTeamMemAccess.put(teamShare.Object_Name__c + teamShare.Role__c, teamShare.Accessibility__c);
            }
        }
        return mpTeamMemAccess;
    }

    /**
     * @description This method retrieves a filtered list of `Team_Sharing_Criteria__mdt` records 
     *              based on the provided `bActive` and `bStandard` flags. 
     *              It uses all metadata records and applies filters in a loop.
     * 
     * @param bActive A Boolean flag to filter records where `bActive__c` matches the given value.
     * @param bStandard A Boolean flag to filter records where `bStandard__c` matches the given value.
     * 
     * @return A List of `Team_Sharing_Criteria__mdt` records that match the specified criteria.
     */
    public static list<Team_Sharing_Criteria__mdt> getTeamShareCriteria(Boolean bActive, Boolean bStandard) {
        map<string, Team_Sharing_Criteria__mdt> mapTeamSharingRecords = Team_Sharing_Criteria__mdt.getAll();
        // Filter records based on bActive__c and bStandard__c
        List<Team_Sharing_Criteria__mdt> filteredList = new List<Team_Sharing_Criteria__mdt>();

        for (Team_Sharing_Criteria__mdt record : mapTeamSharingRecords.values()) {
            if (record.bActive__c == bActive && record.bStandard__c == bStandard) {
                filteredList.add(record);
            }
        }

        return filteredList;

    }

     /**
     * @description Executes a dynamic SOQL query to retrieve specified fields from an sObject.
     * @param selectedfields The fields to be queried, separated by commas (e.g., 'Name, Email').
     * @param sobjectName The API name of the sObject to query (e.g., 'Account').
     * @param whereClause The WHERE clause to filter the query (without the starting 'WHERE').
     * @param returnLimit The maximum number of records to return.
     * @return A list of records matching the query, or an empty list if an exception occurs.
     * @throws Exception Logs any exceptions encountered during query execution.
     */
    public static list<object> getSelectedFieldsByDynamicSOQL(
        string selectedfields,
        string sobjectName,
        string whereClause,
        integer returnLimit
    ) {
        string soql = 'select ';
        list<object> result;
        soql += selectedfields;
        soql += ' from ' + sobjectName;

        if (string.isNotBlank(whereClause)) {
            soql += ' where ' + whereClause.removeStart('where');
        }

        soql += ' limit ' + returnLimit;

        try {
            result = Database.query(soql);
        } catch (Exception ex) {
          GenericLogger.exceptionLog(TeamSharing_HelperClass.class.toString(), 'getSelectedFieldsByDynamicSOQL', ex);
        }
        return result;
    }
     /**
     * @description Initializes sharing objects for the provided team member based on the team objects and sharing criteria.
     *              Creates a list of sharing records (`sObject`) for team members who meet the specified criteria.
     * @param teamMember The `CareProgramTeamMember` object representing the team member for whom sharing records are created.
     * @param teamObjects A list of objects representing the records to be shared.
     * @param tsc The `Team_Sharing_Criteria__mdt` object containing the sharing criteria metadata.
     * @return A list of sharing `sObject` records initialized based on the sharing criteria.
     */
    public static list<sObject> initializeShareObject(
        CareProgramTeamMember teamMember,
        list<object> teamObjects,
        Team_Sharing_Criteria__mdt tsc
    ) {
        string recId = '';
        sObject sObj;
        string jsonStr = '';
        string strOwnerId;
        list<sObject> lstsObjects = new List<sObject>();
        Map<String, Object> teamRecord = new Map<String, Object>();
        for (object obj1 : teamObjects) {
            jsonStr = JSON.serialize(obj1);
            teamRecord = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);
            recId = (string) teamRecord.get('Id');
            strOwnerId = (string) teamRecord.get('OwnerId');
            if (
                recId != null &&
                teamMember.UserId != strOwnerId &&
                mpTeamMemAccess.containskey(tsc.Object_Name__c + teamMember.Role)
            ) {
                
                sObj = Schema.getGlobalDescribe().get(tsc.Object_Name_Share__c).newSObject();
                sObj.put('UserOrGroupId', teamMember.UserId);
                sObj.put(tsc.ShareParentId__c, recId);
                sObj.put(tsc.ShareAccessLevel__c, mpTeamMemAccess.get(tsc.Object_Name__c + teamMember.Role));
                sObj.put('RowCause', 'Manual');
                lstsObjects.add(sObj);
            }
        }
        return lstsObjects;
    }

        /**
     * @description Deletes team sharing records based on the provided team member details and sharing criteria.
     *              This method fetches active sharing criteria metadata and enqueues jobs to delete sharing records.
     * @param careProgTeamMemDetails A map where the key is the Care Program ID and the value is the Team Member ID.
     * @param isStandard A boolean flag indicating whether to consider standard sharing criteria.
     */
    public static void deleteTeamSharing(Map<String, String> careProgTeamMemDetails, Boolean isStandard) {
        // Fetch active sharing criteria metadata
        
        Boolean bActive = true;
        List<Team_Sharing_Criteria__mdt> teamShareCriteriaList = new List<Team_Sharing_Criteria__mdt>();
        teamShareCriteriaList = getTeamShareCriteria(bActive,isStandard);

        if (teamShareCriteriaList.isEmpty()) {
            return; // Exit if no criteria found
        }
        
        if (teamShareCriteriaList != null && teamShareCriteriaList.size() > 0) {
                
                for (Team_Sharing_Criteria__mdt tsc : teamShareCriteriaList) {
                    enqueueJob(careProgTeamMemDetails, tsc.DeveloperName);
                }
            }


    }

   
    /**
     * @description Deletes sharing records associated with the specified parent records.
     *              Retrieves the relevant sharing records and performs the delete operation.
     * @param objNameShare The API name of the share object associated with the primary object.
     * @param lstParentRecords A set of parent record IDs whose associated sharing records need to be deleted.
     *                          If the set is null or empty, the method will exit without performing any operation.
     */
    public static void deleteSharingRecords(string objNameShare, set<string> lstParentRecords) {
        list<sObject> lstsDeleteObjects = new List<sObject>();
        
        
        list<object> teamObjects = getSelectedFieldsByDynamicSOQL(
            'Id',
            objNameShare,
            'RowCause=\'Manual\' and ParentId in ' + COM_QueryUtility.buildWhereClause(lstParentRecords),
            100
        );
        lstsDeleteObjects = J_DeleteSharingRecordsHelper.getSharingRecordsToDelete(teamObjects,objNameShare);
        
        if (lstsDeleteObjects != null && lstsDeleteObjects.size() > 0) {
            COM_DatabaseOperationsUtility.deleteOperation(
                lstsDeleteObjects,
                TeamSharing_HelperClass.class.toString(),
                false
            );
            
        }
    }
	@TestVisible
    private static void enqueueJob(Map<String, String> careProgTeamMemDetails, String developerName) {
        try {
            System.enqueueJob(new J_TeamSharingDeletionQueueable(careProgTeamMemDetails, developerName));
        } catch (Exception ex) {
            GenericLogger.exceptionLog(
                TeamSharing_HelperClass.class.toString(),
                'enqueueJob',
                ex
            );
        }
    }
	@TestVisible
    private static void enqueueJobForCreate(Set<Id> setCareProgTeamMemIds, String developerName) {
        try {
            System.enqueueJob(new J_TeamSharingQueueable(setCareProgTeamMemIds, developerName));
        } catch (Exception ex) {
            GenericLogger.exceptionLog(
                TeamSharing_HelperClass.class.toString(),
                'enqueueJob',
                ex
            );
        }
    }
 
}