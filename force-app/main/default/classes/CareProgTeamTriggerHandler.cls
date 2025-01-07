/**
 * @author         None
 * @date           25/11/2024
 * @description    This class handles the trigger logic for CareProgramTeamMember objects.
 *                 It includes methods for the before and after insert, update, and delete operations
 *                 for managing CareProgramTeamMember records, including role updates and sharing logic.
 * @invocableMethod This class is invoked by the trigger for CareProgramTeamMember objects.
 */
public without sharing class CareProgTeamTriggerHandler {

    /**
     * @description This method handles logic before a CareProgramTeamMember record is deleted.
     *              It checks the profile of the current user and prevents deletion unless the user is a System Administrator.
     * @param teamMemberList List of CareProgramTeamMember records being deleted.
     */
	public void beforeDeleteMethod(List<CareProgramTeamMember> teamMemberList) {  
        // Define the fields and conditions for querying the Profile
        String fields = 'Id, Name';
        String conditions = 'Id = \'' + UserInfo.getProfileId() + '\'';
        
        // Call the executeQuery method to fetch the Profile
        List<SObject> profileResults = COM_QueryUtility.executeQuery('Profile', fields, conditions, true);
    
        // If we have results, get the profile name
        if (profileResults != null && !profileResults.isEmpty()) {
            String profileName = (String)profileResults[0].get('Name'); // Get the Profile Name
    
            // Iterate over the team members to check and add errors if needed
            for (CareProgramTeamMember teamMem : teamMemberList) {
                if (profileName != 'System Administrator') {
                    teamMem.addError('You are not allowed to delete the Care Program Team Member');
                }            
            }
        } 
    }
    
    /**
     * @description This method handles logic before inserting CareProgramTeamMember records.
     *              It calls the UpdateRole method to update the roles of team members.
     * @param teamMemberList List of CareProgramTeamMember records being inserted.
     */
    public void beforeInsertMethod(List<CareProgramTeamMember> teamMemberList){
        UpdateRole(teamMemberList, null);
    }
    
    /**
     * @description This method handles logic before updating CareProgramTeamMember records.
     *              It calls the UpdateRole method to update the roles of team members based on the old values.
     * @param teamMemberList List of CareProgramTeamMember records being updated.
     * @param mpOldTeamMember Map of the old CareProgramTeamMember records.
     */
    public void beforeUpdateMethod(List<CareProgramTeamMember> teamMemberList, Map<id,CareProgramTeamMember> mpOldTeamMember){
        UpdateRole(teamMemberList, mpOldTeamMember);
    }
    
    /**
     * @description This method handles logic after CareProgramTeamMember records are inserted.
     *              It creates and deletes team sharing based on the CareProgramTeamMember IDs.
     * @param teamMemberList List of CareProgramTeamMember records that were inserted.
     */
    public void afterInsertMethod(List<CareProgramTeamMember> teamMemberList){
        try{
        Set<Id> lstCareProgTeamMemIds = new Set<Id>();
        for(CareProgramTeamMember cptm :teamMemberList){
            lstCareProgTeamMemIds.add(cptm.Id);
        }        
        TeamSharing_HelperClass.createTeamSharing(lstCareProgTeamMemIds,true);  
        TeamSharing_HelperClass.createTeamSharing(lstCareProgTeamMemIds,false);
    }
    catch (DMLException e) {
            GenericLogger.exceptionLog('CareProgTeamTriggerHandler', 'afterInsertMethod', e);
        }
    }
    
    /**
     * @description This method handles logic after CareProgramTeamMember records are updated.
     *              It deletes old team sharing records and creates new team sharing records based on the updated IDs.
     * @param teamMemberList List of CareProgramTeamMember records that were updated.
     * @param oldteamMemberList List of old CareProgramTeamMember records before the update.
     */
    public void afterUpdateMethod(List<CareProgramTeamMember> teamMemberList, List<CareProgramTeamMember> oldteamMemberList){
        Set<Id> lstCareProgTeamMemIds = new Set<Id>();
        try{
        map<string,string> mpCareProgramTemDetails= new map<string,string>();  
        for(CareProgramTeamMember cptm :teamMemberList){
            lstCareProgTeamMemIds.add(cptm.Id);
            mpCareProgramTemDetails.put(cptm.Id,cptm.UserId+','+cptm.CareProgramId);
        }
        TeamSharing_HelperClass.deleteTeamSharing(mpCareProgramTemDetails,true);
        TeamSharing_HelperClass.deleteTeamSharing(mpCareProgramTemDetails,false);
        TeamSharing_HelperClass.createTeamSharing(lstCareProgTeamMemIds,true);  
        TeamSharing_HelperClass.createTeamSharing(lstCareProgTeamMemIds,false);   
        }
        catch (DMLException e) {
            GenericLogger.exceptionLog('CareProgTeamTriggerHandler', 'afterUpdateMethod', e);
        }
    }
    
    /**
     * @description This method handles logic after CareProgramTeamMember records are deleted.
     *              It deletes team sharing based on the CareProgramTeamMember IDs.
     * @param teamMemberList List of CareProgramTeamMember records being deleted.
     */
    public void afterdeleteMethod(List<CareProgramTeamMember> teamMemberList){
        map<string,string> mpCareProgramTemDetails= new map<string,string>();        
        for(CareProgramTeamMember cptm :teamMemberList){
            mpCareProgramTemDetails.put(cptm.Id,cptm.UserId+','+cptm.CareProgramId);
        }
        TeamSharing_HelperClass.deleteTeamSharing(mpCareProgramTemDetails,true);
        TeamSharing_HelperClass.deleteTeamSharing(mpCareProgramTemDetails,false);
    }
    
    /**
     * @description This method updates the role of the CareProgramTeamMember based on the user roles.
     *              It checks whether a user's role has changed and updates the role accordingly.
     * @param teamMemberList List of CareProgramTeamMember records to update.
     * @param mpOldTeamMember Map of old CareProgramTeamMember records before the update.
     */
    public void updateRole(List<CareProgramTeamMember> teamMemberList, Map<id, CareProgramTeamMember> mpOldTeamMember){
        Set<String> teamMembersToCheck = getUsersToCheck(teamMemberList, mpOldTeamMember);
        Map<String, String> userRoles = getUserRoles(teamMembersToCheck);
        assignRolesToTeamMembers(teamMemberList, userRoles);
    }
    
    private Set<String> getUsersToCheck(List<CareProgramTeamMember> teamMemberList, Map<id, CareProgramTeamMember> mpOldTeamMember) {
        Set<String> users = new Set<String>();
        for (CareProgramTeamMember teamMem : teamMemberList) {
            if (mpOldTeamMember == null || mpOldTeamMember.get(teamMem.Id).UserId != teamMem.UserId) {
                users.add(teamMem.UserId);
            }
        }
        return users;
    }
    
    private Map<String, String> getUserRoles(Set<String> userIds) {
        Map<String, String> userRoles = new Map<String, String>();
    	
        String conditionIds = '(\'' + String.join(new List<String>(userIds), '\', \'') + '\')';
        // Check if the userIds set is not empty
        if (!userIds.isEmpty()) {
            // Define the fields to be retrieved
            String fields = 'Id, UserRole.Name';
    
            // Build the conditions for the WHERE clause dynamically based on the userIds set
            String conditions = 'Id IN' +conditionIds;
    
            // Call the executeQuery method to fetch the user roles
            List<User> userResults = COM_QueryUtility.executeQuery('User', fields, conditions, true);
    
            // Process the results and populate the userRoles map
            for (User usr : userResults) {
                userRoles.put(usr.Id, usr.UserRole.Name); // Add to map
            }
        }
    
        return userRoles;
    }
    
    private void assignRolesToTeamMembers(List<CareProgramTeamMember> teamMemberList, Map<String, String> userRoles) {
        for (CareProgramTeamMember teamMem : teamMemberList) {
            if (userRoles.containsKey(teamMem.UserId)) {
                teamMem.Role = userRoles.get(teamMem.UserId);
            }
        }
    }
    
    
}