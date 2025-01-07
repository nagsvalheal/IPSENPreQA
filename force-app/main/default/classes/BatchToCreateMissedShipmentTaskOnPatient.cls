/**
 * @description       : Batch class to create "Missed Shipment" tasks for patients based on shipment and refill data.
 *                      This batch identifies missed shipments and creates follow-up tasks for care coordinators.
 * @author            : Vijay
 * @last modified on  : 25-11-2024
 * @version           : 1.0
 */
public class BatchToCreateMissedShipmentTaskOnPatient implements Database.Batchable<sObject>{
    /**
     * @description Retrieves a QueryLocator for CareProgramEnrollee records to process in the batch.
     * @param bc The batch context parameter passed by the system.
     * @return Database.QueryLocator Query locator for CareProgramEnrollee records.
     */
    public Iterable<SObject> start(Database.BatchableContext bc) {
        try{
            // Use the Query Utility class to fetch data
            String fields = 'Id, Name';
            
            // Define the SObject type
            String sObjectType = 'CareProgramEnrollee';
            
            // Define the condition 
            String conditions = 'Name != null';
        
            // Build the query using the common utility class
            String queryString = 'SELECT ' + fields + ' FROM ' + sObjectType + ' WHERE ' + conditions;
        
            // Execute the query using the utility class
            List<SObject> referrals = COM_QueryUtility.executeComplexQuery(queryString, false);
        
            // Return the query directly as a query locator
            return referrals;
        }catch (Exception ex){
            GenericLogger.exceptionLog('BatchToCreateMissedShipmentTaskOnPatient','start',ex);
                    throw ex;
                }
        }
    /**
     * @description Executes the logic to identify missed shipments and create tasks for care coordinators.
     * @param bc The batch context parameter passed by the system.
     * @param scope The list of CareProgramEnrollee records to process in the current batch.
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
    set<Id> setPatientIds = new set<Id>();
    map<Id, List<J_Order__c>> mapOrdersByPatient = new map<Id, List<J_Order__c>>();
    set<Id> setOrderIds = new set<Id>();
    set<Id> setFinalOrderIdsHasTask = new set<Id>();
    list<Task> lstMissedShipmentTasks = new list<Task>();
    list<CareProgramEnrollee> referralsToProcess = (list<CareProgramEnrollee>) scope;
    Id tskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Read Only Task').getRecordTypeId();

    // Collect Patient Ids
    collectPatientIds(referralsToProcess, setPatientIds);

    // Get orders
    list<J_Order__c> lstOrder = getOrders(setPatientIds);
    if (!lstOrder.isEmpty()) {
        mapOrdersByPatient = organizeOrdersByPatient(lstOrder, setOrderIds);
    }

    // Get existing tasks
    setFinalOrderIdsHasTask = getExistingTaskIds(setOrderIds);

    // Create and add missed shipment tasks
    lstMissedShipmentTasks.addAll(createMissedShipmentTasks(mapOrdersByPatient, setFinalOrderIdsHasTask, tskRecordTypeId));

    // Insert missed shipment tasks
    if (!lstMissedShipmentTasks.isEmpty()) {
        insert lstMissedShipmentTasks;
    }
}

private void collectPatientIds(List<CareProgramEnrollee> referralsToProcess, Set<Id> setPatientIds) {
    for (CareProgramEnrollee ref : referralsToProcess) {
        setPatientIds.add(ref.Id);
    }
}

private list<J_Order__c> getOrders(Set<Id> setPatientIds) {
    return [SELECT Id, Name, Care_Program_Enrollee__c, J_SP_Refill_Date__c, CreatedDate,
            Care_Program_Enrollee__r.Account.OwnerId, J_Order_Ship_Date__c, 
            J_Total_Daily_Dose_in_mg__c, J_Program_Type__c, 
            Care_Program_Enrollee__r.Account.PersonContactId, Care_Program_Enrollee__r.CC_Owner__c
            FROM J_Order__c 
            WHERE Care_Program_Enrollee__c IN :setPatientIds 
            AND J_Order_Ship_Date__c != null 
            AND Care_Program_Enrollee__r.Status != 'Discontinued' 
            AND J_SP_Refill_Date__c != null 
            ORDER BY J_SP_Refill_Date__c DESC];
}

private map<Id, List<J_Order__c>> organizeOrdersByPatient(List<J_Order__c> lstOrder, Set<Id> setOrderIds) {
    map<Id, List<J_Order__c>> mapOrdersByPatient = new map<Id, List<J_Order__c>>();
    for (J_Order__c orderRec : lstOrder) {
        if (!mapOrdersByPatient.containsKey(orderRec.Care_Program_Enrollee__c)) {
            mapOrdersByPatient.put(orderRec.Care_Program_Enrollee__c, new List<J_Order__c>());
        }
        mapOrdersByPatient.get(orderRec.Care_Program_Enrollee__c).add(orderRec);
        setOrderIds.add(orderRec.Id);
    }
    return mapOrdersByPatient;
}

private set<Id> getExistingTaskIds(Set<Id> setOrderIds) {
    set<Id> setFinalOrderIdsHasTask = new set<Id>();
    list<Task> tempTaskList = [SELECT Id, Order_ID__c FROM Task WHERE Order_ID__c IN :setOrderIds];
    for (Task tsk : tempTaskList) {
        setFinalOrderIdsHasTask.add(tsk.Order_ID__c);
    }
    return setFinalOrderIdsHasTask;
}

private List<Task> createMissedShipmentTasks(map<Id, List<J_Order__c>> mapOrdersByPatient, Set<Id> setFinalOrderIdsHasTask, Id tskRecordTypeId) {
    List<Task> missedShipmentTasks = new List<Task>();
    for (Id refId : mapOrdersByPatient.keySet()) {
        List<J_Order__c> orders = mapOrdersByPatient.get(refId);
        for (Integer i = 0; i < orders.size(); i++) {
            J_Order__c order = orders[i];
            if (shouldCreateTask(order, mapOrdersByPatient.get(refId), i, setFinalOrderIdsHasTask)) {
                Task tsk = new Task();
                populateTaskFields(tsk, order, tskRecordTypeId);
                missedShipmentTasks.add(tsk);
            }
        }
    }
    return missedShipmentTasks;
}

private Boolean shouldCreateTask(J_Order__c order, List<J_Order__c> orderList, Integer index, Set<Id> setFinalOrderIdsHasTask) {
    if (order == null || orderList == null || orderList.size() <= 1) {
        return false;
    }

    if (index == 0) {
        Boolean shouldCreateForRefillDate = shouldCreateForRefillDate(order, orderList[1]);
        Boolean shouldCreateForShipDate = shouldCreateForShipDate(order);
        if (shouldCreateForRefillDate || shouldCreateForShipDate) {
            return !setFinalOrderIdsHasTask.contains(order.Id);
        }
    }
    return false;
}

private Boolean shouldCreateForRefillDate(J_Order__c order, J_Order__c nextOrder) {
    return order.J_SP_Refill_Date__c != null && order.J_Order_Ship_Date__c > nextOrder.J_SP_Refill_Date__c &&
           order.J_Order_Ship_Date__c >= nextOrder.J_SP_Refill_Date__c + 7 && order.Care_Program_Enrollee__r.CC_Owner__c != null;
}

private Boolean shouldCreateForShipDate(J_Order__c order) {
    return order.J_SP_Refill_Date__c != null && system.today() > order.J_SP_Refill_Date__c + 7 && order.Care_Program_Enrollee__r.CC_Owner__c != null;
}


private void populateTaskFields(Task tsk, J_Order__c order, Id tskRecordTypeId) {
    tsk.ActivityDate = system.Today() + 1;
    tsk.Subject = 'Missed shipment - SP interaction';
    tsk.WhatId = order.Care_Program_Enrollee__c;
    tsk.OwnerId = order.Care_Program_Enrollee__r.CC_Owner__c;
    tsk.Status = 'Scheduled';
    tsk.Order_Ship_Date__c = order.J_Order_Ship_Date__c;
    tsk.SP_Refill_Date__c = order.J_SP_Refill_Date__c;
    tsk.Total_Daily_Dose__c = order.J_Total_Daily_Dose_in_mg__c;
    tsk.Program_Type__c = order.J_Program_Type__c;
    tsk.Order_ID__c = order.Id;
    tsk.RecordTypeId = tskRecordTypeId;
}
/**
     * @description Executes any final logic after the batch processing is completed.
     * @param bc The batch context parameter passed by the system.
     */
    public void finish(Database.BatchableContext bc){     
        GenericLogger.debugLog('BatchToCreateMissedShipmentTaskOnPatient is Completed');
    }
}