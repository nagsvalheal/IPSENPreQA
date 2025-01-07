/**
*   @author         Arkadii Sychov
*   @date           11/7/20
*   @description    IPSC-213. Unit Tests for J_ConsentExpirationDue18Sched and J_ConsentExpirationDue18Batch
**/
@isTest
private class J_ConsentExpirationDue18Test {
    static final String PATIENT_FIRST_NAME = 'patient_test';
    static final String CAREGIVER_FIRST_NAME = 'patient_testt';
     static final String STATE_MAILING = 'Arkansas';
    static final String CITY_MAILING = 'CITY';
    @TestSetup
    static void makeData(){
        //Create Territory
        List<J_Territory__c> territories = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'test 1',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        territories.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'test 2',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        territories.add(territoryPEL);

        insert territories;

        //Create Patient
        Account patient = new Account(
           FirstName	 = PATIENT_FIRST_NAME,
            LastName        = J_TestUtils.PATIENT_LAST_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonBirthdate = Date.today().addYears(-17),
            PersonMailingState= STATE_MAILING,
            PersonMailingCity = CITY_MAILING,
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE, 
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '00099'
        );
        insert patient;
    }

    @isTest
    static void scheduledTest() {
        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String cronExp = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = System.schedule('J_ConsentExpirationDue18SchedTest', cronExp, new J_ConsentExpirationDue18Sched() );   
        Test.stopTest();
        Assert.areNotEqual(null, jobId, 'The job ID should not be null.');
    }

    @isTest
    static void batchTest() {
        Account patient = J_TestUtils.queryAccount()[0];

        //Create Caregiver
        Account caregiver = new Account(
              FirstName	 = CAREGIVER_FIRST_NAME,
            LastName        = J_TestUtils.PATIENT_LAST_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_CAREGIVER_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonBirthdate = Date.today().addYears(-40),
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE, 
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '00099',
            
            J_LegalGuardian__c = true
        );
        insert caregiver;

        //Create Consent
        J_Consent__c consent = new J_Consent__c(
            J_Patient__c = patient.Id,
            J_Caregiver__c = caregiver.Id,
            Consented_by_Others__c='Yes',
            J_EnrollmentFormAttached__c = true, //Set to true when Active Consent
            J_ConsentStatus__c = J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_ACTIVE,
            J_Mail__c ='Opt-in' ,J_SMS__c ='Opt-in',J_Email__c ='Opt-in',J_Meetings__c ='Opt-in',J_Phone__c ='Opt-in', J_MarketingMaterial__c ='Opt-in'
        );
        insert consent;
        
        Test.startTest();
            J_ConsentExpirationDue18Batch batch = new J_ConsentExpirationDue18Batch();
            Id batchId = Database.executeBatch(batch);
        Test.stopTest();

        Assert.areNotEqual(null, batchId, 'The batch ID should not be null.');

        List<J_Consent__c> consents = [
            SELECT Id, J_ConsentStatus__c
            FROM J_Consent__c
        ];

        Assert.areEqual(J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_EXPIRING, consents[0].J_ConsentStatus__c,'Consent status should be expiring');

        List<Task> tasks = [
            SELECT Id, Subject
            FROM Task
        ];
        Assert.areEqual(true, tasks.isEmpty(),'Task should be empty');
    }

}