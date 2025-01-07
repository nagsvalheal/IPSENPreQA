public with sharing class FollowupTaskRelatedListController {
    /**
     * @description Fetches Task records for the specified TaskID.
     * @param TaskID The ID of the parent record associated with the tasks.
     * @return List of Task records matching the specified TaskID.
     */
    @AuraEnabled
    public static List<Task> fetchTaskRecords(String TaskID) {
        try {
            // Define the sObject type, fields, and conditions
            String sObjectType = 'Task';
            String fields = 'Id, Subject, Status, Owner_Name__c, ActivityDate';
            String conditions = 'Parent_Record_Id__c = \'' + TaskID + '\'';
            Boolean withUserMode = true;

            // Use the executeQuery method to fetch the records
            List<SObject> results = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, withUserMode);

            // Cast the results to the List<Task> and return
            return (List<Task>) results;
        } catch (Exception ex) {
            // Log the exception
            GenericLogger.exceptionLog(
                'FollowupTaskRelatedListController', 
                'fetchTaskRecords', 
                ex
            );

           return null;
           
        }
    }
}