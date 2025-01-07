/*==================================================================================================================================
Author:         
Company:         
Purpose:        Schedule Class for scheduling the batch class BatchfordeletingExceptionLog
                
History:
[Date]              [Author]            [Description]
==================================================================================================================================
==================================================================================================================================*/
@IsTest
public class ScheduleBatchDeleteExceptionLogTest {
@TestSetup static void setup(){
        
        //List<Integration_Log__c> integrationLogDelete = new List<Integration_Log__c>();
        //Create Exception_Log__c
        Exception_Log__c log = new Exception_Log__c( Message__c = 'Attempt to de-reference a null object');
        insert log;
        Datetime yesterday = Datetime.now().addDays(-61);
        Test.setCreatedDate(log.Id, yesterday);   
    } 
    
    @IsTest static void deleteExceptionLog(){
        
        //GIVEN
        Datetime date1 = [SELECT Id,CreatedDate FROM Exception_Log__c LIMIT 1].CreatedDate;
        
        //When
        Test.startTest();
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute()); 
        String ss = String.valueOf(Datetime.now().second());
        
        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        
        ScheduleBatchDeleteExceptionLog s = new ScheduleBatchDeleteExceptionLog(); 
        String jobID = System.schedule('Job Started At ' + String.valueOf(Datetime.now()), nextFireTime, s);
        Test.stopTest();
        
        //Then
        CronTrigger ct = [SELECT Id, TimesTriggered, NextFireTime
                          FROM CronTrigger WHERE Id = :jobID];
        
        System.assertEquals(jobID, ct.Id , 'Apex class did not scheduled');   
    }
}