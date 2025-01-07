/**
*   @author         Arkadii Sychov
*   @date           11/7/20
*   @description    The class expires the consent for a patient if the patient is turning 18 within next 12 
*   months and notify CC via task on the date of consent expiration 
**/
public with sharing class J_ConsentExpirationDue18Batch implements Database.Batchable<sObject>{

    /**
     * @description    This method queries all the consents where the patient is turning 18 within the next 12 months 
     *                 (based on the patient's birthdate) and where the consent status is "Active".
     *                 It returns a query locator that is used in the batch process to process the relevant consents.
     * @param bc        The batch context.
     * @return        Database.QueryLocator - A query locator to fetch the consents that match the criteria.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date expirationDate = Date.today().addYears(-17);
        return Database.getQueryLocator(
            'SELECT ID, J_ConsentStatus__c, J_ConsentExpirationDate__c, ' +
            'J_Patient__c, J_Patient__r.PersonContactId, J_Patient__r.J_CCTerritory__r.OwnerId ' +
            'FROM J_Consent__c ' +
            'WHERE J_Patient__r.PersonBirthdate = :expirationDate ' +
            'AND J_ConsentStatus__c = \'' + J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_ACTIVE + '\''
        );
    }

    /**
     * @description    This method processes each batch of consents. For each consent:
     *                 1. It updates the consent status to "Expiring".
     *                 2. It creates a Task to notify the Care Coordinator about the expiring consent.
     * @param bc       The batch context object that provides information about the current batch execution.
     * @param scope    A list of J_Consent__c records (consents) to be processed in the batch.
     */

     public void execute(Database.BatchableContext bc, List<J_Consent__c> scope){
        try{
        setConsentStatusToExpiring(scope);
        createTasks(scope);
        }
        catch(Exception ex){
            GenericLogger.exceptionLog(J_ConsentExpirationDue18Batch.Class.toString(),'execute',ex);
        }
    }    

    /**
     * @description    This method is executed after all batches are processed. 
     *                 It is typically used for post-processing, such as sending notifications 
     *                 or performing cleanup operations.
     * @param bc       The batch context object that provides information about the current batch execution.
     */

    public void finish(Database.BatchableContext bc){
        GenericLogProvider.logBatchExecutionSuccess(
            J_ConsentExpirationDue18Batch.Class.toString(),
            'finish',
            'batch class successfully executed'
        );
    }    

    /**
     * @description Updates the 'Consent Status' field of the provided `J_Consent__c` records to 'Expiring'.
     *              This method ensures that consents nearing expiration are marked appropriately in the system.
     * @param consents The list of `J_Consent__c` records to update.
     */
    public static void setConsentStatusToExpiring(List<J_Consent__c> consents) {
        for (J_Consent__c consent : consents) {
            consent.J_ConsentStatus__c = J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_EXPIRING;
        }
        COM_DatabaseOperationsUtility.updateOperation(consents,J_ConsentExpirationDue18Batch.Class.toString(),true);
    }

    /**
     * @description Creates follow-up tasks for consents nearing expiration. Each task is assigned to the CC user 
     *              associated with the patient’s territory and provides a reminder to take action on the expiring consent.
     * @param consents The list of `J_Consent__c` records for which tasks will be created.
     */
    public static void createTasks(List<J_Consent__c> consents) {
        String taskRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.TASK_RT_CARE_PLAN_TASK,  J_ObjectUtils.TASK_API_NAME);
        List<Task> tasksToInsert = new List<Task>();

        for (J_Consent__c consent : consents) {
            Task t = new Task(
                RecordTypeId = taskRecordTypeId,
                ActivityDate = Date.today().addDays(1),
                WhoId = consent.J_Patient__r.PersonContactId,
                OwnerId = consent.J_Patient__r.J_CCTerritory__r.OwnerId,
                Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
                Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                Subject = J_ObjectUtils.TASK_SUBJECT_PL_CONSENT_EXPIRING,
                WhatId = consent.J_Patient__c
            );
            tasksToInsert.add(t);
        }
        COM_DatabaseOperationsUtility.insertOperation(tasksToInsert,J_ConsentExpirationDue18Batch.Class.toString(),true);
    }
}