/**
* @class J_CareProgramTriggerHandler
* @description Trigger handler class for `CareProgram` records. This class includes logic 
*              to prevent deletion of `CareProgram` records by unauthorized users.
* @visibility public without sharing
*/
public without sharing class J_CareProgramTriggerHandler {
    /**
* Prevents the deletion of `CareProgram` records for non-administrative users.
*
* @param careProgramList List of `CareProgram` records that are being deleted.
*
* @throws DmlException Adds an error to each `CareProgram` record in the list
*         if the user attempting the deletion is not a "System Administrator".
*/
    
    public void beforeDeleteMethod(List<CareProgram> careProgramList) {
        try {
            String sObjectType = 'Profile';
            String fields = 'Id, Name';
            String conditions = 'Id = \'' + UserInfo.getProfileId() + '\'';
            Boolean withUserMode = true;
            
            List<SObject> profiles = COM_QueryUtility.executeQuery(
                sObjectType,
                fields,
                conditions,
                withUserMode
            );
            
            if (profiles.isEmpty()) {
                for (CareProgram cp : careProgramList) {
                    cp.addError('Unable to verify user profile.');
                }
                return;
            }
            
            Profile userProfile = (Profile) profiles[0];
            
            for (CareProgram cp : careProgramList) {
                if (userProfile.Name != 'System Administrator') {
                    cp.addError('You are not allowed to delete the Care Program');
                }
                
            }
        } catch (Exception e) {
            // Log the exception for debugging purposes
            GenericLogger.exceptionLog(e);
        }
    }
}