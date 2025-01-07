/**
 * @description This class implements the Schedulable interface to run a scheduled batch job 
 * that processes missed shipment tasks for patients.
 * 
 * The `execute` method is called by the Salesforce scheduler and initiates the 
 * batch job `batchToCreateMissedShipmentTaskOnPatient` with a batch size of 200 records.
 * 
 * Usage:
 * This class should be scheduled using Salesforce's UI or programmatically 
 * to run at a specified frequency (e.g., daily, weekly).
 */
public WITH SHARING class ScheduledBatchMissedShipmentTaskPatient implements Schedulable {
    /**
     * @description The execute method is called when the scheduled job runs.
     * 
     * @param sc The context object for the scheduled job.
     */
    public void execute(SchedulableContext sc) { 
        try {
            // Create an instance of the batch class
            BatchToCreateMissedShipmentTaskOnPatient bJob = new BatchToCreateMissedShipmentTaskOnPatient();

            // Use the DML utility for executing the batch job with a batch size of 200 records
            Database.executeBatch(bJob, 200);
        } catch (Exception ex){
            GenericLogger.exceptionLog('ScheduledBatchMissedShipmentTaskPatient','execute',ex);
            throw ex; 
        }
    }
}