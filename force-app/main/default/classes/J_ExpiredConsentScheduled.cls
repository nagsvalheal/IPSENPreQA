/**
 * @description Schedulable class that runs the J_ExpiredConsentBatch to update consent statuses.
 *              This class is designed to be scheduled to run at specific intervals to ensure 
 *              that expired consents are updated automatically.
 */
public with sharing class J_ExpiredConsentScheduled implements Schedulable {

    /**
     * @description Executes the batch job `J_ExpiredConsentBatch` to process expired consents.
     * @param sc    The context of the scheduled job.
     *              This parameter provides the job's ID and other contextual information.
     */
    public void execute(SchedulableContext sc) {
        J_ExpiredConsentBatch batch = new J_ExpiredConsentBatch();
        Database.executeBatch(batch);
    }
}