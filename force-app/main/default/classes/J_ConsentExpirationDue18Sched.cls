/**
*   @author         Arkadii Sychov
*   @date           11/7/20
*   @description    The class expires the consent for a patient if the patient is turning 18 within next 12 
*   months and notify CC via task on the date of consent expiration 
**/
public with sharing class J_ConsentExpirationDue18Sched implements Schedulable {
    /**
     * @description    Executes the scheduled job by starting a batch process to manage 
     *                 consent expiration tasks.
     * @param sc       The schedulable context object that contains information about 
     *                 the scheduled job's execution.
     */
    public void execute(SchedulableContext sc) {
        J_ConsentExpirationDue18Batch b = new J_ConsentExpirationDue18Batch(); 
        database.executebatch(b);
    }
}