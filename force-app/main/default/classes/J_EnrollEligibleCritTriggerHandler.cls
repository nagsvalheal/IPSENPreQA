/**
* @class J_EnrollEligibleCritTriggerHandler
* @description Ensures that only users with the 'System Administrator' profile can delete 
*              records of the `EnrollmentEligibilityCriteria` object. Adds an error to prevent 
*              deletion if the user is not authorized.
* @visibility public
*/
public without sharing class J_EnrollEligibleCritTriggerHandler {
    /**
* @description Ensures that only users with the 'System Administrator' profile can delete records 
*              of the CareProgramEligibilityRule object. If the user does not have the required profile, 
*              an error is added to the record to prevent deletion.
*
* @param creteriaList List of CareProgramEligibilityRule records that are being deleted.
*
* @throws DmlException if an error occurs during the deletion process or if the user's profile
*                      does not allow deletion of the records.
*/
    public void beforeDeleteMethod(
        List<EnrollmentEligibilityCriteria> creteriaList
    ) {
        try {
            string sobjectType = 'profile';
            string fields = 'Id, Name';
            String conditions = 'Id = \'' + UserInfo.getProfileId() + '\'';
            Boolean withUserMode = true;
            // Fetch the user's profile using a utility method
            List<SObject> profiles = COM_QueryUtility.executeQuery(
                sObjectType,
                fields,
                conditions,
                withUserMode
            );
            // Check if the profile was retrieved successfully
            if (!profiles.isEmpty()) {
                Profile usrProfile = (Profile) profiles[0];
                for (EnrollmentEligibilityCriteria creteria : creteriaList) {
                    // Restrict deletion for users not in the 'System Administrator' profile
                    if (usrProfile.Name != 'System Administrator') {
                        creteria.addError(
                            'You are not allowed to delete the Care Program Eligibility Rule'
                        );
                    }
                }
            } 
        } catch (Exception e) {
            // Log the exception for debugging purposes
            GenericLogger.exceptionLog(e);
        }
        
    }
}