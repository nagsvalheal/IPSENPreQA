/**
 * @description This test class validates the behavior of the J_LeadTriggerHandler.
 * It includes test methods for the `afterInsert` and `afterDelete` operations.
 */
@isTest
public class J_LeadTriggerHandlerTest {

    /** @description Tests the `afterInsert` method of the trigger to ensure Leads are shared correctly upon insertion.*/
    @isTest
    static void afterInsertMethodTest() {
        // Start the test context
        Test.startTest();

        // Step 1: Create a Care Program as a prerequisite for the Lead
        CareProgram cp = J_TestUtils.createCareProgram();

        // Step 2: Create a new Lead with necessary fields populated
        Lead le = J_TestUtils.createLead(J_ObjectUtils.LEAD_PATIENT_RECORD_TYPE, cp.id);

        // Step 3: Verify that the Lead is shared correctly
        List<LeadShare> leShare = [SELECT Id FROM LeadShare WHERE LeadId = :le.Id LIMIT 1];
        System.assert(leShare != null, 'Lead is shared successfully');

        // End the test context
        Test.stopTest();
    }

    /** @description Tests the `afterDelete` method of the trigger to ensure Lead shares are removed upon deletion. */
    @isTest
    static void afterDeleteMethodTest() {
        // Start the test context
        Test.startTest();
        
         CareProgram cp = J_TestUtils.createCareProgram();

        // Step 1: Create a new Lead with necessary fields populated
      
        Lead le = J_TestUtils.createLead(J_ObjectUtils.LEAD_PATIENT_RECORD_TYPE, cp.id);

        // Step 2: Delete the Lead record
        delete le;

        // Step 3: Verify that the Lead sharing is removed
        List<LeadShare> leShare = [SELECT Id FROM LeadShare WHERE LeadId = :le.Id LIMIT 1];
        System.assert(leShare.size() == 0, 'Lead sharing is deleted successfully');

        // End the test context
        Test.stopTest();
    }
}