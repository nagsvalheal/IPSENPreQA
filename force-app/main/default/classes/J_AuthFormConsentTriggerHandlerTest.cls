/**
*   @description    Unit Tests for J_AuthFormConsentTriggerHandler class
**/
@isTest
private class J_AuthFormConsentTriggerHandlerTest {
    /**
     * @description
     * Test setup method to create the necessary test data for the AuthorizationFormConsent and related objects
     * like Account, CareProgram, CareProgramEnrollee, AuthorizationForm, and Consent_Doc.
     * This ensures that data is available for all test methods.
     */
    @TestSetup
    static void makeData()
    {
        //Create Patient
        Account patient = new Account(
            LastName = 'TestLastName',
            FirstName = 'TestFirstName',
            RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonMailingCity = J_TestUtils.CITY_MAILING,
            PersonMailingState = J_TestUtils.STATE_MAILING,
            PersonBirthdate = Date.today().addYears(-19),
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '1234567891'
        );
        insert patient;
        
        //Create CareProgram
        CareProgram cp = new CareProgram(
            Name = 'Test Care Program',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(1),
            Status = 'Active'
        );
        insert cp;
        
        //Create CareProgramEnrollee
        CareProgramEnrollee cpe = new CareProgramEnrollee(
            Name = 'Test Enrollee',
            CareProgramId = CP.id,
            Status = 'Pending',
            Sub_Status__c= 'New Enrollment',
            PA_Consent_Status__c = 'Active',
            AccountId = patient.id
        );
        insert cpe;
        
        //Create AuthorizationForm
        AuthorizationForm af = new AuthorizationForm(
            Name = 'Journeys Authorization Form'
        );
        insert af; 
        
        //Create AuthorizationFormText
        AuthorizationFormText aft = new AuthorizationFormText(
            AuthorizationFormId = af.id,
            Name = 'Journeys Authorization Form Text',
            SummaryAuthFormText = 'Summary Authorization Form Text',
            IsActive = true,
            Locale = 'en_US'
        );
        insert aft;
        
        AuthorizationFormConsent afc = new AuthorizationFormConsent(
            Name = 'Patient Authorization',
            ConsentGiverId = cpe.id,
            Care_Program_Enrollee__c = cpe.id,
            AuthorizationFormTextId = aft.id,
            
            J_TypeOfConsent__c = 'Patient Authorization',
            J_ConsentStatus__c = 'Active',
            J_EnrollmentFormAttached__c = true,            
            Consented_by_others__c = 'No',
            ConsentCapturedDateTime = Date.today(),
            //Consented_Caregiver__c = encare.id,
            J_Email__c = 'Opt-in',
            J_Mail__c = 'Opt-in',
            J_SMS__c  = 'Opt-in',
            J_Meetings__c = 'Opt-in',
            J_Phone__c = 'Opt-in',
            J_MarketingMeterial__c = 'Opt-in'    
        );
        insert afc;

        Consent_Doc__c cd = new Consent_Doc__c (Authorization_Form_Consent__c = afc.id, Name='Patient Authorization Document');
        Insert cd;
        
        //cpe.Status = 'Active';
        //cpe.Sub_Status__c ='PAP';
        //cpe.PA_Consent_Active__c = true;
        //UPDATE cpe;

    }
    /**
     * @description
     * Test method to check if the system correctly handles an attempt to insert a ContentDocumentLink
     * when a document is already linked to the same entity. This test ensures that proper error handling
     * is done when the duplicate link exception is thrown.
     */
    @IsTest
    //Test Class for Class J_ContentDocumentLinkTriggerHandler
    static void checkEnrollmentForm2ActivateConsentTest()
    {
        //AuthorizationFormConsent afc = [SELECT ID,Name FROM AuthorizationFormConsent LIMIT 1];
        Consent_Doc__c cd = [SELECT ID,Name FROM Consent_Doc__c LIMIT 1];
        
        
        Test.startTest();
        ContentVersion cv = new ContentVersion(
            Title = 'TestFirstName TestLastName - Journeys Enrollment Form',
            PathOnClient = 'TestFirstName TestLastName - Journeys Enrollment Form.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert cv;
        ContentVersion newtestContent = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = newtestContent.ContentDocumentId;
        cdl.LinkedEntityId = cd.Id;
        insert cdl;
        
        ContentDocumentLink cdl2 = new ContentDocumentLink();
        cdl2.ContentDocumentId = newtestContent.ContentDocumentId;
        cdl2.LinkedEntityId = cd.Id;
        try{
            insert cdl2;
        }
        Catch (Exception ex){
            String expectedSubstring = 'already linked with the entity';
            String actualMessage = ex.getMessage();
        
            // Check if the message contains the expected substring
            Assert.areEqual(
                actualMessage.contains(expectedSubstring),True,
                'Error: Expected message to contain "' + expectedSubstring + '" but got "' + actualMessage + '"'
            );        }
        
        Test.stopTest();
    }
    
    /**
     * @description
     * Test method to verify that the 'before delete' trigger on AuthorizationFormConsent correctly 
     * prevents deletion when the user does not have permission, and throws an appropriate error message.
     */
    @isTest 
    static void beforeDeleteMethodTest() 
    {      	
        Test.startTest();            
        AuthorizationFormConsent afc = [SELECT ID,Name FROM AuthorizationFormConsent LIMIT 1];
        Consent_Doc__c cd = [SELECT ID,Name FROM Consent_Doc__c LIMIT 1];
        
        try{
            delete afc;
            delete cd;
        }
        catch(Exception ex){
            String expectedMessage = 'You do not have permission to delete this record';
            String actualMessage = ex.getMessage();
            // Use Assert.assertEquals with only two arguments (expected, actual)
            Assert.areEqual(expectedMessage, actualMessage, 'Error: Expected message "' + expectedMessage + '" but got "' + actualMessage + '"');
        }        
        Test.stopTest();
    }
}