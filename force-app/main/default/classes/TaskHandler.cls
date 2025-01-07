public with sharing class TaskHandler {
/**
 * @description Retrieves tasks associated with a specific Care Program Enrollee.
 *              Uses the `executeQuery` method to dynamically execute the SOQL query.
 * @param careProgramEnrolleeId The ID of the Care Program Enrollee for which to retrieve tasks.
 * @return List<Task> A list of Task records related to the specified Care Program Enrollee.
 */
    @AuraEnabled(cacheable=true)
    public static List<Task> getTasksForCareProgramEnrollees(Id careProgramEnrolleeId) {
        
        if (careProgramEnrolleeId == null) {
            return new List<Task>();
        }

        String sObjectType = 'Task';
        String fields = 'Id, Subject, OwnerId, Owner.Name, Status, CreatedDate, ActivityDate';
        String conditions = 'WhatId = \'' + String.escapeSingleQuotes(careProgramEnrolleeId) + '\'';
        Boolean withUserMode = true;
    
        
        List<SObject> results = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, withUserMode);
    
      
        List<Task> tasks = new List<Task>();
        for (SObject result : results) {
            tasks.add((Task) result);
        }
    
        return tasks;
    }
    

   /**
 * @description Retrieves all Care Program Enrollees using the `executeQuery` method.
 * @return List<CareProgramEnrollee> A list of all Care Program Enrollee records.
 */
@AuraEnabled(cacheable=true)
public static List<CareProgramEnrollee> getAllCareProgramEnrollees() {
    
    String sObjectType = 'CareProgramEnrollee';
    String fields = 'Id, Name';
    String conditions = ''; 
    Boolean withUserMode = true;

    
    List<SObject> results = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, withUserMode);

   
    List<CareProgramEnrollee> enrollees = new List<CareProgramEnrollee>();
    for (SObject result : results) {
        enrollees.add((CareProgramEnrollee) result);
    }

    return enrollees;
}

    


}