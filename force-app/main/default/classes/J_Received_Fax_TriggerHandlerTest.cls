/**
 * @description This is a test class for the `J_Received_Fax_TriggerHandler` class.
 *              It validates the functionality of the after insert and delete trigger events for the `Received_Fax__c` object.
 *              It also ensures proper sharing records are created and deleted as expected.
 */
@IsTest
public class J_Received_Fax_TriggerHandlerTest {
    static final String PATIENT_FIRST_NAME = 'patient_test';
    static final String STATE_MAILING = 'Arkansas';
    static final String CITY_MAILING = 'CITY';
    static final String STATUS = 'Active';

    /**
     * @description Creates test data required for testing `J_Received_Fax_TriggerHandler` methods.
     *              Includes creating a test user, territories, a patient account, care program, and enrollee.
     */
    @testSetup
    static void makeData() { 
        // Create test User
        User u = new User(
            Alias = 'jStand',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'AbcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'jTest@jTesting.com'
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{u}, 'J_Received_Fax_TriggerHandlerTest', false);

        // Create Territories
        List<J_Territory__c> lTerritory = new List<J_Territory__c>();

        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'test 1',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        lTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'test 2',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        lTerritory.add(territoryPEL);

        COM_DatabaseOperationsUtility.insertOperation(lTerritory, 'J_Received_Fax_TriggerHandlerTest', false);

        // Create Patient
        Account patient = new Account(
            FirstName = PATIENT_FIRST_NAME,
            LastName = J_TestUtils.PATIENT_LAST_NAME,
            RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonBirthdate = Date.today().addYears(-19),
            Patient_Status__pc = STATUS,
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '00099',
            PersonMailingState = STATE_MAILING,
            PersonMailingCity = CITY_MAILING
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{patient}, 'J_Received_Fax_TriggerHandlerTest', false);

        // Create Care Program
        CareProgram cp = new CareProgram(
            Name = 'Care Program',
            StartDate = System.today(),
            Status = 'Active'
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{cp}, 'J_Received_Fax_TriggerHandlerTest', false);

        // Create Care Program Enrollee
        CareProgramEnrollee cpEnrollee = new CareProgramEnrollee(
            Name = 'Enrollee Test',
            Status = 'Pending',
            Sub_Status__c = 'New Enrollment',
            CareProgramId = cp.Id,
            Clinical_trial_participant__c = 'Yes',
            AccountId = patient.Id
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{cpEnrollee}, 'J_Received_Fax_TriggerHandlerTest', false);
    }

    /**
     * @description Tests the `afterInsertMethod` of the `J_Received_Fax_TriggerHandler` class.
     *              Validates that sharing records are created for `Received_Fax__c` objects.
     */
    @IsTest
    static void afterInsertMethodTest() {
        CareProgramEnrollee enrollee = [SELECT Id FROM CareProgramEnrollee LIMIT 1];

        Test.startTest();
        Received_Fax__c rFax = new Received_Fax__c(
            Care_Program_Enrollee__c = enrollee.Id
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{rFax}, 'J_Received_Fax_TriggerHandlerTest', false);

        List<Received_Fax__Share> rFaxShare = [SELECT Id FROM Received_Fax__Share WHERE ParentId = :rFax.Id LIMIT 1];
        System.assert(rFaxShare != null, 'Share not created');
        System.assertEquals(0, rFaxShare.size(), 'Expected sharing record to be created');
        Test.stopTest();
    }

    /**
     * @description Tests the `afterDeleteMethod` of the `J_Received_Fax_TriggerHandler` class.
     *              Validates that sharing records are deleted for `Received_Fax__c` objects.
     */
    @IsTest
    static void afterDeleteMethodTest() {
        CareProgramEnrollee enrollee = [SELECT Id, CareProgramId FROM CareProgramEnrollee LIMIT 1];

        Test.startTest();
        Received_Fax__c rFax = new Received_Fax__c(
            Care_Program_Enrollee__c = enrollee.Id
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{rFax}, 'J_Received_Fax_TriggerHandlerTest', false);
        COM_DatabaseOperationsUtility.deleteOperation(new List<SObject>{rFax}, 'J_Received_Fax_TriggerHandlerTest', false);

        List<Received_Fax__Share> rFaxShare = [SELECT Id FROM Received_Fax__Share WHERE ParentId = :rFax.Id LIMIT 1];
        System.assert(rFaxShare.size() == 0, 'Share not deleted');
        System.assertEquals(0, rFaxShare.size(), 'Expected sharing record to be deleted.');
        Test.stopTest();
    }
}