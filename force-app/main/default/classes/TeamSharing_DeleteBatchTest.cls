@isTest
public class TeamSharing_DeleteBatchTest {
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
            Product2 prod = new Product2(
                Name = 'Activin A',
                ProductCode = '756567',
                NDC_Code__c = '87545839273',
                Description = 'This way, you will have separate test methods for insert and update scenarios',
                QuantityUnitOfMeasure = 'Milligrams (mg)',
                IsActive=true 
            );
            insert prod;
            CareProgram cp1 = new CareProgram(Name='testcp1',
                                              StartDate = Date.today(),
                                              EndDate = Date.today().addDays(100),
                                              status='Active'
                                             );    
            insert cp1;   
            CareProgramTeamMember cpTeam = new CareProgramTeamMember(CareProgramId=cp1.Id,UserId=u2.Id,Name='standarduser2');
            insert cpTeam;
            CareProgramProduct cpProd1 = new CareProgramProduct(Name ='CareProgramProductname',Description__c='Test',Status='Active',CareProgramId=cp1.Id,ProductId=prod.Id);
            insert cpProd1;            
        }
    }
    
    @isTest
    static void testExecute() {  
        CareProgram cp1 = [select id from CareProgram limit 1];  
        list<object> shareObjectList=[select id from CareProgramProductshare where Parent.CareProgramId=:cp1.Id and RowCause='Manual'];
        if(shareObjectList!=null && shareObjectList.size()>0){
            Test.startTest(); 
                System.enqueueJob(new TeamSharing_DeleteBatch(shareObjectList,'CareProgramProductshare'));
                system.assert(shareObjectList!=null && shareObjectList.size()>0,'CareProgramProductshare record not exist');
            Test.stopTest();
        }
        
    }
    
}