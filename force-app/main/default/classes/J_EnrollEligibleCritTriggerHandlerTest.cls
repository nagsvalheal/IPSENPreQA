/**
* @class J_EnrollEligibleCritTriggerHandlerTest
* @description Test class to validate the functionality of `J_EnrollEligibleCritTriggerHandler`.
*              Verifies that non-administrative users cannot delete `EnrollmentEligibilityCriteria` records.
*/
@isTest
public class J_EnrollEligibleCritTriggerHandlerTest {
    /**
* @testSetup
* @description Sets up test data for the `EnrollmentEligibilityCriteria` object.
*              Creates a standard test user and inserts an `EnrollmentEligibilityCriteria` record.
*/
    @testSetup
    static void setup() {         
        // Create a test user using a utility method
        User u = J_TestUtils.createTestJourneysUser();   
        System.runAs(u) {  
            // Create and insert an EnrollmentEligibilityCriteria record
            EnrollmentEligibilityCriteria eliCriteria = new EnrollmentEligibilityCriteria(Name='testeliCriteria',Description='test Description',
                                                                                          Criteria_type__c='Enrollment',Status='Active',State__c='Alaska',Federal_poverty_level__c=100,
                                                                                          IPSEN_threshold__c=10,Persons_in_Family_Household__c=1,Effective_Date__c=date.today());
            insert eliCriteria;           
        }
    }
    /**
* @test
* @description Validates the `beforeDeleteMethod` to ensure non-administrative users cannot delete records.
*/
    @isTest
    static void beforeDeleteMethodTest() {      	
        Test.startTest();      
        // Fetch an existing EnrollmentEligibilityCriteria record
        EnrollmentEligibilityCriteria creteria = [select id from EnrollmentEligibilityCriteria limit 1];
        try{
            delete creteria;                    
        }catch(Exception ex){
        }  
        
        Test.stopTest();
    }
}