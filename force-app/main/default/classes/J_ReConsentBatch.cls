/**
*   @author         Arkadii Sychov
*   @date           10/18/20
*   @description    The class updates 'Consent Status' field on Consent record to 'Expiring'
*       and sends a task with Subject: 'Consent Expiring' to CC user assigned to Patients Territory 
*       when there is 40 Days before Consent expiration date
*       IPSC-212
**/
public with sharing class J_ReConsentBatch implements Database.Batchable<sObject> {

    /**
     * @description Retrieves a list of `J_Consent__c` records that are active and have 
     *              an expiration date between today and the next 40 days.
     * @param bc    The batch context instance.
     * @return      A Database.QueryLocator object for the batchable records.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date expirationStartDate = Date.today();
        Date expirationEndDate = Date.today().addDays(40);
        return Database.getQueryLocator(
            'SELECT ID, J_ConsentStatus__c, J_ConsentExpirationDate__c, ' +
            'J_Patient__c, J_Patient__r.PersonContactId, J_Patient__r.J_CCTerritory__r.OwnerId ' +
            'FROM J_Consent__c ' +
            'WHERE J_ConsentExpirationDate__c > :expirationStartDate ' +
            'AND J_ConsentExpirationDate__c <= :expirationEndDate ' +
            'AND J_ConsentStatus__c = \'' + J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_ACTIVE + '\''
        );
    }

    /**
     * @description Processes each batch of `J_Consent__c` records. It updates the consent status 
     *              to 'Expiring' and creates tasks for the assigned CC users.
     * @param bc    The batch context instance.
     * @param scope The list of `J_Consent__c` records to process in the current batch.
     */

    public void execute(Database.BatchableContext bc, List<J_Consent__c> scope){
        try{
        J_ConsentExpirationDue18Batch.setConsentStatusToExpiring(scope);
        J_ConsentExpirationDue18Batch.createTasks(scope);
        }
        catch(Exception ex){
            GenericLogger.exceptionLog(J_ConsentExpirationDue18Batch.Class.toString(),'execute',ex);
        }
    }    

    /**
     * @description This method executes after all batchable records have been processed.
     *              Currently, it does not include any post-processing logic.
     * @param bc    The batch context instance.
     */
    public void finish(Database.BatchableContext bc){
        GenericLogProvider.logBatchExecutionSuccess(
            J_ConsentExpirationDue18Batch.Class.toString(),
            'finish',
            'batch class successfully executed'
        );
    }

}