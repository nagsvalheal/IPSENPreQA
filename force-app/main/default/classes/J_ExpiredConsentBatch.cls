/**
 * @description Batch class to set the status of expired consents to "Expired".
 *              This class processes all consents with an expiration date earlier than or equal to today and 
 *              updates their status if they are currently "Active" or "Expiring".
 */

public with sharing class J_ExpiredConsentBatch implements Database.Batchable<SObject>{

    /**
     * @description The `start` method defines the batch's query to fetch the records that need to be processed.
     * @param bc The instance of the batch context.
     * @return   A Database.QueryLocator object to retrieve records for processing.
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
                'SELECT Id, J_ConsentStatus__c, J_ConsentExpirationDate__c ' +
                        'FROM J_Consent__c ' +
                        'WHERE J_ConsentExpirationDate__c <= TODAY ' +
                        'AND (J_ConsentStatus__c = \'' + J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_ACTIVE + '\' ' +
                        'OR J_ConsentStatus__c = \'' + J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_EXPIRING + '\')'
        );
    }

    /**
     * @description The `execute` method processes a batch of records fetched by the `start` method.
     *              It updates the consent status to "Expired" for the records in the current batch.
     * @param bc    The instance of the batch context.
     * @param scope The list of J_Consent__c records to process in the current batch.
     */
    public void execute(Database.BatchableContext bc, List<J_Consent__c> scope) {
        try{
            setConsentStatusToExpired(scope);
        }
        catch(Exception ex){
            GenericLogger.exceptionLog(J_ExpiredConsentBatch.class.toString(),'execute',ex);
        }
    }

    /**
     * @description The `finish` method executes any logic that needs to run after all batches are processed.
     *              This implementation does not include any post-processing logic.
     * @param bc    The instance of the batch context.
     */
    public void finish(Database.BatchableContext bc) {
        GenericLogProvider.logBatchExecutionSuccess(
            J_ExpiredConsentBatch.Class.toString(),
            'finish',
            'batch class successfully executed'
        );
    }

    private void setConsentStatusToExpired(List<J_Consent__c> consents) {
        for (J_Consent__c consent : consents) {
            consent.J_ConsentStatus__c = J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_EXPIRED;
        }
        COM_DatabaseOperationsUtility.updateOperation(consents, J_ExpiredConsentBatch.Class.toString(), false);
    }
}