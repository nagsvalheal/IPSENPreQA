/**
 * @description       : Bath class to track the deleted exception log
 * @author            :  Harish
 * @group             : 
 * @last modified on  : 07-22-2022

**/
Public with sharing class BatchDeleteExceptionLog implements Database.Batchable<SObject>{

  /**
 * @description    Fetches records from the Exception_Log__c object that were created before a certain date.
 *                 The date is calculated based on a configuration setting retrieved from the GenericMetadataProvider.
 * @param          bc Database.BatchableContext context of the batch job, passed automatically during batch execution.
 * @return         Database.QueryLocator object containing the list of Exception_Log__c records with the 'CreatedDate' 
 *                 earlier than the calculated date. This QueryLocator is used by Salesforce for batch processing.
 */
  // Start Method
  public Database.QueryLocator start(Database.BatchableContext bc){
      Integer recordOfIntSetting = GenericMetadataProvider.getRecordFromGeneralSetting();
      Date d = System.today().addDays(recordOfIntSetting * -1);
      return Database.getQueryLocator( 'Select Id from Exception_Log__c where CreatedDate <=:d' );               
  }
/**
 * @description    Processes the list of `Exception_Log__c` records provided in the batch's scope. If any records exist, 
 *                 the method deletes them from the database. The method logs the scope for debugging purposes.
 * @param          bc Database.BatchableContext context of the batch job, passed automatically during batch execution.
 * @param          scope List of `Exception_Log__c` records to be processed in this batch execution.
 */
  // Execute Logic
  public void execute(Database.BatchableContext bc, List<Exception_Log__c>scope){
      Genericlogger.debugLog('in exc'+ scope);
      if(scope.size() >0){
        delete scope;
      }
  }
  /**
 * @description    Executes logic at the completion of the batch process. This method is called once all records in the batch 
 *                 have been processed by the `execute` method. It can be used to perform any final operations or send 
 *                 notifications after the batch job has finished.
 * @param          bc Database.BatchableContext context of the batch job, passed automatically during batch execution.
 */
  public void finish(Database.BatchableContext bc){
    GenericLogProvider.logBatchExecutionSuccess(
      BatchDeleteExceptionLog.Class.toString(),
      'finish',
      'batch class successfully executed'
  );
  }
 
}