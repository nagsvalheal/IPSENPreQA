@isTest
public class TeamSharing_HelperClassTest {
    
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
    static void CreateTeamSharingTest() {      
        CareProgram cp1 = [select id from CareProgram limit 1];
        CareProgramTeamMember teamMem=[select id from CareProgramTeamMember where CareProgramId=:cp1.Id limit 1];
        Set<Id> lstCareProgTeamMemIds = new Set<Id>();
        lstCareProgTeamMemIds.add(teamMem.Id);
        Test.startTest(); 
            TeamSharing_HelperClass.CreateTeamSharing(lstCareProgTeamMemIds,true);        	      
        Test.stopTest();
    }
    
    @isTest
    static void DeleteTeamSharingTest() {      
        CareProgram cp1 = [select id from CareProgram limit 1];
        CareProgramTeamMember teamMem=[select id,CareProgramId,UserId from CareProgramTeamMember where CareProgramId=:cp1.Id limit 1];
       	map<string,string> mpCareProgramTemDetails= new map<string,string>();
        mpCareProgramTemDetails.put(teamMem.Id,teamMem.UserId+','+teamMem.CareProgramId);        
        Test.startTest(); 
            TeamSharing_HelperClass.DeleteTeamSharing(mpCareProgramTemDetails,true);        	      
        Test.stopTest();
    }
    
    @isTest
    static void getSelectedFieldsByDynamicSOQLTest() { 
        string selectedfields = 'id,OwnerId';
        string sobjectName='CareProgramTeamMember';
        string whereClause='id!=null';
        integer returnLimit=1000;
        Test.startTest(); 
            TeamSharing_HelperClass.getSelectedFieldsByDynamicSOQL(selectedfields,sobjectName,whereClause,returnLimit);        	      
        Test.stopTest();
    }
    
    @isTest
    static void insertShareRecordsTest() {      
        CareProgramProduct cpProd1 = [select id,CareProgramId,OwnerId from CareProgramProduct limit 1];
        map<string,map<string,string>> mpCPProductDetails = new map<string,map<string,string>>();
        map<string,string> prodDetails = new map<string,string>();
        prodDetails.put(cpProd1.Id,cpProd1.OwnerId);
        mpCPProductDetails.put(cpProd1.CareProgramId, prodDetails);
        Test.startTest(); 
            TeamSharing_HelperClass.insertShareRecords('CareProgramProduct','CareProgramProductShare',mpCPProductDetails);        	      
        Test.stopTest();
    }
    
    @isTest
    static void DeleteSharingRecordsTest() {      
        set<string> lstDeRecords = new set<String>();         
        CareProgramProduct cpProd1 = [select id,CareProgramId,OwnerId from CareProgramProduct limit 1];
        lstDeRecords.add(cpProd1.Id);       
        Test.startTest(); 
            TeamSharing_HelperClass.DeleteSharingRecords('CareProgramProductShare',lstDeRecords);        	      
        Test.stopTest();
    }
    
    @isTest
    static void getTeamSharingObjectsTest() {         
        Test.startTest(); 
            TeamSharing_HelperClass.getTeamSharingObjects(true,'CareProgramProduct');        	      
        Test.stopTest();
    }
    
    @isTest
    static void buildWhereClauseTest() { 
        set<String> stringList=new set<String>{'Id','OwnerId','CreatedById'};        
        Test.startTest(); 
            TeamSharing_HelperClass.buildWhereClause(stringList);        	      
        Test.stopTest();
    }

}