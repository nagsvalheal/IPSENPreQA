@isTest
public class J_CareEnrolleProductTriggerHandlerTest {
    static final String PATIENT_FIRST_NAME = 'patient_test';
    static final String STATE_MAILING = 'Arkansas';
    static final String CITY_MAILING = 'CITY';
    static final String STATUS = 'Active';
    
    @testSetup
    static void dataSetup(){         
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
        insert u;         
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
        
        insert lTerritory;
        
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
        insert patient; 
        
        // create a care program
        CareProgram cProgram = new CareProgram(Name = 'Care Program',
                                         StartDate = system.today(),
                                         Status = 'Active'
                                        );
        insert cProgram;
        
        // create enrollee
        CareProgramEnrollee cpEnrollee = new CareProgramEnrollee(Name = 'Enrollee Test',
                                                                 Status = 'Pending',
                                                                 Sub_Status__c='	New Enrollment',
                                                                 CareProgramId = cProgram.id,
                                                                 Clinical_trial_participant__c = 'Yes',
                                                                 AccountId = patient.id
                                                                );
        insert cpEnrollee;
        
        Product2 prod = new Product2(Name = 'Activin A',
                                     ProductCode = '756567',
                                     NDC_Code__c = '87545839273',
                                     Description = 'This way, you will have separate test methods for insert and update scenarios',
                                     QuantityUnitOfMeasure = 'Milligrams (mg)',
                                     IsActive=true
                                    );
        insert prod;
        CareProgramProduct cpp = new CareProgramProduct(Name ='CareProgramProductname',Description__c='Test',Status='Active',CareProgramId=cProgram.Id,ProductId=prod.Id);
        insert cpp;
        
    }
    
    @isTest
    static void beforeDeleteMethoddTest() {      	
        Test.startTest();     
            CareProgramEnrollee cpEnrollee =[select id from CareProgramEnrollee limit 1];
            CareProgramProduct cpp =[select id from CareProgramProduct limit 1];
            CareProgramEnrolleeProduct cpep = new CareProgramEnrolleeProduct(
                Name ='CareProgramenrolleProductname', CareProgramEnrolleeId = cpEnrollee.Id,
                CareProgramProductId = cpp.Id,
                Status = 'Active'
            );
            insert cpep;
            try {
                delete cpep;                    
            } catch(Exception ex) {
                // Assert that the exception message contains the expected string
                System.assert(ex.getMessage().contains('You are not allowed to delete the Care Program Enrollee Product'), 
                              'Expected exception message not found: ' + ex.getMessage());
            }        
        Test.stopTest();
    }
    
    @isTest
    static void afterInsertMethodTest() {      	
        Test.startTest();  
        	CareProgramEnrollee cpEnrollee =[select id from CareProgramEnrollee limit 1];
            CareProgramProduct cpp =[select id from CareProgramProduct limit 1];
            CareProgramEnrolleeProduct cpep = new CareProgramEnrolleeProduct(
                Name ='CareProgramenrolleProductname', CareProgramEnrolleeId = cpEnrollee.Id,
                CareProgramProductId = cpp.Id,
                Status = 'Active'
            );
            insert cpep;
List<CareProgramProductShare> cpepShare = [SELECT Id FROM CareProgramProductShare WHERE ParentId = :cpep.Id LIMIT 1];

// Assert that the list is not empty
System.assert(!cpepShare.isEmpty(), 'Expected CareProgramProductShare record was not found for ParentId: ' + cpep.Id);
        Test.stopTest();
    }
    
    @isTest
    static void afterDeleteMethodTest() {      	
        Test.startTest();      
        	CareProgramEnrollee cpEnrollee =[select id from CareProgramEnrollee limit 1];
            CareProgramProduct cpp =[select id from CareProgramProduct limit 1];
            CareProgramEnrolleeProduct cpep = new CareProgramEnrolleeProduct(
                Name ='CareProgramenrolleProductname', CareProgramEnrolleeId = cpEnrollee.Id,
                CareProgramProductId = cpp.Id,
                Status = 'Active'
            );
            insert cpep;
        	Delete cpep;	
        	// Query CareProgramProductShare records related to the deleted cpep
List<CareProgramProductShare> cpepShare = [SELECT Id FROM CareProgramProductShare WHERE ParentId = :cpep.Id LIMIT 1];

// Assert that no CareProgramProductShare records exist for the deleted cpep
System.assert(cpepShare.isEmpty(), 'CareProgramProductShare record was not deleted for ParentId: ' + cpep.Id);
        Test.stopTest();
    }
}