@isTest
private class OT_consentTriggerTest {
    static final String STATE_MAILING = 'Arkansas';
    @TestSetup
    static void makeData(){
        //Create Patient
        Account patient = new Account(
            FirstName        = 'Fred',
            LastName        = 'Flintstone',
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = '92656',
            PersonMailingStreet = '123 Test St',
            PersonMailingCity = 'Aliso Viejo',
            PersonMailingState= STATE_MAILING,
            PersonBirthdate = Date.today().addYears(-45),
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '123456789',
			PersonEmail = 'test@test.com'
        );
        insert patient;

        //Create Patient
        patient = new Account(
            FirstName        = 'Barney',
            LastName        = 'Rubble',
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = '92673',
            PersonMailingStreet = '456 Test St',
            PersonMailingCity = 'San Clemente',
            PersonMailingState= STATE_MAILING,
            PersonBirthdate = Date.today().addYears(-16),
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '123456789',
			PersonEmail = 'test2@test.com'
        );
        insert patient;

        //Create Caregiver
        Account caregiver = new Account(
            FirstName        = 'Betty',
            LastName        = 'Rubble',
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_CAREGIVER_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = '92673',
            PersonMailingStreet = '456 Test St',
            PersonMailingCity = 'San Clemente',
            PersonMailingState= STATE_MAILING,
            PersonBirthdate = Date.today().addYears(-41),
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '123456789',
			J_LegalGuardian__c = true
        );
        insert caregiver;
    }
    
    @isTest static void testJ_ConsentActiveTrigger() {
        Account patient = J_TestUtils.queryAccount()[0];

        Test.startTest();
        //Create Consent
        J_Consent__c consent = new J_Consent__c(
            J_Patient__c = patient.Id,
			J_ConsentEffectiveDate__c = Date.today(),
            J_ConsentExpirationDate__c = Date.today().addDays(40),
            J_EnrollmentFormAttached__c = true, //Set to true when Active Consent
            J_ConsentStatus__c = J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_ACTIVE,
			J_TypeOfConsent__c = 'Patient Authorization',
			J_Mail__c = 'Opt-in',
			J_Email__c = 'Opt-in',
			J_Phone__c = 'Opt-in',
			J_SMS__c = 'Opt-in',
			J_Meetings__c = 'Opt-in',
			J_MarketingMaterial__c = 'Opt-in',
            
            Consented_by_Others__c='No'
        );
        Exception ex;
        try {
			insert consent;
            consent.J_ConsentStatus__c = J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_EXPIRED;
			/*consent.J_Mail__c = 'Opt-out';
			consent.J_Email__c = 'Opt-out';
			consent.J_Phone__c = 'Opt-out';
			consent.J_SMS__c = 'Opt-out';
			consent.J_Meetings__c = 'Opt-out';
			consent.J_MarketingMaterial__c = 'Opt-out';
			consent.J_Mail__c = 'Opt-out';*/
			update consent;
        } catch (OT_Error_Exception e) {
            ex = e;
        }
        Test.stopTest();

		// Validate the results
        System.assertEquals(null, ex);
    }

    @isTest static void testJ_ConsentExpiredTrigger() {
        Account patient = J_TestUtils.queryAccount()[0];

        Test.startTest();
        //Create Consent
        J_Consent__c consent = new J_Consent__c(
            J_Patient__c = patient.Id,
			J_ConsentEffectiveDate__c = Date.today().addDays(-365),
            J_ConsentExpirationDate__c = Date.today().addDays(-1),
            J_ConsentStatus__c = J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_EXPIRED,
			J_TypeOfConsent__c = 'Patient Authorization',
			J_Mail__c = 'Opt-in',
			J_Email__c = 'Opt-in',
			J_Phone__c = 'Opt-in',
			J_SMS__c = 'Opt-in',
			J_Meetings__c = 'Opt-in',
			J_MarketingMaterial__c = 'Opt-in',
            Consented_by_Others__c='No'
        );
        
        
        Exception ex;
        try {
			insert consent;
            consent.J_ConsentStatus__c = 'In Progress';
			update consent;
        } catch (OT_Error_Exception e) {
            ex = e;
        }
        Test.stopTest();

		// Validate the results
        System.assertEquals(null, ex);
    }

    @isTest static void testJ_ConsentMinorTrigger() {
        Account patient = J_TestUtils.queryAccount()[1];
        Account caregiver = J_TestUtils.queryAccount()[2];

        Test.startTest();
        //Create Consent
        J_Consent__c consent = new J_Consent__c(
            J_Patient__c = patient.Id,
			J_ConsentEffectiveDate__c = Date.today().addDays(-365),
            J_ConsentExpirationDate__c = Date.today().addDays(-1),
            J_ConsentStatus__c = J_ObjectUtils.CONSENT_CONSENT_STATUS_PL_EXPIRED,
			J_TypeOfConsent__c = 'Patient Authorization',
			J_Mail__c = 'Opt-in',
			J_Email__c = 'Opt-in',
			J_Phone__c = 'Opt-in',
			J_SMS__c = 'Opt-in',
			J_Meetings__c = 'Opt-in',
			J_MarketingMaterial__c = 'Opt-in',
			J_Caregiver__c = caregiver.Id
        );
        
        
        Exception ex;
        try {
			insert consent;
			update consent;
        } catch (OT_Error_Exception e) {
            ex = e;
        }
        Test.stopTest();

		// Validate the results
        System.assertEquals(null, ex);
    }

}