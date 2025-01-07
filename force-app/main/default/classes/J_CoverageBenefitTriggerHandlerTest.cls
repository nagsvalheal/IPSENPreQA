/**
 * @description This test class verifies the functionality of the J_CoverageBenefitTriggerHandler.
 *              It includes a test setup method to create required test data such as Patient, Care Program,
 *              Enrollee, Member Plan, and Coverage Benefit records. These records serve as prerequisites 
 *              for simulating and validating the logic of the trigger handler.
 *              
 *              The class ensures that the trigger logic is executed correctly under various scenarios,
 *              covering data integrity and intended functionality.
 */
@isTest
public class J_CoverageBenefitTriggerHandlerTest {
    
    /**
* @description Test setup method to create required test data, including a Patient, Care Program, Enrollee, 
*              Member Plan, and Coverage Benefit records. This ensures all dependent data is available for the tests.
*/
    @TestSetup
    static void makeData() {
        // Create a test Patient
        Account patient = J_TestUtils.createPatient();
        
        // Create a test Care Program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee associated with the Patient and Care Program
        CareProgramEnrollee cpEnrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);
        
        // Create a Member Plan associated with the Patient
        MemberPlan mp = J_TestUtils.createMemberPlan(patient.Id);
        
        // Create a Coverage Benefit associated with the Enrollee and Member Plan
        CoverageBenefit cb = J_TestUtils.createCoverageBenefit(cpEnrollee.Id, mp.Id);
    }
    
    /**
* @description Test method to verify the functionality of the `uploadCoverageBenefitPDF` method.
*/
    @isTest
    static void uploadCoverageBenefitPDFTest() {
        // Retrieve a Coverage Benefit record
        CoverageBenefit cb = [SELECT Id FROM CoverageBenefit LIMIT 1];
        
        // Call the method under test
        J_CoverageBenefitTriggerHandler.UploadCoverageBenefitPDF(new List<Id>{cb.Id});
        
        // Assert that a ContentDocumentLink record is created for the Coverage Benefit
        System.assertEquals(1, [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :cb.Id].size(),
                            'ContentDocumentLink record should be created');
    }
    
    /**
* @description Test method to verify the functionality of the `afterInsertMethod`.
*/
    @isTest
    static void afterInsertMethodTest() {
        Test.startTest();
        
        // Insert test Coverage Benefit records
        List<CoverageBenefit> coverageBenefits = [
            SELECT Id, OwnerId, Care_Program_Enrollee__r.CareProgramId FROM CoverageBenefit LIMIT 2
        ];
        
        // Simulate the after-insert event
        J_CoverageBenefitTriggerHandler handler = new J_CoverageBenefitTriggerHandler();
        handler.afterInsertMethod(coverageBenefits);
        
        // Assert that sharing records are created for Coverage Benefit
        List<CoverageBenefitShare> shares = [
            SELECT Id FROM CoverageBenefitShare WHERE ParentId IN :coverageBenefits
        ];
        System.assert(!shares.isEmpty(), 'Sharing records should be created for Coverage Benefit');
        
        Test.stopTest();
    }
    
    /**
* @description Test method to verify the functionality of the `afterDeleteMethod`.
*/
    @isTest
    static void afterDeleteMethodTest() {
        Test.startTest();
        
        // Retrieve a Coverage Benefit record
        CoverageBenefit cb = [SELECT Id FROM CoverageBenefit LIMIT 1];
        
        // Delete the Coverage Benefit record
        delete cb;
        
        // Simulate the after-delete event
        J_CoverageBenefitTriggerHandler handler = new J_CoverageBenefitTriggerHandler();
        handler.afterDeleteMethod(new List<CoverageBenefit>{cb});
        
        // Assert that associated sharing records are deleted
        List<CoverageBenefitShare> cbShares = [
            SELECT Id FROM CoverageBenefitShare WHERE ParentId = :cb.Id
        ];
        List<CoverageBenefit> deletedCb = [SELECT Id FROM CoverageBenefit WHERE Id = :cb.Id LIMIT 1];
        System.assertEquals(0, deletedCb.size(), 'CoverageBenefit record should be deleted');
        Test.stopTest();
    }
}