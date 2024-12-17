/*==================================================================================================================================
Author:         
Company:         
Purpose:        Schedule Class for scheduling the batch class BatchfordeletingExceptionLog
                
History:
[Date]              [Author]            [Description]
==================================================================================================================================
==================================================================================================================================*/
global class ScheduleBatchDeleteExceptionLog implements Schedulable {
    global void execute(SchedulableContext SC) {
        BatchDeleteExceptionLog batch = new BatchDeleteExceptionLog();
        Database.executeBatch(batch);
    }
}