/**
 * @description       : Batch class to track and delete old exception logs based on a configurable retention period.
 *                      This batch processes `Exception_Log__c` records that are older than a specified number of days.
 * @author            : Vijay
 * @last modified on  : 11-25-2024
 * @version           : 1.0
 */
global class BatchDeleteExceptionLog implements Database.Batchable<SObject> {

  /**
   * @description Retrieves a QueryLocator for `Exception_Log__c` records that are older than the configured retention period.
   * @param bc The batch context parameter passed by the system.
   * @return Database.QueryLocator Query locator for the records to be processed.
   */
  global Database.QueryLocator start(Database.BatchableContext bc) {
      Integer recordOfIntSetting = GenericMetadataProvider.getRecordFromGeneralSetting();
      Date d = System.today().addDays(recordOfIntSetting * -1);
      return Database.getQueryLocator('Select Id from Exception_Log__c where CreatedDate <=:d');
  }

  /**
   * @description Deletes the exception log records passed in the batch scope.
   * @param bc The batch context parameter passed by the system.
   * @param scope The list of `Exception_Log__c` records to process.
   */
  global void execute(Database.BatchableContext bc, List<Exception_Log__c> scope) {
      Genericlogger.debugLog('in exc' + scope);
      if (scope.size() > 0) {
          delete scope;
      }
  }

  /**
   * @description Executes logic after the batch processing is completed.
   * @param bc The batch context parameter passed by the system.
   */
  global void finish(Database.BatchableContext bc) {
      // Logic to be Executed at finish
  }
}