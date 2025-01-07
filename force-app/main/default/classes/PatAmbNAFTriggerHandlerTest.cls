@isTest
public class PatAmbNAFTriggerHandlerTest {
    
    @testSetup
    static void dataSetup(){         
        UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'Journeys_Manager'];
        User u = new User(
                Alias = 'jStand',
                Email = 'standarduser@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'AbcdTest',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'jTest@jTesting.com',
            	UserRoleId = role.Id,
            	Patient_Ambassador_Manager__c=true
        );
        insert u;
        
        
    }
    
    @isTest static void beforeDeleteMethodTest() {   	
        User u = [SELECT Id FROM User WHERE Username = :'jTest@jTesting.com'];
        Test.startTest(); 
        Account patient = new Account(
                LastName = J_TestUtils.PATIENT_LAST_NAME,
            	FirstName = 'patient_last',
                RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
                J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
                PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
                PersonMailingStreet = J_TestUtils.STREET_MAILING,
            	PersonMailingCity = 'Coimbatore',
            	PersonMailingCountry='Australia',
            	PersonMailingState = 'Queensland',
            	PersonEmail = 'test@test.com',
            	J_PatientAmbassadorStatus__c = 'Active',
            	Patient_Ambassador_Manager__c=u.Id
        );
        insert patient;
        J_NAF__c naf = new J_NAF__c(Name='testnaf1',J_Subtype__c='Bone Marketing',J_Type__c='Annual',J_DateInitiated__c=Date.today(),J_DateExpired__c=Date.today()+10,OwnerId=u.Id,i_engage__c='test');
        insert naf;         
        J_PatientAmbassadorNAF__c panaf = new J_PatientAmbassadorNAF__c(OwnerId=u.Id,J_PatientAmbassador__c=patient.Id,J_NAFID__c=naf.Id);
        insert panaf;
        try{
            System.runAs(u) {                
                delete panaf;            
            }
        }catch (Exception ex) {
           system.assert(ex.getMessage().contains('You are not allowed to delete the Patient Ambassador FFS record'));
        }
        Test.stopTest();           
    }
    
}