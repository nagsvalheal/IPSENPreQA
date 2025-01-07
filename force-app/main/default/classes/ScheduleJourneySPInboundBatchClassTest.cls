@isTest
public class ScheduleJourneySPInboundBatchClassTest {
    
	@isTest
    static void scheduleInboundTest(){
        Test.StartTest();
		ScheduleJourneySPInboundBatchClass testsche = new ScheduleJourneySPInboundBatchClass();
		String sch = '0 0 23 * * ?';
		Id jobId = system.schedule('Test status Check', sch, testsche );
		Test.stopTest();

		CronTrigger ct = [SELECT Id, CronExpression, State, NextFireTime 
                           FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('WAITING', ct.State, 'The job should be in WAITING state.');
    }
}