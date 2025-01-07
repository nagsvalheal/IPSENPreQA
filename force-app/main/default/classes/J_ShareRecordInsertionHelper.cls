/**
 * @description
 * `J_ShareRecordInsertionHelper` is a utility class designed to handle the insertion of sharing records for specified objects
 * based on metadata-driven sharing criteria. It dynamically retrieves sharing rules, evaluates team member access levels,
 * and generates sharing records for team members associated with specific care programs.It is designed to work seamlessly in scenarios requiring bulk processing of sharing records across multiple team members
 * and care programs, ensuring efficient and maintainable sharing rule management.
 */

 public with sharing class J_ShareRecordInsertionHelper {
    /**
     * @description Inserts sharing records based on the provided sharing criteria and team member access levels.
     *
     * @param objName The API name of the object for which sharing records are being created.
     * @param objNameShare The API name of the object that represents sharing records.
     * @param sharingRecords A map containing sharing records keyed by CareProgramId with record details.
     */
    public static void insertShareRecord(String objName, String objNameShare, Map<String, Map<String, String>> sharingRecords) {
        List<SObject> shareRecordsToInsert = new List<SObject>();
        Map<String, String> teamMemberAccess = TeamSharing_HelperClass.getTeamSharingObjects(false, objName);

        Team_Sharing_Criteria__mdt criteria = getSharingCriteria(objName);
        if (criteria == null) {
            return;
        }

        List<CareProgramTeamMember> allTeamMembers = getTeamMember(sharingRecords.keySet());
        
        Map<String, List<CareProgramTeamMember>> teamMembersByProgram = groupTeamMembersByProgram(allTeamMembers);
    
        for (String programId : sharingRecords.keySet()) {
            Map<String, String> recordDetails = sharingRecords.get(programId);
    
            if (!teamMembersByProgram.containsKey(programId)) {
                continue;
            }
    
            List<CareProgramTeamMember> programTeamMembers = teamMembersByProgram.get(programId);
    
            for (String recordId : recordDetails.keySet()) {
                for (CareProgramTeamMember teamMember : programTeamMembers) {
                    if (shouldCreateShareRecord(teamMember, recordDetails.get(recordId), teamMemberAccess, objName)) {
                        SObject shareRecord = createShareRecord(
                            objNameShare,
                            criteria,
                            recordId,
                            teamMember.UserId,
                            teamMemberAccess.get(objName + teamMember.Role)
                        );
                        shareRecordsToInsert.add(shareRecord);
                    }
                }
            }
        }
    
        if (!shareRecordsToInsert.isEmpty()) {
            // insert shareRecordsToInsert;
            COM_DatabaseOperationsUtility.insertOperation(
                    shareRecordsToInsert,
                    TeamSharing_HelperClass.class.toString(),
                    false
                );

        }
    }

    private static Team_Sharing_Criteria__mdt getSharingCriteria(String objName) {
        Team_Sharing_Criteria__mdt tmSharing = Team_Sharing_Criteria__mdt.getInstance(objName);

        if (!tmSharing.bActive__c) {
            return null;
        }
        return tmSharing;
    }

    private static List<CareProgramTeamMember> getTeamMember(Set<String> careProgramIds) {
        List<CareProgramTeamMember> allTeamMembers = new List<CareProgramTeamMember>();
        List<String> tmList = new List<String>();
        for (String tm : careProgramIds) {
            tmList.add(tm);
        }
        String objectType = 'CareProgramTeamMember';
        String fields = 'Id, CareProgramId, UserId, Role';
        String tmIds = '(\'' + String.join(new List<String>(tmList), '\', \'') + '\')';
        String conditions = 'CareProgramId IN ' + tmIds;
        // Execute the query dynamically using the helper class
        allTeamMembers = (List<CareProgramTeamMember>) COM_QueryUtility.executeQuery(
            objectType,
            fields,
            conditions,
            false
        );
        return allTeamMembers;
    }
 
    private static Map<String, List<CareProgramTeamMember>> groupTeamMembersByProgram(List<CareProgramTeamMember> teamMembers) {
        Map<String, List<CareProgramTeamMember>> groupedMembers = new Map<String, List<CareProgramTeamMember>>();
    
        for (CareProgramTeamMember member : teamMembers) {
            if (!groupedMembers.containsKey(member.CareProgramId)) {
                groupedMembers.put(member.CareProgramId, new List<CareProgramTeamMember>());
            }
            groupedMembers.get(member.CareProgramId).add(member);
        }
    
        return groupedMembers;
    }
    @TestVisible
    private static boolean shouldCreateShareRecord(
        CareProgramTeamMember teamMember,
        String excludedUserId,
        Map<String, String> teamMemberAccess,
        String objName
    ) {
        return teamMemberAccess.containsKey(objName + teamMember.Role) && teamMember.UserId != excludedUserId;
    }
    @TestVisible
    private static SObject createShareRecord(
        String objNameShare,
        Team_Sharing_Criteria__mdt criteria,
        String parentId,
        String userId,
        String accessLevel
    ) {
        SObject shareRecord = Schema.getGlobalDescribe().get(objNameShare).newSObject();
        shareRecord.put(criteria.ShareParentId__c, parentId);
        shareRecord.put(criteria.ShareAccessLevel__c, accessLevel);
        shareRecord.put('UserOrGroupId', userId);
        shareRecord.put('RowCause', 'Manual');
        return shareRecord;
    }

    
    
}