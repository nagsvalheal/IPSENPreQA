/**
 * @description Trigger handler for CareProgramEnrollee object to manage tracking events and deletion logic.
 * @author [Your Name]
 * @date [Date]
 */
public with sharing class J_CareProgramEnrolleeTriggerHandler {

    /**
     * @description List of CareProgramEnrollee records to be processed.
     */
    public List<CareProgramEnrollee> enrollees { get; private set; }

    /**
     * @description Constructor to initialize the list of CareProgramEnrollee records.
     */
    public J_CareProgramEnrolleeTriggerHandler() {
        enrollees = new List<CareProgramEnrollee>();
    }

    /**
     * @description Triggers a hub tracking event when there is a change in the CareProgramEnrollee's Status or Sub_Status__c field.
     * @param newList List of new CareProgramEnrollee records (trigger.new).
     * @param oldMap Map of old CareProgramEnrollee records (trigger.oldMap).
     */
    public void triggerHubTrackingEvent(List<CareProgramEnrollee> newList, Map<Id, CareProgramEnrollee> oldMap) {
        List<CareProgramEnrollee> enrollees = new List<CareProgramEnrollee>();
        
        try{

        // Process updated records to identify changes in Status or Sub_Status__c fields
        if (oldMap != null) {
            for (CareProgramEnrollee updatedenrollee : newList) {
                if ((updatedenrollee.Status != oldMap.get(updatedenrollee.Id).Status) || 
                    (updatedenrollee.Sub_Status__c != oldMap.get(updatedenrollee.Id).Sub_Status__c)) {
                    enrollees.add(updatedenrollee);
                }
            }
        } 
        // Add all records in case of insert operations (oldMap is null)
        else {
            enrollees.addAll(newList);
        }

        // Trigger the Patient Hub Tracking Event if there are relevant records
        if (!enrollees.isEmpty()) {
           PatientHubTrackingEventTriggerHandler.triggerEvent(enrollees);
        }
        }catch (DMLException e) {
            GenericLogger.exceptionLog('J_CareProgramEnrolleeTriggerHandler', 'triggerHubTrackingEvent', e);
        }
    }

    /**
     * @description Prevents deletion of CareProgramEnrollee records unless performed by a System Administrator.
     * @param enrolleeList List of CareProgramEnrollee records to be deleted (trigger.old).
     */
    public void beforeDeleteMethod(List<CareProgramEnrollee> enrolleeList) {
        
        try {
            // Define the fields to be selected
            String fields = 'Id, Name';
            
            // Define the conditions for the WHERE clause (filter by current user's ProfileId)
            String conditions = 'Id = \'' + UserInfo.getProfileId() + '\'';
        
            // Call COM_QueryUtility to execute the query
            List<SObject> profileResults = COM_QueryUtility.executeQuery('Profile', fields, conditions, true);
        
            // Check if the profile results are returned and process them
            if (profileResults != null && !profileResults.isEmpty()) {
                String profileName = (String) profileResults[0].get('Name');  // Get the Profile Name
        
                // Prevent deletion for non-System Administrator profiles
                for (CareProgramEnrollee enrollee : enrolleeList) {
                    if (profileName != 'System Administrator') {
                        enrollee.addError('You are not allowed to delete the Care Program Enrollee');
                    }
                }
            }
        }catch (DMLException e) {
            GenericLogger.exceptionLog('J_CareProgramEnrolleeTriggerHandler', 'beforeDeleteMethod', e);
        }
        }

}