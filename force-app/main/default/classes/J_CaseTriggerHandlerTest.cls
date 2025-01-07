/**
 * @description Test class for J_CaseTriggerHandler to validate the behavior and business rules 
 *              related to the Case object, including insert, update, and delete operations.
 */
@isTest
public class J_CaseTriggerHandlerTest {
      // Constants for test data and validation
    private static final String STATUS_NEW = 'New';
    private static final String TREATMENT_STATUS_TREATMENT = 'Treatment';
    private static final String TREATMENT_STATUS_NOT_ON_TREATMENT = 'Not on Treatment';

    static final String PATIENT_FIRST_NAME = 'patient_test';
    static final String CITY_MAILING = 'CITY';
    static final String STATE_MAILING = 'Arkansas';
 /**
     * @description Test setup method to create prerequisite data such as Territories and a Patient Account.
     */
    @TestSetup
    static void makeData() {

        //Create Patient
        Account patient = J_TestUtils.createPatient();
    }
  /**
     * @description Test to ensure that an account cannot have more than one Case record on insert.
     */
    @isTest
    static void accountCantHasTwoCasesInsert() {
        Account patient = J_TestUtils.queryAccount()[0];
        Case case1 = new Case(
            RecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.CASE_RT_CARE_PLANTASK, J_ObjectUtils.CASE_API_NAME),
            AccountId = patient.Id,
            Status = STATUS_NEW,
            J_TreatmentStatus__c = TREATMENT_STATUS_TREATMENT
        );

        insert case1;

        Exception ex = null;

        try {
            Case case2 = new Case(
                RecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.CASE_RT_CARE_PLANTASK, J_ObjectUtils.CASE_API_NAME),
                AccountId = patient.Id,
                Status = STATUS_NEW,
                J_TreatmentStatus__c = TREATMENT_STATUS_TREATMENT
            );
            insert case2;
        } catch (Exception e) {
            ex = e;
        }

        // Assert that an exception was thrown and the message contains the expected text
        System.assertNotEquals(null, ex, 'Expected an exception due to two cases on the same account');
        
    }
 /**
     * @description Test to ensure that an account cannot have more than one Case record on update.
     */
    @isTest
    static void accountCantHasTwoCasesUpdate() {
        Account patient = J_TestUtils.queryAccount()[0];

        Case case2 = new Case(
            RecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.CASE_RT_CARE_PLANTASK, J_ObjectUtils.CASE_API_NAME),
            Status = STATUS_NEW,
            J_TreatmentStatus__c = TREATMENT_STATUS_TREATMENT
        );
        insert case2;

        Exception ex = null;

        try {
            case2.AccountId = patient.Id;
            update case2;
        } catch (Exception e) {
            ex = e;
        }
    }
  /**
     * @description Test to ensure that deleting a Case record raises an exception as per business rules.
     */
    @isTest
    static void beforeDeleteMethodTest() {
        Test.startTest();
        Account patient = J_TestUtils.queryAccount()[0];
        Case case1 = new Case(
            RecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.CASE_RT_CARE_PLANTASK, J_ObjectUtils.CASE_API_NAME),
            AccountId = patient.Id,
            Status = STATUS_NEW,
            J_TreatmentStatus__c = TREATMENT_STATUS_TREATMENT
        );
        insert case1;
        
        try {
            delete case1;
        } catch (Exception ex) {
            // Assert that the exception message contains the expected string
            System.assert(ex.getMessage().contains('You are not allowed to delete the case'), 'The exception message should contain "You are not allowed to delete the case"');
        }

        Test.stopTest();
    }
}