@isTest
public class NAFTriggerHandlerTest {
    
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
            	UserRoleId = role.Id
        );
        insert u;
        
        
    }
    
    @isTest static void beforeDeleteMethodTest() {   	
        User u = [SELECT Id FROM User WHERE Username = :'jTest@jTesting.com'];
        Test.startTest();   
        J_NAF__c naf = new J_NAF__c(Name='testnaf1',J_Subtype__c='Bone Marketing',J_Type__c='Annual',J_DateInitiated__c=Date.today(),J_DateExpired__c=Date.today()+10,OwnerId=u.Id,i_engage__c='test');
        insert naf;           
        try{
            System.runAs(u) {                
                delete naf;            
            }
        }catch (Exception ex) {
           system.assert(ex.getMessage().contains('You are not allowed to delete the NAF record'));
        }
        Test.stopTest();           
    }
    
}