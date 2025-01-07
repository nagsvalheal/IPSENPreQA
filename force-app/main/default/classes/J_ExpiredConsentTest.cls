/**
*   @description    Unit Tests for J_ExpiredConsentBatch and J_ExpiredConsentScheduled
**/
@isTest
private class J_ExpiredConsentTest {

    static final String CITY_MAILING = 'CITY';
    static final String STATE_MAILING = 'Arkansas';
    static final String PATIENT_FIRST_NAME = 'patient_test';
    @TestSetup
    static void makeData() {
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
                LastName = J_TestUtils.PATIENT_LAST_NAME,
                RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
                J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
                PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
                PersonMailingStreet = J_TestUtils.STREET_MAILING,
                PersonBirthdate = Date.today().addYears(-19),
                Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
                Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
                PersonHomePhone = '00099',
            PersonMailingState= STATE_MAILING,
            PersonMailingCity = CITY_MAILING
            
        );
        insert patient;
    }

    @isTest
    static void expiredConsentScheduledTest() {
        Test.startTest();
        Datetime dt = Datetime.now().addMinutes(1);
        String cronExp = '0 ' + dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
        String jobId = System.schedule('J_ExpiredConsentScheduledTest', cronExp, new J_ExpiredConsentScheduled());
        Test.stopTest();
		
        Assert.areNotEqual(null, jobId,'Job Id should not be null');
    }

    @isTest
    static void expiredConsentBatchTest() {
        Account patient =J_TestUtils.queryAccount()[0];

        List<J_Consent__c>consentLst = new List<J_Consent__c>();
        //Create Consent
        J_Consent__c consent = new J_Consent__c(
                J_Patient__c = patient.Id,
                J_ConsentExpirationDate__c = Date.today(),
                J_ConsentStatus__c = J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_EXPIRING,
            Consented_by_Others__c = 'Yes',
            J_Mail__c ='Opt-in' ,J_SMS__c ='Opt-in',J_Email__c ='Opt-in',J_Meetings__c ='Opt-in',J_Phone__c ='Opt-in', J_MarketingMaterial__c ='Opt-in'
        );
        insert consent;
        consent.J_ConsentExpirationDate__c = Date.today();
        update consent;
        consentLst.add(consent);

        Test.startTest();
        J_ExpiredConsentBatch batch = new J_ExpiredConsentBatch();
        Id batchId = Database.executeBatch(batch);
        Assert.areNotEqual(null, batchId, 'The batch ID should not be null.');

        Database.QueryLocator ql = batch.start(null);
        batch.execute(null,consentLst);
        batch.Finish(null);
        Test.stopTest();
        Assert.areNotEqual(null, ql, 'The query locator should not be null.');

        List<J_Consent__c> consents = [
                SELECT Id, J_ConsentStatus__c
                FROM J_Consent__c
        ];

        Assert.areEqual(J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_EXPIRED, consents[0].J_ConsentStatus__c,'The consent status should be expired.');
    }
}