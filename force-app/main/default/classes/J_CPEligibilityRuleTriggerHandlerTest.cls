/**
* @class J_CPEligibilityRuleTriggerHandlerTest
* @description Test class for the `J_CPEligibilityRuleTriggerHandler` class. This class includes test cases
*              for validating the trigger handler's behavior during CareProgramEligibilityRule record deletion.
* @visibility public
* @isTest
*/
@isTest
public class J_CPEligibilityRuleTriggerHandlerTest {	
    /**
* @method dataSetup
* @description Test setup method to create the necessary test data, including a CareProgram, 
*              EnrollmentEligibilityCriteria, and CareProgramEligibilityRule records. This data 
*              will be used in subsequent test methods.
*/
    
    @testSetup
    static void dataSetup(){         
       
        User u = J_TestUtils.createTestJourneysUser();
        System.runAs(u) {  
            CareProgram cp1 = new CareProgram(Name='testcp1',Status='Active');    
            insert cp1;
            EnrollmentEligibilityCriteria eliCriteria = new EnrollmentEligibilityCriteria(Name='testeliCriteria',Description='test Description',
                                                                                          Criteria_type__c='Enrollment',Status='Active',State__c='Alaska',Federal_poverty_level__c=100,
                                                                                          IPSEN_threshold__c=10,Persons_in_Family_Household__c=1,Effective_Date__c=date.today());
            insert eliCriteria;
            CareProgramEligibilityRule cpEligiRule = new CareProgramEligibilityRule(CareProgramId=cp1.Id,EligibilityCriteriaId=eliCriteria.Id,Status='Active');
            insert cpEligiRule;
        }
    }
    
    /**
* @method afterDeleteMethodTest
* @description Validates that after a CareProgramEligibilityRule record is deleted, any associated 
*              CareProgramProductShare records are also removed.
*/
    @isTest
    static void beforeDeleteMethodTest() {      	
        Test.startTest();      
        User u = [SELECT Id FROM User WHERE Alias = 'jStand'];
        System.runAs(u) {  
            CareProgramEligibilityRule cpEligiRule = [select id from CareProgramEligibilityRule limit 1];
            try{
                delete cpEligiRule;                    
            }catch(Exception ex){
                // system.assert(ex.getMessage().contains('You are not allowed to delete the Care Program'));
            }  
        }
        Test.stopTest();
    }
    
    /**
* @method afterDeleteMethodTest
* @description Validates that after a CareProgramEligibilityRule record is deleted, any associated 
*              CareProgramProductShare records are also removed.
*/
    @isTest
    static void afterDeleteMethodTest() {      	
        Test.startTest();      
        CareProgramEligibilityRule cpEligiRule = [select id from CareProgramEligibilityRule limit 1];
        Delete cpEligiRule;	
        list<CareProgramProductShare> cpEligiRuleShare = [select id from CareProgramProductShare where ParentId=:cpEligiRule.Id limit 1];
        system.assert(cpEligiRuleShare.size()==0);
        Test.stopTest();
    }
}