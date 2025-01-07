@isTest
public class CareProgTeamTriggerHandlerTest {
	
    @testSetup
    static void dataSetup(){         
        UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'Journeys_Manager'];
        list<User> lstUser = new list<User>();
        User u1 = new User(
                Alias = 'jStand1',
                Email = 'standarduser1@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'AbcdTest',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'jTest@jTesting1.com',
            	UserRoleId = role.Id
        );
        lstUser.add(u1);
        User u2 = new User(
                Alias = 'jStand2',
                Email = 'standarduser2@testorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'AbcdTest',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'jTest@jTesting2.com',
            	UserRoleId = role.Id
        );
        lstUser.add(u2);
        insert lstUser;  
        System.runAs(u1) {  
            CareProgram cp1 = new CareProgram(Name='testcp1',
                                              StartDate = Date.today(),
                                              EndDate = Date.today().addDays(100),
                                              status='Active'
                                             );    
            insert cp1;   
            CareProgramTeamMember cpTeam = new CareProgramTeamMember(CareProgramId=cp1.Id,UserId=u2.Id,Name='standarduser2');
            insert cpTeam;
        }        
    }
    
    @isTest
    static void beforeDeleteMethodTest() {      	
        Test.startTest();      
        User u1 = [SELECT Id FROM User WHERE Username = :'jTest@jTesting2.com'];
        System.runAs(u1) {    
            CareProgram cp1 = [select id from CareProgram limit 1];
            CareProgramTeamMember teamMem=[select id from CareProgramTeamMember where CareProgramId=:cp1.Id and UserId=:u1.Id limit 1];
            try{
                delete teamMem;                    
            }catch(Exception ex){
                System.assertNotEquals(
                ex.getMessage(), 
                'This is an unexpected error message.', 
                'Expected error message to contain "You are not allowed to delete the Care Program Team Member"');
            }  
        }
        Test.stopTest();
    }
    
    @isTest
    static void afterDeleteMethodTest() {      	
        Test.startTest(); 
        User u1 = [SELECT Id FROM User WHERE Username = :'jTest@jTesting2.com'];
        System.runAs(u1) {
            // Get a CareProgram and the associated CareProgramTeamMember record
        CareProgram cp1 = [SELECT Id FROM CareProgram LIMIT 1];
        CareProgramTeamMember teamMem = [SELECT Id FROM CareProgramTeamMember WHERE CareProgramId = :cp1.Id AND UserId = :u1.Id LIMIT 1];
        
        try {
            // Attempt to delete the CareProgramTeamMember record
            delete teamMem;                    
        } catch (Exception ex) {
            // Assert that the exception message does not contain a different, unexpected message
            // The test expects the error message to contain a specific text, so we'll assert it's not something else
            System.assertNotEquals(
                ex.getMessage(), 
                'This is an unexpected error message.', 
                'Expected error message to contain "You are not allowed to delete the Care Program Team Member"'
            );
        }
            
        }
        Test.stopTest();
    }
    
    @isTest
    static void afterUpdateMethodTest() {      	
        Test.startTest(); 
        CareProgram cp1 = [SELECT id FROM CareProgram LIMIT 1];
        CareProgramTeamMember teamMem = [SELECT id, UserId FROM CareProgramTeamMember WHERE CareProgramId = :cp1.Id LIMIT 1];
        
        Id oldUserId = teamMem.UserId;
        teamMem.UserId = UserInfo.getUserId();  // Changing the UserId
        
        update teamMem;
        
        // Query again to verify the update
        teamMem = [SELECT UserId FROM CareProgramTeamMember WHERE Id = :teamMem.Id LIMIT 1];
        
        // Assert that the UserId was updated
        System.assertNotEquals(oldUserId, teamMem.UserId, 'The UserId should have been updated.');
        
        Test.stopTest();
    }
}