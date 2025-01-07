/**
 * @class J_CareProgramTriggerHandlerTest
 * @description Test class for the `J_CareProgramTriggerHandler` to verify the behavior of the `beforeDeleteMethod`.
 *              Ensures that only authorized users can delete `CareProgram` records.
 * @visibility public
 */
@isTest
public class J_CareProgramTriggerHandlerTest {	
    /**
     * @method setup
     * @description Creates test data and a standard user with a non-administrative profile.
     */
    @testSetup
    static void setup() {       
       // UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'Journeys_Manager'];
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
            //	UserRoleId = role.Id
        );
        insert u;          
    }
       /**
     * @method beforeDeleteMethodTest
     * @description Verifies that the `beforeDeleteMethod` prevents non-administrative users
     *              from deleting `CareProgram` records by adding an appropriate error.
     */
    @isTest
    static void beforeDeleteMethodTest() {      	
        Test.startTest();      
        	  
                CareProgram cp1 = new CareProgram(Name='testcp1');    
                insert cp1;
                try{
                    delete cp1;                    
                }catch(Exception ex){
                    system.assert(ex.getMessage().contains('You are not allowed to delete the Care Program'));
                } 
        Test.stopTest();
    }
}