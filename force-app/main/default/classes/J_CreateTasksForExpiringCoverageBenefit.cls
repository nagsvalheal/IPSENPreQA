/**
 * @description This class handles the creation of Task records when a "Coverage Benefit" with
 *              an active "Insurance Record" and an active "Enrollee" reaches its expiration date.
 * @author Mickram
 * @date 2025-01-05
 */
public with sharing class J_CreateTasksForExpiringCoverageBenefit {

    /**
     * @description Entry point for processing expiring Coverage Benefits.
     * @throws Exception if any error occurs during query execution or record insertion.
     */
    public static void coverageBenefitExpiring() {
        try {
            // Step 1: Fetch filtered Coverage Benefits
            List<CoverageBenefit> expiringCoverageBenefits = getExpiringCoverageBenefits();

            if (expiringCoverageBenefits.isEmpty()) {
                return; // Exit early if no Coverage Benefits are found
            }

            // Step 2: Fetch related Cases and existing Tasks
            Map<Id, Id> enrolleeToCaseMap = getRelatedCases(expiringCoverageBenefits);
            Map<Id, Set<Id>> caseToCoverageBenefitTaskMap = getExistingTasks(enrolleeToCaseMap);

            // Step 3: Prepare Task records to insert
            List<Task> tasksToInsert = prepareTasks(expiringCoverageBenefits, enrolleeToCaseMap, caseToCoverageBenefitTaskMap);

            // Step 4: Insert Tasks
            if (!tasksToInsert.isEmpty()) {
                insertTasks(tasksToInsert);
            }
        } catch (Exception ex) {
            GenericLogger.debugLog('Error in coverageBenefitExpiring: ' + ex.getMessage());
            throw ex;
        }
    }

    private static List<CoverageBenefit> getExpiringCoverageBenefits() {
        String coverageBenefitConditions = 'J_CoverageBenefitStatus__c = \'Active\' AND ' +
        									'MemberPlan.Status = \'Active\' AND ' +
        									'Care_Program_Enrollee__r.Status = \'Active\'';

        List<SObject> coverageBenefitsRaw = COM_QueryUtility.executeQuery(
            'CoverageBenefit',
            'Id, J_BenefitsEndDate__c, Care_Program_Enrollee__c, MemberPlanId, MemberPlan.Status, Care_Program_Enrollee__r.CC_Owner__c, OwnerId',
            coverageBenefitConditions,
            true
        );
        
        // Filter records in Apex based on J_BenefitsEndDate__c
        List<CoverageBenefit> expiringCoverageBenefits = new List<CoverageBenefit>();
        for (SObject record : coverageBenefitsRaw) {
            CoverageBenefit cb = (CoverageBenefit) record;
            if (cb.J_BenefitsEndDate__c != null && cb.J_BenefitsEndDate__c == Date.today()) {
                expiringCoverageBenefits.add(cb);
            }
        }

        return (List<CoverageBenefit>) expiringCoverageBenefits;
    }

    private static Map<Id, Id> getRelatedCases(List<CoverageBenefit> coverageBenefits) {
        Set<Id> enrolleeIds = new Set<Id>();
        for (CoverageBenefit coverageBenefit : coverageBenefits) {
            enrolleeIds.add(coverageBenefit.Care_Program_Enrollee__c);
        }

        List<String> enrolleeIdList = new List<String>();
        for (Id enrolleeId : enrolleeIds) {
            enrolleeIdList.add(String.valueOf(enrolleeId));
        }

        String caseConditions = 'Care_Program_Enrollee__c IN (\'' +
            String.join(enrolleeIdList, '\', \'') +
            '\') AND RecordTypeId = \'' + COM_QueryUtility.retrieveRecordTypeId('Case', 'J_Re_Verification_New_Insurance') + '\'';

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

        List<String> caseIdList = new List<String>();
        for (Id caseId : enrolleeToCaseMap.values()) {
            caseIdList.add(String.valueOf(caseId));
        }

        String whatIdCondition = 'WhatId IN (\'' +
            String.join(caseIdList, '\', \'') +
            '\') AND RecordTypeId = \'' + COM_QueryUtility.retrieveRecordTypeId('Task', 'J_Re_Verification_New_Insurance_Read_Only') + '\'';

        List<SObject> tasksRaw = COM_QueryUtility.executeQuery('Task', 'Id, WhatId, J_CoverageBenefit__c', whatIdCondition, true);

        Map<Id, Set<Id>> caseToCoverageBenefitTaskMap = new Map<Id, Set<Id>>();
        for (Task task : (List<Task>) tasksRaw) {
            if (!caseToCoverageBenefitTaskMap.containsKey(task.WhatId)) {
                caseToCoverageBenefitTaskMap.put(task.WhatId, new Set<Id>());
            }
            caseToCoverageBenefitTaskMap.get(task.WhatId).add(task.J_CoverageBenefit__c);
        }
        return caseToCoverageBenefitTaskMap;
    }

    private static List<Task> prepareTasks(List<CoverageBenefit> coverageBenefits, Map<Id, Id> enrolleeToCaseMap, Map<Id, Set<Id>> caseToCoverageBenefitTaskMap) {
        List<Task> tasksToInsert = new List<Task>();
        Id taskRecordTypeId = COM_QueryUtility.retrieveRecordTypeId('Task', 'J_Re_Verification_New_Insurance_Read_Only');

        for (CoverageBenefit coverageBenefit : coverageBenefits) {
            Id caseId = enrolleeToCaseMap.get(coverageBenefit.Care_Program_Enrollee__c);
            if (caseId != null &&
                (!caseToCoverageBenefitTaskMap.containsKey(caseId) ||
                 !caseToCoverageBenefitTaskMap.get(caseId).contains(coverageBenefit.Id))) {
                tasksToInsert.add(new Task(
                    Subject = 'Benefit reverification',
                    OwnerId = coverageBenefit.OwnerId,
                    ActivityDate = Date.today()+1,
                    WhatId = caseId,
                    Priority = 'Normal',
                    RecordTypeId = taskRecordTypeId,
                    Status = 'Scheduled',
                    J_CoverageBenefit__c = coverageBenefit.Id
                ));
            }
        }
        return tasksToInsert;
    }

    private static void insertTasks(List<Task> tasksToInsert) {
        Database.SaveResult[] results = COM_DatabaseOperationsUtility.insertOperation(
            tasksToInsert,
            'J_CreateTasksForExpiringCoverageBenefit',
            true
        );
        for (Database.SaveResult result : results) {
            if (!result.isSuccess()) {
                GenericLogger.debugLog('Failed to create task: ' + result.getErrors());
            }
        }
    }
}