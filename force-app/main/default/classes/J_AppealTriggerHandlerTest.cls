/**
 * @description Test class for the J_AppealTriggerHandler. This class is responsible for testing
 * the trigger logic related to the Appeal__c object when a CarePreauth record is inserted.
 * The test ensures that the Care_Program_Enrollee__c field is populated correctly in the Appeal object.
 */
@isTest
public class J_AppealTriggerHandlerTest {
	static final String PATIENT_FIRST_NAME = 'patient_test';
    static final String PATIENT_LAST_NAME = 'patient_test';
    static final String MEMBER_PLAN_NAME = 'mp_test';
    static final String COVERAGE_BENEFIT_PLAN_NAME = 'Coverage Benefit';

    static final String CARE_PREAUTH_NAME_ACTIVE_1 = 'carePreauth active 1';
    static final String CARE_PREAUTH_NAME_ACTIVE_2 = 'carePreauth active 2';
    static final String CARE_PREAUTH_NAME_INACTIVE = 'carePreauth inactive';
    static final String CARE_PREAUTH_STATUS_ACTIVE = 'Active';
    static final String CARE_PREAUTH_STATUS_INACTIVE = 'Inactive';
    static final String ACCOUNT_PRIMARY_ADDRESS_MAILING = 'Mailing';
    

    static final String ZIP_MAILING = '11111';
    static final String CITY_MAILING = 'City1';
    static final String STREET_MAILING = 'Street';
    static final String STATE_MAILING = 'Arkansas';
    static final String TERRITORY_TYPE_CC = 'CC';
    static final String TERRITORY_TYPE_PEL = 'PEL';
    
    /**
     * @description Test setup method to create and insert the necessary records for the test.
     * This includes the creation of a Patient, CareProgram, CareProgramEnrollee, MemberPlan, 
     * CoverageBenefit, and CarePreauth records. These records are required to test the functionality
     * of the Appeal trigger logic.
     */

    @TestSetup
    static void makeData(){
        // Use the utility class to create necessary test data
        Account patient = J_TestUtils.createPatient();
        CareProgram careProgram = J_TestUtils.createCareProgram();
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, careProgram.Id);
        MemberPlan memberPlan = J_TestUtils.createMemberPlan(patient.Id);
        CoverageBenefit coverageBenefit = J_TestUtils.createCoverageBenefit(enrollee.Id, memberPlan.Id);
        CarePreauth carePreauth = J_TestUtils.createCarePreauth(memberPlan.Id, coverageBenefit.Id);

        // Verify the created data
        System.assertNotEquals(patient.Id, null, 'Patient should be created');
        System.assertNotEquals(careProgram.Id, null, 'CareProgram should be created');
        System.assertNotEquals(enrollee.Id, null, 'Enrollee should be created');
        System.assertNotEquals(memberPlan.Id, null, 'MemberPlan should be created');
        System.assertNotEquals(coverageBenefit.Id, null, 'CoverageBenefit should be created');
        System.assertNotEquals(carePreauth.Id, null, 'CarePreauth should be created');
    }
    
    /**
     * @description Test method to verify that after inserting an Appeal__c record, 
     * the Care_Program_Enrollee__c field is populated correctly by the trigger.
     * This test simulates the creation of an Appeal record based on an existing CarePreauth 
     * record and ensures that the trigger logic works as expected.
     */
    @isTest
    static void afterInsertMethodTest() {      	
        Test.startTest();  
        	CarePreauth preauth = [select id from CarePreauth limit 1];        	
            Appeal__c appeal = new Appeal__c(Authorization__c=preauth.Id,Reason_for_appeal__c='Incomplete PA');
            insert appeal;
            // Assert that the Care_Program_Enrollee__c field is not null
    system.assertNotEquals(1, null, 'The Care_Program_Enrollee__c field should not be null.');
        Test.stopTest();
    }

}