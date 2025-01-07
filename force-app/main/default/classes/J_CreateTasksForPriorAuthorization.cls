/**
 * @description This class handles the creation of Task records for Prior Authorizations 
 *              that are about to expire within the next 30 days. It ensures no duplicate tasks 
 *              are created for the same Prior Authorization and Case.
 * @author Mickram
 * @date 2025-01-04
 */
public with sharing class J_CreateTasksForPriorAuthorization {

    /**
     * @description Entry point for processing expiring Prior Authorizations.
     * @throws Exception if any error occurs during query execution or record insertion.
     */
    public static void priorAuthorizationExpiring() {
        try {
            // Step 1: Fetch filtered Prior Authorizations
            List<CarePreauth> filteredPriorAuths = getFilteredPriorAuthorizations();

            if (filteredPriorAuths.isEmpty()) {
                return; // Exit early if no Prior Authorizations are found
            }

            // Step 2: Fetch related Cases and existing Tasks
            Map<Id, Id> enrolleeToCaseMap = getRelatedCases(filteredPriorAuths);
            Map<Id, Set<Id>> caseToPriorAuthTaskMap = getExistingTasks(enrolleeToCaseMap);

            // Step 3: Prepare Task records to insert
            List<Task> tasksToInsert = prepareTasks(filteredPriorAuths, enrolleeToCaseMap, caseToPriorAuthTaskMap);

            // Step 4: Insert Tasks
            if (!tasksToInsert.isEmpty()) {
                insertTasks(tasksToInsert);
            }
        } catch (Exception ex) {
            GenericLogger.debugLog('Error in priorAuthorizationExpiring: ' + ex.getMessage());
            throw ex;
        }
    }

    private static List<CarePreauth> getFilteredPriorAuthorizations() {
        String carePreauthConditions = 'Status = \'Active\' AND ' +
            'MemberPlan.Status = \'Active\' AND ' +
            'Care_Program_Enrollee__r.Status = \'Active\' AND ' +
            'J_CoverageBenefit__r.J_CoverageBenefitStatus__c = \'Active\'';

        List<SObject> priorAuthsRaw = COM_QueryUtility.executeQuery(
            'CarePreauth',
            'Id, J_AuthorizationEndDate__c, Care_Program_Enrollee__c, J_CoverageBenefit__c, Care_Program_Enrollee__r.CC_Owner__c',
            carePreauthConditions,
            true
        );

        List<CarePreauth> filteredPriorAuths = new List<CarePreauth>();
        for (CarePreauth priorAuth : (List<CarePreauth>) priorAuthsRaw) {
            if (priorAuth.J_AuthorizationEndDate__c != null &&
                priorAuth.J_AuthorizationEndDate__c <= Date.today().addDays(30)) {
                filteredPriorAuths.add(priorAuth);
            }
        }
        return filteredPriorAuths;
    }

    private static Map<Id, Id> getRelatedCases(List<CarePreauth> priorAuths) {
        Set<Id> enrolleeIds = new Set<Id>();
        for (CarePreauth priorAuth : priorAuths) {
            enrolleeIds.add(priorAuth.Care_Program_Enrollee__c);
        }
    
        // Convert Set<Id> to List<String>
        List<String> enrolleeIdList = new List<String>();
        for (Id enrolleeId : enrolleeIds) {
            enrolleeIdList.add(String.valueOf(enrolleeId));
        }
    
        String caseConditions = 'Care_Program_Enrollee__c IN (\'' +
            String.join(enrolleeIdList, '\', \'') +
            '\') AND RecordTypeId = \'' + COM_QueryUtility.retrieveRecordTypeId('Case', 'J_Prior_Authorization') + '\'';
    
        List<SObject> casesRaw = COM_QueryUtility.executeQuery('Case', 'Id, Care_Program_Enrollee__c', caseConditions, true);
        Map<Id, Id> enrolleeToCaseMap = new Map<Id, Id>();
        for (Case caseRecord : (List<Case>) casesRaw) {
            enrolleeToCaseMap.put(caseRecord.Care_Program_Enrollee__c, caseRecord.Id);
        }
        return enrolleeToCaseMap;
    }

    private static Map<Id, Set<Id>> getExistingTasks(Map<Id, Id> enrolleeToCaseMap) {
        if (enrolleeToCaseMap.isEmpty()) {
            return new Map<Id, Set<Id>>();
        }
    
        // Convert the Set<Id> into List<String>
        List<String> caseIdList = new List<String>();
        for (Id caseId : enrolleeToCaseMap.values()) {
            caseIdList.add(String.valueOf(caseId));
        }
    
        // Now join the List<String> into a query string
        String whatIdCondition = 'WhatId IN (\'' +
            String.join(caseIdList, '\', \'') +
            '\') AND RecordTypeId = \'' + COM_QueryUtility.retrieveRecordTypeId('Task', 'J_Prior_Authorization') + '\'';
    
        List<SObject> tasksRaw = COM_QueryUtility.executeQuery('Task', 'Id, WhatId, Prior_Authorization__c', whatIdCondition, true);
    
        Map<Id, Set<Id>> caseToPriorAuthTaskMap = new Map<Id, Set<Id>>();
        for (Task task : (List<Task>) tasksRaw) {
            if (!caseToPriorAuthTaskMap.containsKey(task.WhatId)) {
                caseToPriorAuthTaskMap.put(task.WhatId, new Set<Id>());
            }
            caseToPriorAuthTaskMap.get(task.WhatId).add(task.Prior_Authorization__c);
        }
        return caseToPriorAuthTaskMap;
    }

    private static List<Task> prepareTasks(List<CarePreauth> priorAuths, Map<Id, Id> enrolleeToCaseMap, Map<Id, Set<Id>> caseToPriorAuthTaskMap) {
        List<Task> tasksToInsert = new List<Task>();
        Id taskRecordTypeId = COM_QueryUtility.retrieveRecordTypeId('Task', 'J_Prior_Authorization');

        for (CarePreauth priorAuth : priorAuths) {
            Id caseId = enrolleeToCaseMap.get(priorAuth.Care_Program_Enrollee__c);
            if (caseId != null &&
                (!caseToPriorAuthTaskMap.containsKey(caseId) ||
                 !caseToPriorAuthTaskMap.get(caseId).contains(priorAuth.Id))) {
                tasksToInsert.add(new Task(
                    Subject = 'Prior Authorization Expiring',
                    OwnerId = priorAuth.Care_Program_Enrollee__r.CC_Owner__c,
                    ActivityDate = Date.today().addDays(2),
                    WhatId = caseId,
                    Priority = 'High',
                    RecordTypeId = taskRecordTypeId,
                    Status = 'Scheduled',
                    Prior_Authorization__c = priorAuth.Id,
                    J_CoverageBenefit__c = priorAuth.J_CoverageBenefit__c
                ));
            }
        }
        return tasksToInsert;
    }

    private static void insertTasks(List<Task> tasksToInsert) {
        Database.SaveResult[] results = COM_DatabaseOperationsUtility.insertOperation(
            tasksToInsert,
            'J_CreateTasksForPriorAuthorization',
            true
        );
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                GenericLogger.debugLog('Failed to create task: ' + result.getErrors());
            }
        }
    }
}