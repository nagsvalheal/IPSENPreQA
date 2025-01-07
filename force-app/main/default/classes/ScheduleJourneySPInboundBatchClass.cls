/**
 * @description This class is a schedulable wrapper for executing the JourneySPInboundBatchClass. 
 *              It allows scheduling the batch process to run at specified times.
 * @author Vijay
 * @date 26-11-2024
 */
public with sharing class ScheduleJourneySPInboundBatchClass implements Schedulable {
    
   /**
    * @description Executes the schedulable job by initializing and running the JourneySPInboundBatchClass. 
    *              This method is invoked by the Salesforce scheduler.
    * @param ctx The context of the scheduled job, provided by the Schedulable interface.
    */
   public void execute(SchedulableContext ctx) {
    try{
       JourneySPInboundBatchClass batch = new JourneySPInboundBatchClass();
       Database.executebatch(batch);
   }catch(Exception ex){
    GenericLogger.exceptionLog('ScheduleJourneySPInboundBatchClass', 'execute', ex);

   }
 }
}