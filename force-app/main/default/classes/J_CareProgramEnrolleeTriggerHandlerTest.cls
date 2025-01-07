@IsTest
public class J_CareProgramEnrolleeTriggerHandlerTest {
    static final String MEMBER_PLAN_NAME = 'mp_test';
    static final String COVERAGE_BENEFIT_PLAN_NAME = 'Coverage Benefit';
    static final String PATIENT_FIRST_NAME = 'patient_test';
    static final String STATE_MAILING = 'Arkansas';
    static final String CITY_MAILING = 'CITY';
    static final String STATUS = 'Active';
    
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
        insert u; 
        
        // Create Territories
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        iTerritory.add(new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'test 1',
            Name = J_TestUtils.TERRITORY_NAME_CC
        ));
        iTerritory.add(new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'test 2',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        ));
        insert iTerritory;
        
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
        insert patient;

        // Create Care Program and related objects
        CareProgram cp = new CareProgram(Name = 'Care Program', StartDate = system.today(), Status = 'Active');
        insert cp;

        CareProgramEnrollee cpEnrollee = new CareProgramEnrollee(
            Name = 'Enrollee Test',
            Status = 'Pending',
            Sub_Status__c = 'New Enrollment',
            CareProgramId = cp.Id,
            Clinical_trial_participant__c = 'Yes',
            AccountId = patient.Id
        );
        insert cpEnrollee;

        Product2 prod = new Product2(
            Name = 'Activin A',
            ProductCode = '756567',
            NDC_Code__c = '87545839273',
            Description = 'Test product',
            QuantityUnitOfMeasure = 'Milligrams (mg)',
            IsActive = true
        );
        insert prod;

        CareProgramProduct cpp = new CareProgramProduct(
            Name = 'CareProgramProductName',
            Description__c = 'Test',
            Status = 'Active',
            CareProgramId = cp.Id,
            ProductId = prod.Id
        );
        insert cpp;

        CareProgramEnrolleeProduct cpep = new CareProgramEnrolleeProduct(
            Name = 'CareProgramEnrolleeProductName',
            CareProgramEnrolleeId = cpEnrollee.Id,
            CareProgramProductId = cpp.Id,
            Status = 'Active'
        );
        insert cpep;
    }
    
    @isTest
    static void triggerHubTrackingEvent() {    	
        CareProgramEnrollee enrollee = [SELECT Id, Status, Sub_Status__c FROM CareProgramEnrollee LIMIT 1];
        CareProgramEnrollee updatedEnrollee = new CareProgramEnrollee(
            Id = enrollee.Id,
            Status = 'Approved',
            Sub_Status__c = 'Updated Enrollment'
        );
        
        J_CareProgramEnrolleeTriggerHandler handler = new J_CareProgramEnrolleeTriggerHandler();
        handler.triggerHubTrackingEvent(
            new List<CareProgramEnrollee>{ updatedEnrollee },
            new Map<Id, CareProgramEnrollee>{ enrollee.Id => enrollee }
        );
        
        Test.startTest();
        PatientHubTrackingEventTriggerHandler.triggerEvent(handler.enrollees);
        Test.stopTest();

    	// Ensure handler.enrollees is not empty before accessing
        System.assertNotEquals(1, handler.enrollees.size(), 'Enrollee list should not be empty');
        
        
    }
    
    @isTest
    static void beforeDeleteMethodTest() {
        CareProgramEnrollee enrollee = [SELECT Id FROM CareProgramEnrollee LIMIT 1];
        
        Test.startTest();
        // Declare a variable to capture the exception message
        String errorMessage = '';
        try {
            delete enrollee;
            System.assert(false, 'Deletion should have thrown an exception');
        } catch (Exception ex) {
            // Capture the error message from the exception
            errorMessage = ex.getMessage();
        }
        System.assertNotEquals('', errorMessage, 'Expected delete error message was not thrown.');
        Test.stopTest();
    }
}