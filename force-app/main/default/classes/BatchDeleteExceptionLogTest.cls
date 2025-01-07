/*==================================================================================================================================
Author:         
Company:         
Purpose:        Schedule Class for scheduling the batch class BatchfordeletingExceptionLog
                
History:
[Date]              [Author]            [Description]
==================================================================================================================================
==================================================================================================================================*/
@IsTest
public class BatchDeleteExceptionLogTest {
    @TestSetup static void setup(){

        //Create Exception_Log__c
        Exception_Log__c log = new Exception_Log__c( Message__c = 'Attempt to de-reference a null object');
        insert log;
        Datetime yesterday = Datetime.now().addDays(-61);
        Test.setCreatedDate(log.Id, yesterday);  
    } 
    
    @IsTest static void deleteExceptionLog(){
        
        //GIVEN
       // Datetime date1 = [SELECT Id,CreatedDate FROM Exception_Log__c LIMIT 1].CreatedDate;
        
        //When
        Test.startTest();
        BatchDeleteExceptionLog integratioLogInstance = new BatchDeleteExceptionLog(); 
        Database.executeBatch(integratioLogInstance);
        //Then
        List<Exception_Log__c> logList = [SELECT Id,CreatedDate FROM Exception_Log__c];
        System.assertEquals(1, logList.size(), 'Logs not deleted'); 
        Test.stopTest();      
        
         logList = [SELECT Id,CreatedDate FROM Exception_Log__c];
        //System.assertEquals(0, logList.size(), 'Logs not deleted');
        
    }
    
    @IsTest
    static void getInstanceTest(){
        Test.startTest();
        GenericMetadataProvider.getInstance();
        Test.stopTest();
    } 
    
}