/**
 * @description       : Test class for validating the behavior of triggers and sharing logic
 *                       associated with the Email_Data__c object. This class ensures the correct 
 *                       creation, sharing, and deletion of records in relation to the CareProgramEnrollee
 *                       and associated Email Data.
 * @testClass         : J_Email_Data_TriggerHandlerTest
 * @author            : Vijay 
 * @last modified on  : 08-12-2024
 * 
**/
@IsTest
public class J_Email_Data_TriggerHandlerTest {
    static final String PATIENT_FIRST_NAME = 'patient_test';
    static final String STATE_MAILING = 'Arkansas';
    static final String CITY_MAILING = 'CITY';
    static final String STATUS = 'Active';
  /**
     * @description       : Test setup method to create test data for User, Territories, Patient,
     *                       Care Program, and Care Program Enrollee. This data is used by the test methods.
     **/   
	@testSetup
    static void makeData()
    { 
        //Create test User
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
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{u}, 'J_Email_Data_TriggerHandlerTest', false);

        
        List<J_Territory__c> lTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(J_Active__c = true,
                                                        J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
                                                        J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
                                                        J_TerritoryCode__c = 'test 1',
                                                        J_States__c = 'test 1',
                                                        Name = J_TestUtils.TERRITORY_NAME_CC
                                                       );
        lTerritory.add(territoryCC);
        
        J_Territory__c territoryPEL = new J_Territory__c(J_Active__c = true,
                                                         J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
                                                         J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
                                                         J_TerritoryCode__c = 'test 2',
                                                         J_States__c = 'test 2',
                                                         Name = J_TestUtils.TERRITORY_NAME_PEL
                                                        );
        lTerritory.add(territoryPEL);
        
        COM_DatabaseOperationsUtility.insertOperation(lTerritory, 'J_Email_Data_TriggerHandlerTest', false);
        
        //Create Patient
        Account patient = new Account(FirstName	 = PATIENT_FIRST_NAME,
                                      LastName        = J_TestUtils.PATIENT_LAST_NAME,
                                      RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
                                      J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
                                      PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
                                      PersonMailingStreet = J_TestUtils.STREET_MAILING,
                                      PersonBirthdate = Date.today().addYears(-19),
                                      Patient_Status__pc = STATUS,
                                      Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
                                      PersonHomePhone = '00099',
                                      PersonMailingState= STATE_MAILING,
                                      PersonMailingCity = CITY_MAILING
                                     );
         COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{patient}, 'J_Email_Data_TriggerHandlerTest', false);
        
        // create a care program
        CareProgram cp = new CareProgram(Name = 'Care Program',
                                         StartDate = system.today(),
                                         Status = 'Active'
                                        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{cp}, 'J_Email_Data_TriggerHandlerTest', false);
        
        // create enrollee
        CareProgramEnrollee cpEnrollee = new CareProgramEnrollee(Name = 'Enrollee Test',
                                                                 Status = 'Pending',
                                                                 Sub_Status__c='	New Enrollment',
                                                                 CareProgramId = cp.id,
                                                                 Clinical_trial_participant__c = 'Yes',
                                                                 AccountId = patient.id
                                                                );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{cpEnrollee}, 'J_Email_Data_TriggerHandlerTest', false);
        
        
    }
    /**
     * @description       : Test method to validate the sharing logic of Email_Data__c records 
     *                       after an insert operation. Verifies that the record is shared correctly
     *                       with Care Program Admin (PEL).
     **/
    @IsTest
    static void afterInsertMethodTest() 
    {
        CareProgramEnrollee enrollee = [select id,CareProgramId from CareProgramEnrollee limit 1];
        Test.startTest();
        	Email_Data__c eData = new Email_Data__c();
        	eData.Subject__c = 'test subject';
        	eData.Messages__c = 'test message';
        	eData.Care_Program_Enrollee__c=enrollee.Id;
            COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{eData}, 'J_Email_Data_TriggerHandlerTest', false);
        	list<Email_Data__Share> eDataShare = [select id from Email_Data__Share where ParentId=:eData.Id limit 1];
            system.assert(eDataShare!=null,'Email Data not shared with care program admin (PEL)');
        Test.stopTest();
    }
    /**
     * @description       : Test method to validate the sharing logic of Email_Data__c records 
     *                       after a delete operation. Verifies that sharing records are removed.
     **/
    @IsTest
    static void afterDeleteMethodTest() 
    {
        CareProgramEnrollee enrollee = [select id from CareProgramEnrollee limit 1];
        Test.startTest();
        	Email_Data__c eData = new Email_Data__c();
        	eData.Subject__c = 'test subject';
        	eData.Messages__c = 'test message';
        	eData.Care_Program_Enrollee__c=enrollee.Id;
            COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{eData}, 'J_Email_Data_TriggerHandlerTest', false);
            COM_DatabaseOperationsUtility.deleteOperation(new List<SObject>{eData}, 'J_Email_Data_TriggerHandlerTest', false);    
        	list<Email_Data__Share> eDataShare = [select id from Email_Data__Share where ParentId=:eData.Id limit 1];
            system.assert(eDataShare.size()==0,'Email Data not shared with care program admin (PEL)');
        Test.stopTest();
    }
}