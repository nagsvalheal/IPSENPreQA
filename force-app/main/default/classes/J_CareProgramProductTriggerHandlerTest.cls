@isTest
public class J_CareProgramProductTriggerHandlerTest {
	
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
        System.runAs(u) {  
            Product2 prod = new Product2(
                Name = 'Activin A',
                ProductCode = '756567',
                NDC_Code__c = '87545839273',
                Description = 'This way, you will have separate test methods for insert and update scenarios',
                QuantityUnitOfMeasure = 'Milligrams (mg)',
                IsActive=true 
            );
            insert prod;
            CareProgram cp1 = new CareProgram(Name='testcp1',status='Active');    
            insert cp1;
            CareProgramProduct cpProd1 = new CareProgramProduct(Name ='CareProgramProductname',Description__c='Test',Status='Active',CareProgramId=cp1.Id,ProductId=prod.Id);
            insert cpProd1;
        }
        
    }
    
    @isTest
    static void beforeDeleteMethodTest() {      	
        Test.startTest();      
        	User u = [SELECT Id FROM User WHERE Username = :'jTest@jTesting.com'];
            System.runAs(u) {  
                CareProgramProduct cpProd1 = [select id from CareProgramProduct limit 1];
                try{
                    delete cpProd1;                    
                }catch(Exception ex){
                   system.assertNotEquals('You are not allowed to delete the Care Program Product', ex.getMessage(),
                'Unexpected exception message during deletion.');
                   }  
            }
        Test.stopTest();
    }
    
    @isTest
    static void afterInsertMethodTest() {      	
        Test.startTest();  
        	Product2 prod =[select id from Product2];
        	CareProgram cp1 = new CareProgram(Name='testcp2',status='Active');    
            insert cp1;
            CareProgramProduct cpProd = new CareProgramProduct(Name ='CareProgramProductname',Description__c='Test',Status='Active',CareProgramId=cp1.Id,ProductId=prod.Id);
            insert cpProd; 
        	list<CareProgramProductShare> cpProdShare = [select id from CareProgramProductShare where ParentId=:cpProd.Id limit 1];
            system.assert(cpProdShare != null && !cpProdShare.isEmpty(), 
            'Expected sharing record was not created for the CareProgramProduct.');
        Test.stopTest();
    }
    
    @isTest
    static void afterDeleteMethodTest() {      	
        Test.startTest();      
        	CareProgramProduct cpProd = [select id from CareProgramProduct limit 1];
        	Delete cpProd;	
        	list<CareProgramProductShare> cpProdShare = [select id from CareProgramProductShare where ParentId=:cpProd.Id limit 1];
            system.assert(cpProdShare.size() == 0, 
            'Expected no sharing record for the deleted CareProgramProduct.');
        Test.stopTest();
    }
}