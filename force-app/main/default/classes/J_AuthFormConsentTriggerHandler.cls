/**
 * @description    This trigger handler class manages the sharing and deletion logic for the 
 *                 `AuthorizationFormConsent` object. It ensures proper sharing records are created 
 *                 after an insert operation and removed after a delete operation. It also restricts 
 *                 unauthorized deletion of `AuthorizationFormConsent` records based on the user's profile.
 **/

public with sharing class J_AuthFormConsentTriggerHandler {
    /**
     * @description Restricts deletion of `AuthorizationFormConsent` records for non-System Administrator profiles.
     * @param authorizationFormConsents List of `AuthorizationFormConsent` records being deleted.
     */
    public void beforeDelete(List<AuthorizationFormConsent> authorizationFormConsents)
    {  
        String sObjectType = 'Profile';
        String fields = 'Name';
        String conditions = 'Id = \'' + UserInfo.getProfileId() + '\'';
        List<Profile> lstProfiles = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
        String userProfile = !lstProfiles.isEmpty() ? lstProfiles[0].Name : null;
        for(AuthorizationFormConsent afc : authorizationFormConsents) {
            if (userProfile != 'System Administrator' )
            {
                afc.addError('You dont have permission to delete this record');
            }
        }
    }
    /**
     * @description Handles post-insert logic for `AuthorizationFormConsent` records.
     * Creates sharing records for the inserted `AuthorizationFormConsent` records based on their Care Program.
     *
     * @param authorizationFormConsents List of `AuthorizationFormConsent` records that were inserted.
     */
    public void afterInsertMethod(List<AuthorizationFormConsent> authorizationFormConsents){
        Set<String> authConsentIds = new Set<String>();
        for (AuthorizationFormConsent authorizationFormConsent : authorizationFormConsents) {
            authConsentIds.add(authorizationFormConsent.Id);
        }

        String conditionIds = '(\'' + String.join(new List<String>(authConsentIds), '\', \'') + '\')';
        String sObjectType = 'AuthorizationFormConsent';
        String fields = 'Id, OwnerId, Care_Program_Enrollee__r.CareProgramId';
        String conditions = 'Id IN ' + conditionIds;

        List<AuthorizationFormConsent> newAuthorizationFormConsents = COM_QueryUtility.executeQuery(
            sObjectType,
            fields,
            conditions,
            true // Assuming true for read-only query
        );
        if(newAuthorizationFormConsents!=null && newAuthorizationFormConsents.size()>0){
            map<string,map<string,string>> mpConsentDetails = new map<string,map<string,string>>();
       		map<string,string> conDetails = new map<string,string>();
            for(AuthorizationFormConsent afconsent:newAuthorizationFormConsents){               
                conDetails = new map<string,string>();
                if(mpConsentDetails.containskey(afconsent.Care_Program_Enrollee__r.CareProgramId)){
                    conDetails=mpConsentDetails.get(afconsent.Care_Program_Enrollee__r.CareProgramId);
                }            
                conDetails.put(afconsent.Id,afconsent.OwnerId);
                mpConsentDetails.put(afconsent.Care_Program_Enrollee__r.CareProgramId,conDetails);
            }
            ShareRecordInsertion_HelperClass.insertShareRecord('AuthorizationFormConsent','AuthorizationFormConsentShare',mpConsentDetails);        
        }        
    }
     /**
     * @description Handles post-delete logic for `AuthorizationFormConsent` records.
     * Deletes sharing records associated with the deleted `AuthorizationFormConsent` records.
     *
     * @param authorizationFormConsents List of `AuthorizationFormConsent` records that were deleted.
     */

    public void afterDeleteMethod(List<AuthorizationFormConsent> authorizationFormConsents){ 
        set<string> lstDeRecords = new set<String>(); 
        for(AuthorizationFormConsent afc:authorizationFormConsents){
            lstDeRecords.add(afc.Id);
        }
        if(lstDeRecords!=null && lstDeRecords.size()>0){
            TeamSharing_HelperClass.deleteSharingRecords('AuthorizationFormConsentShare',lstDeRecords);
        }
    }
}