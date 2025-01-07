@isTest
public class SchBatchMissedShipmentTaskPatientTest {
    
    @isTest public static void testschedule() {
        // Create an instance of the scheduled batch class
        scheduledBatchMissedShipmentTaskPatient sh1 = new scheduledBatchMissedShipmentTaskPatient();
        
        // Schedule the batch job with the given cron expression
        String sch = '0 0 23 * * ?';
        system.schedule('CreateMissedShipmentTaskForPatient', sch, sh1);
        
        // Use the query utility to fetch the scheduled job's state
        String fields = 'Id, CronExpression, State';
        String conditions = 'CronJobDetail.Name = \'CreateMissedShipmentTaskForPatient\'';
        CronTrigger job = (CronTrigger) COM_QueryUtility.executeQuery('CronTrigger', fields, conditions, true).get(0);
        
        // Verify the job state and cron expression
        System.assertEquals('0 0 23 * * ?', job.CronExpression, 'The cron expression should match the scheduled job.');
    }
}