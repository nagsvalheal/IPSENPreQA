@isTest
public class J_TeamSharingQueueableTest {

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
        User u2 = [select id from User where Email = 'standarduser2@testorg.com' limit 1];
        CareProgramTeamMember teamMem = [select id,CareProgramId,UserId,Role from CareProgramTeamMember where UserId=:u2.Id limit 1];
        list<Team_Sharing_Criteria__mdt> lstTSC = [select Id,DeveloperName, Object_Name_Share__c, Object_Name__c, Query_Fields__c, ShareAccessLevel__c, ShareParentId__c,Where_Clause__c, bActive__c, bStandard__c from Team_Sharing_Criteria__mdt where 
                                                                     bActive__c =true and Object_Name__c='CareProgramProduct'];
        Test.startTest(); 
            J_TeamSharingQueueable objbatch = new J_TeamSharingQueueable(new set<id>{teamMem.id},lstTSC[0].DeveloperName);
            System.enqueueJob(objbatch);
            System.assertEquals(1, lstTSC.size(), 'One sharing record should be created.');
        Test.stopTest();
        
    }
}