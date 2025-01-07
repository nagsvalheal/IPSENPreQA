/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 08-01-2022
 * @last modified by  : 
**/
@IsTest
public class J_ContentDocumentLinkTriggerHandlerTest {
  
    @TestSetup
    static void makeData()
    {
       
        User u = new User(Alias = 'jStand',
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
        
        //Create Patient
        Account patient = new Account(FirstName = 'TestFirstName',
                                      LastName        = 'TestLastName',
                                      RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
                                      J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
                                      PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
                                      PersonMailingStreet = J_TestUtils.STREET_MAILING,
                                      PersonMailingCity = J_TestUtils.CITY_MAILING,
                                      PersonMailingState= J_TestUtils.STATE_MAILING,
                                      PersonBirthdate = Date.today().addYears(-19),
                                      Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
                                      Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
                                      PersonHomePhone = '00099'
                                     );
        insert patient;
        
        //Create Cre Program
        CareProgram cp = new CareProgram(Name = 'Test Care Program',
                                         StartDate = Date.today(),
                                         EndDate = Date.today().addDays(1),
                                         Status = 'Active'
                                        );
        insert cp;
        
        // Create a CareProgramEnrollee record and set the lookup field to the CareProgram record created above
        CareProgramEnrollee enrollee = new CareProgramEnrollee(Name = 'Test Enrollee', 
                                                               Status = 'Pending',
                                                               Sub_Status__c='	New Enrollment',
                                                               Clinical_trial_participant__c = 'Yes',
                                                               AccountId = patient.Id,
                                                               CareProgramId = cp.Id
                                                              );
        insert enrollee;
    }

    @IsTest
    static void checkFileNameForEnrollmentFormCorrectNameTest() 
    {
        
        CareProgramEnrollee enrollee = [select id from CareProgramEnrollee limit 1];
            
        J_Charitable__c charitable = new J_Charitable__c (Care_Program_Enrollee__c = enrollee.Id,
                                                          J_CharitableStatus__c = 'In Process',
                                                          J_Enrollment_Start_Date__c = Date.today(),
                                                          J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                                                          J_Persons_in_Family_Household__c = 11,
                                                          J_Annual_Household_Income__c = 11111
                                                         );
        insert charitable;
        
        //Create AuthorizationForm
        AuthorizationForm af = new AuthorizationForm(Name = 'Journeys Authorization Form');
        insert af; 
        
        //Create AuthorizationFormText
        AuthorizationFormText aft = new AuthorizationFormText(AuthorizationFormId = af.id,
                                                              Name = 'Journeys Authorization Form Text',
                                                              SummaryAuthFormText = 'Summary Authorization Form Text',
                                                              IsActive = true,
                                                              Locale = 'en_US'
                                                             );
        insert aft;
        
        AuthorizationFormConsent afc = new AuthorizationFormConsent(Name = 'Patient Authorization',
                                                                    ConsentGiverId = enrollee.id,
                                                                    Care_Program_Enrollee__c = enrollee.id,
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
        
        
        Test.startTest();
        Exception ex;
        try {
            ContentVersion contentVersion = new ContentVersion(
                Title = 'TestFirstName TestLastName - PAP Enrollment Form',
                PathOnClient = 'TestFirstName TestLastName - PAP Enrollment Form.pdf',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
            );
            insert contentVersion;
            ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
            ContentDocumentLink newLink = new ContentDocumentLink();
            newLink.ContentDocumentId = testContent.ContentDocumentId;
            newLink.LinkedEntityId = charitable.Id;
            insert newLink;
            
        }catch (Exception e) {
            ex = e;
        }
        Test.stopTest();
        System.assertEquals(null, ex, 'Exception Handled');
        
    }
    

    @IsTest
    static void checkEnrollmentForm2ActivateConsentTest()
    {
        Account patient = [select id from Account WITH SECURITY_ENFORCED limit 1];
        CareProgramEnrollee enrollee = [select id from CareProgramEnrollee limit 1];
        
        
        //Create AuthorizationForm
        AuthorizationForm af = new AuthorizationForm(Name = 'Journeys Authorization Form');
        insert af; 
        
        //Create AuthorizationFormText
        AuthorizationFormText aft = new AuthorizationFormText(AuthorizationFormId = af.id,
                                                              Name = 'Journeys Authorization Form Text',
                                                              SummaryAuthFormText = 'Summary Authorization Form Text',
                                                              IsActive = true,
                                                              Locale = 'en_US'
                                                             );
        insert aft;
        
        AuthorizationFormConsent afc = new AuthorizationFormConsent(Name = 'Patient Authorization',
                                                                    ConsentGiverId = enrollee.id,
                                                                    Care_Program_Enrollee__c = enrollee.id,
                                                                    AuthorizationFormTextId = aft.id,
                                                                    J_TypeOfConsent__c = 'Patient Authorization',
                                                                    J_ConsentStatus__c = 'In Progress',
                                                                    //J_EnrollmentFormAttached__c = true,            
                                                                    Consented_by_others__c = 'No',
                                                                    ConsentCapturedDateTime = Date.today(),
                                                                    J_Patient__c = Patient.id,
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
        Catch (Exception ex1){
            System.assertEquals(cdl2.ContentDocumentId, newtestContent.ContentDocumentId,'Both files should fail');
         
        }
        
        Test.stopTest();
        
    }

}