/**
*   @author         Arkadii Sychov
*   @date           10/18/20
*   @description    The class invokes J_ReConsentScheduled which updates 'Consent Status' field on Consent record to 'Expiring' 
*       and sends a task with Subject: 'Consent Expiring' to CC user assigned to Patients Territory 
*       when there is 40 Days before Consent expiration date
*       IPSC-212
**/
public with sharing class J_ReConsentScheduled implements Schedulable {
    /**
    * @description Executes the scheduled job for the J_ReConsentBatch class.
    * This method is invoked when the Apex scheduler triggers the class execution. 
    * It creates an instance of the J_ReConsentBatch class and submits it as a batch job to process
    * records. The batch updates the 'Consent Status' field on Consent records to 'Expiring' and 
    * creates a task with the subject 'Consent Expiring' for the Care Coordinator (CC) assigned to 
    * the patient's territory. This is executed 40 days before the consent expiration date.
    *
    * @param sc The SchedulableContext instance provided by the system during execution.
    */
    public void execute(SchedulableContext sc) {
        J_ReConsentBatch b = new J_ReConsentBatch(); 
        database.executebatch(b);
    }
}