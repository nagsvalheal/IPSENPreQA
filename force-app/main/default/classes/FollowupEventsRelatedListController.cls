public class FollowupEventsRelatedListController {
   
   /**
 * @description Fetches Event records for the specified EventID.
 * @param EventID The ID of the parent record associated with the events.
 * @return List of Event records matching the specified EventID.
 */
@AuraEnabled
public static List<Event> fetchEventRecords(String EventID) {
    try{
    // Define the sObject type, fields, and conditions
    String sObjectType = 'Event';
    String fields = 'Id, Subject, Owner_Name__c, StartDateTime, EndDateTime';
    String conditions = 'Parent_Record_Id__c = \'' + EventID + '\'';
    Boolean withUserMode = true;

    // Use the executeQuery method to fetch the records
    List<SObject> results = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, withUserMode);

    // Cast the results to the List<Event> and return
    return (List<Event>) results;
    }
    catch(Exception ex){
        GenericLogger.exceptionLog('FollowupEventsRelatedListController','fetchEventRecords',ex);
        return null;
    }
}

}