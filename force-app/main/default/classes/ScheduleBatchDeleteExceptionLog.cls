/**
 * @class          ScheduleBatchDeleteExceptionLog
 * @description    A class that schedules and triggers the batch process for deleting exception log records.
 * @implements     Schedulable Interface
 * @audhour        Harish
 * Date            17/12/2022
 * @example        This class schedules the `BatchDeleteExceptionLog` batch to run as part of the scheduled job.
 */
Public With Sharing class ScheduleBatchDeleteExceptionLog implements Schedulable {
    /**
 * @method         execute
 * @description    Executes the scheduled job to delete exception log records by initiating the batch process.
 * @param          sc The context of the scheduled job provided by the system.
 * @example        This method is triggered when the scheduled job runs, and it calls the 
 *                 `BatchDeleteExceptionLog` batch class to perform the deletion of old exception logs.
 */
    Public void execute(SchedulableContext sc) {
        BatchDeleteExceptionLog batch = new BatchDeleteExceptionLog();
        Database.executeBatch(batch);
    }
}