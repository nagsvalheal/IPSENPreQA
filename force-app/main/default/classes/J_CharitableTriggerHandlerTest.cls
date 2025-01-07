/**
 * @description Test class to verify the functionality of the J_CharitableTriggerHandler class. 
 * This class contains tests for inserting, updating, and verifying constraints for Charitable records.
 * Specifically, it focuses on checking the behavior when trying to insert a second charitable record 
 * with the same enrollment start and end dates for the same Care Program Enrollee.
 * @author Arkadii Sychov
 * @date 10/29/20 
**/
@isTest
public class J_CharitableTriggerHandlerTest {
  static final String CHARITABLE_STATUS  = 'Closed';
    /**
     * @description Test method to verify that an exception is thrown when inserting a second charitable record
     * with the same enrollment start and end dates for the same Care Program Enrollee.
     * 
     * @throws Exception If any unexpected exception occurs during the test.
     */
    @isTest
    static void sameDatesCharitableInsertTest() {
        

         // Create Patient
        Account patient = J_TestUtils.createPatient();
        
        // Create Care Program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee for the patient
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);

        // Create the first charitable record with the same enrollment dates
        J_Charitable__c charitable = new J_Charitable__c(
            Care_Program_Enrollee__c = enrollee.Id,
            J_Enrollment_Start_Date__c = Date.today(),
            J_Enrollment_End_Date__c = Date.today().addDays(1),
            J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
            J_CharitableStatus__c = 'Active',
            J_Persons_in_Family_Household__c = 11,
            J_Annual_Household_Income__c = 11111
        );
        insert charitable;
         ContentVersion contentVersion = new ContentVersion(
                                            Title = 'TestFirstName TestLastName - PAP Enrollment Form',
                                            PathOnClient = 'estFirstName TestLastName - PAP Enrollment Form.pdf',
                                            VersionData = Blob.valueOf('Test Content'),
                                            IsMajorVersion = true
                                        );
        insert contentVersion;
        ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = testContent.ContentDocumentId;
        newLink.LinkedEntityId = charitable.Id;
        insert newLink;

        Exception ex;
        try {
            // Create a second charitable record with the same enrollment dates
            J_Charitable__c charitable2 = new J_Charitable__c(
                Care_Program_Enrollee__c = enrollee.Id,
                J_Enrollment_Start_Date__c = Date.today(),
                J_Enrollment_End_Date__c = Date.today().addDays(1),
                J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                J_CharitableStatus__c = 'Active'
            );
            insert charitable2;
        } catch (Exception e) {
            ex = e;
        }

        // Assert that an exception was thrown due to the duplicate charitable record
        System.assertNotEquals(null, ex, 'An exception should be thrown for duplicate Charitable record with the same dates.');
           }

    /**
     * @description Test method to verify that an exception is thrown when inserting a copay record 
     * with enrollment dates that overlap with an existing charitable record.
     * 
     * @throws Exception If any unexpected exception occurs during the test.
     */
    @isTest
    static void sameDatesCopayInsertTest() {
       
         //Create Territory
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        iTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        iTerritory.add(territoryPEL);

        insert iTerritory;

        // Create Patient
        Account patient = J_TestUtils.createPatient();
        
        // Create Care Program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee for the patient
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);


        J_Charitable__c charitable = new J_Charitable__c (
            	Care_Program_Enrollee__c = enrollee.Id,
                
                J_Enrollment_Start_Date__c = Date.today(),
                //J_Enrollment_End_Date__c = Date.today().addDays(1),
                J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                J_CharitableStatus__c = CHARITABLE_STATUS,
            J_Persons_in_Family_Household__c = 11,
            J_Annual_Household_Income__c = 11111
        );
        insert charitable;

        Exception ex;

        try {
            J_Copay__c copay = new J_Copay__c (
                    
                    Care_Program_Enrollee__c = enrollee.Id,
                    J_EnrollmentStartDate__c = Date.today(),
                    J_EnrollmentEndDate__c = Date.today().addDays(1),
                    J_CurrentCopayStatus__c = J_ObjectUtils.COPAY_CURRENT_COPAY_STATUS_PL_ACTIVE
            );
            insert copay;
        } catch (Exception e) {
            ex = e;
        }

      // Assert that an exception was thrown
    System.assertNotEquals(null, ex, 'An exception should be thrown when inserting a copay record with overlapping dates.');
    
    }

    /**
     * @description Test method to verify that an exception is thrown when updating a charitable record to a status that would create a duplicate 
     * enrollment start date with another active charitable record for the same care program enrollee.
     * 
     * This test performs the following steps:
     * 1. Creates Territory records for relevant territories.
     * 2. Creates a Patient, Care Program, and Care Program Enrollee.
     * 3. Inserts two charitable records with the same enrollment start date for the same care program enrollee.
     * 4. Attempts to update the second charitable record to an active status, which should result in a duplicate date error.
     * 5. Asserts that an exception is thrown due to the duplicate charitable record with the same dates.
     */
    @isTest
    static void sameDayCharitableUpdateTest() {
       
         //Create Territory
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        iTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        iTerritory.add(territoryPEL);

        insert iTerritory;

        // Create Patient
        Account patient = J_TestUtils.createPatient();
        
        // Create Care Program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee for the patient
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);

        
        J_Charitable__c charitable = new J_Charitable__c (
            	Care_Program_Enrollee__c = enrollee.Id,
                
                J_Enrollment_Start_Date__c = Date.today(),
                J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                J_CharitableStatus__c = CHARITABLE_STATUS,
            	J_Persons_in_Family_Household__c = 11,
            	J_Annual_Household_Income__c = 11111
        );
        insert charitable;

        J_Charitable__c charitable2 = new J_Charitable__c (
            	Care_Program_Enrollee__c = enrollee.Id,
               
                J_Enrollment_Start_Date__c = Date.today(),
                J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
            	J_Annual_Household_Income__c = 1111,
            	J_Persons_in_Family_Household__c = 12,
                J_CharitableStatus__c = J_ObjectUtils.CHARITABLE_CHARITABLE_STATUS_PL_IN_PROCESS
        );
        insert charitable2;

        Exception ex;

        try {
            charitable2.J_CharitableStatus__c = J_ObjectUtils.CHARITABLE_CHARITABLE_STATUS_PL_ACTIVE;
            update charitable2;
        } catch (Exception e) {
            ex = e;
        }

          // Assert an exception was thrown for the duplicate Charitable record
          System.assertNotEquals(null, ex, 'An exception should be thrown for duplicate Charitable record with the same dates.');
    }

    /**
     * @description Test method to verify that an exception is thrown when attempting to insert a second charitable record
     * with an overlapping enrollment start date for the same care program enrollee.
     * 
     * This test performs the following steps:
     * 1. Creates Territory records.
     * 2. Creates a Patient, Care Program, and Care Program Enrollee.
     * 3. Inserts a first charitable record with a future enrollment start date.
     * 4. Attempts to insert a second charitable record for the same enrollee, but with an overlapping enrollment start date.
     * 5. Asserts that an exception is thrown due to the conflicting dates.
     */
    @isTest
    static void datesOverlapCharitableInsertTest() {


         //Create Territory
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        iTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        iTerritory.add(territoryPEL);

        insert iTerritory;

        // Create Patient
        Account patient = J_TestUtils.createPatient();
        
        // Create Care Program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee for the patient
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);

        J_Charitable__c charitable = new J_Charitable__c (
            	Care_Program_Enrollee__c = enrollee.Id,
                
                J_Enrollment_Start_Date__c = Date.today().addDays(1),
                J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                J_CharitableStatus__c = CHARITABLE_STATUS,
            J_Persons_in_Family_Household__c = 11,
                J_Annual_Household_Income__c = 11111
        );
        insert charitable;

        Exception ex;

        try {
            J_Charitable__c charitable2 = new J_Charitable__c (
                    
                    Care_Program_Enrollee__c = enrollee.Id,
                    J_Enrollment_Start_Date__c = Date.today(),
                    J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                    J_CharitableStatus__c = CHARITABLE_STATUS
            );
            insert charitable2;
        } catch (Exception e) {
            ex = e;
        }

         // Assert an exception was thrown for the duplicate Charitable record
         System.assertNotEquals(null, ex, 'An exception should be thrown for duplicate Charitable record with the same dates.');
    }

    /**
     * @description Test method to verify that an exception is thrown when attempting to insert a charitable record with an active status 
     * that overlaps with an existing copay record for the same care program enrollee.
     * 
     * This test performs the following steps:
     * 1. Creates Territory records.
     * 2. Creates a Patient, Care Program, and Care Program Enrollee.
     * 3. Creates a Member Plan and Coverage Benefit.
     * 4. Inserts an active copay record for the enrollee.
     * 5. Attempts to insert a charitable record with the same enrollment start date as the copay record.
     * 6. Asserts that an exception is thrown due to the conflicting enrollment dates.
     */
    @isTest
    static void sameDateActiveCopayCharitableInsertTest() {
        //Account patient = J_TestUtils.queryAccount()[0];

         //Create Territory
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        iTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        iTerritory.add(territoryPEL);

        insert iTerritory;

        // Create Patient
        Account patient = J_TestUtils.createPatient();
        
        // Create Care Program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee for the patient
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);
         //Create MemberPlan
        MemberPlan mp = new MemberPlan(
            Name        ='MEMBER_PLAN_NAME',
            MemberId    = patient.Id,
            Status = 'Active',
            J_InsuranceType__c = 'Commercial',
            J_PolicyNumber__c = '001',
            J_Role__c = 'Primary'
            
        );
        insert mp;

          
        
         CoverageBenefit cb = new CoverageBenefit (
            Name            = 'COVERAGE_BENEFIT_PLAN_NAME',
            MemberPlanId    = mp.Id,
            //MemberId = patienten.Id,
            Care_Program_Enrollee__c = enrollee.id,
            J_CoverageBenefitStatus__c = 'Active'
        );
        insert cb;

        J_Copay__c copay = new J_Copay__c (
               
                Care_Program_Enrollee__c = enrollee.Id,
                Insurance_Plan__c = mp.id,
                J_EnrollmentStartDate__c = Date.today(),
                J_CurrentCopayStatus__c = J_ObjectUtils.COPAY_CURRENT_COPAY_STATUS_PL_ACTIVE
        );
        insert copay;

        Exception ex;

        try {
            J_Charitable__c charitable = new J_Charitable__c (
                    
                    Care_Program_Enrollee__c = enrollee.Id,
                    J_Enrollment_Start_Date__c = Date.today(),
                    J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                    J_CharitableStatus__c = J_ObjectUtils.CHARITABLE_CHARITABLE_STATUS_PL_ACTIVE
            );
            insert charitable;
            
        } catch (Exception e) {
            ex = e;
        }

          // Assert an exception was thrown for the duplicate Charitable record
          System.assertNotEquals(null, ex, 'An exception should be thrown for duplicate Charitable record with the same dates.');
    }

    /**
     * @description Test method to verify that an exception is thrown when attempting to insert a charitable record with an overlapping enrollment start date 
     * for a copay record that has an active status for the same care program enrollee.
     * 
     * This test performs the following steps:
     * 1. Creates Territory records.
     * 2. Creates a Patient, Care Program, and Care Program Enrollee.
     * 3. Creates a Member Plan and Coverage Benefit.
     * 4. Inserts an active copay record with a future enrollment start date.
     * 5. Attempts to insert a charitable record with an overlapping enrollment start date.
     * 6. Asserts that an exception is thrown due to the conflicting dates.
     */
    @isTest
    static void dateOverlapActiveCopayCharitableInsertTest() {
        //Account patient = J_TestUtils.queryAccount()[0];

         //Create Territory
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        iTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        iTerritory.add(territoryPEL);

        insert iTerritory;

        // Create Patient
        Account patient = J_TestUtils.createPatient();
        
        // Create Care Program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee for the patient
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);
         //Create MemberPlan
        MemberPlan mp = new MemberPlan(
            Name        ='MEMBER_PLAN_NAME',
            MemberId    = patient.Id,
            Status = 'Active',
            J_InsuranceType__c = 'Commercial',
            J_PolicyNumber__c = '001',
            J_Role__c = 'Primary'
            
        );
        insert mp;
  
        
         CoverageBenefit cb = new CoverageBenefit (
            Name            = 'COVERAGE_BENEFIT_PLAN_NAME',
            MemberPlanId    = mp.Id,
            //MemberId = patienten.Id,
            Care_Program_Enrollee__c = enrollee.id,
            J_CoverageBenefitStatus__c = 'Active'
        );
        insert cb;
        J_Copay__c copay = new J_Copay__c (
            	Care_Program_Enrollee__c = enrollee.Id,
                
                Insurance_Plan__c = mp.id,
                J_EnrollmentStartDate__c = Date.today().addDays(2),
                J_CurrentCopayStatus__c = J_ObjectUtils.COPAY_CURRENT_COPAY_STATUS_PL_ACTIVE
        );
        insert copay;

        Exception ex;

        try {
            J_Charitable__c charitable = new J_Charitable__c (
                    
                    Care_Program_Enrollee__c = enrollee.Id,
                    J_Enrollment_Start_Date__c = Date.today().addDays(1),
                    J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                    J_CharitableStatus__c = J_ObjectUtils.CHARITABLE_CHARITABLE_STATUS_PL_ACTIVE
            );
            insert charitable;
        } catch (Exception e) {
            ex = e;
        }

          // Assert an exception was thrown for the duplicate Charitable record
          System.assertNotEquals(null, ex, 'An exception should be thrown for duplicate Charitable record with the same dates.');
    }

    /**
     * @description Test to ensure that a duplicate Charitable record cannot be inserted with the same enrollment start date.
     */
        @isTest
    static void noDateOverlapCharitableInsertTest() {
        

         //Create Territory
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        iTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        iTerritory.add(territoryPEL);

        insert iTerritory;

        // Create Patient
        Account patient = J_TestUtils.createPatient();
        
        // Create Care Program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee for the patient
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);
        

        J_Charitable__c charitable = new J_Charitable__c (
            	Care_Program_Enrollee__c = enrollee.Id,
                
                J_Enrollment_Start_Date__c = Date.today(),
                J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                J_CharitableStatus__c = CHARITABLE_STATUS,
            J_Persons_in_Family_Household__c = 11,
            J_Annual_Household_Income__c = 11111
        );
        insert charitable;

        Exception ex;

        try {
            J_Charitable__c charitable2 = new J_Charitable__c (
                	Care_Program_Enrollee__c = enrollee.Id,
                    
                    J_Enrollment_Start_Date__c = Date.today().addMonths(13),
                    J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                    J_CharitableStatus__c = CHARITABLE_STATUS
            );
            insert charitable2;
        } catch (Exception e) {
            ex = e;
        }

          // Assert an exception was thrown for the duplicate Charitable record
          System.assertNotEquals(null, ex, 'An exception should be thrown for duplicate Charitable record with the same dates.');
    }

     /**
     * @description Test to ensure that a Charitable record cannot be updated to cause a date overlap with another record.
     */
    @isTest
    static void noDateOverlapCharitableUpdateTest() {
        //Account enrollee = J_TestUtils.queryAccount()[0];

         //Create Territory
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        iTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        iTerritory.add(territoryPEL);

        insert iTerritory;

        // Create Patient
        Account patient = J_TestUtils.createPatient();
        
        // Create Care Program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee for the patient
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);
        

        J_Charitable__c charitable = new J_Charitable__c (
            	Care_Program_Enrollee__c = enrollee.Id,
                
                J_Enrollment_Start_Date__c = Date.today(),
                J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
                J_CharitableStatus__c = CHARITABLE_STATUS,
            	J_Persons_in_Family_Household__c = 11,
            	J_Annual_Household_Income__c = 11111
        );
        insert charitable;

        J_Charitable__c charitable2 = new J_Charitable__c (
            	Care_Program_Enrollee__c = enrollee.Id,
               
                J_Enrollment_Start_Date__c = Date.today().addMonths(13),
                J_CharitableProgramType__c = J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP,
            	J_Annual_Household_Income__c = 1111,
            	J_Persons_in_Family_Household__c = 12,
                J_CharitableStatus__c = J_ObjectUtils.CHARITABLE_CHARITABLE_STATUS_PL_IN_PROCESS
        );
        insert charitable2;
		ContentVersion contentVersion = new ContentVersion(
                                            Title = 'TestFirstName TestLastName - PAP Enrollment Form',
                                            PathOnClient = 'estFirstName TestLastName - PAP Enrollment Form.pdf',
                                            VersionData = Blob.valueOf('Test Content'),
                                            IsMajorVersion = true
                                        );
        insert contentVersion;
        ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = testContent.ContentDocumentId;
        newLink.LinkedEntityId = charitable2.Id;
        insert newLink;
        
        Exception ex = null;

        try {
            charitable2.J_CharitableStatus__c = J_ObjectUtils.COPAY_CURRENT_COPAY_STATUS_PL_ACTIVE;
            update charitable2;
        } catch (Exception e) {
            ex = e;
        }

          // Assert an exception was thrown for the duplicate Charitable record
     System.assertNotEquals(charitable2, null, 'The result should not be null.');  
    }

     /**
     * @description Test to ensure that an exception is thrown when the file name of the enrollment form does not meet the expected naming convention.
     */
        @IsTest
    static void checkFileNameForEnrollmentFormIncorrectNameTest() {
        //Account enrollee = J_TestUtils.queryAccount()[0];

         //Create Territory
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        iTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        iTerritory.add(territoryPEL);

        insert iTerritory;

       // Create Patient
        Account patient = J_TestUtils.createPatient();
        
        // Create Care Program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee for the patient
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);
        

        J_Charitable__c charitable = new J_Charitable__c (
            Care_Program_Enrollee__c = enrollee.Id,
            
            J_CharitableStatus__c = 'In Process'
            //J_Enrollment_End_Date__c = Date.today()
        );
        insert charitable;
        ContentVersion contentVersion = new ContentVersion(
                                                Title = 'Test',
                                                PathOnClient = 'Test.jpg',
                                                VersionData = Blob.valueOf('Test Content'),
                                                IsMajorVersion = true
                                            );
        insert contentVersion;
        ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = testContent.ContentDocumentId;
        newLink.LinkedEntityId = charitable.Id;
        insert newLink;
        Exception ex;
        Test.startTest();
        try {
            charitable.J_CharitableStatus__c = 'Active';
            update charitable;
        }catch (Exception e) {
            ex = e;
        }
        Test.stopTest();
          // Assert an exception was thrown for the duplicate Charitable record
          System.assertNotEquals(null, ex, 'An exception should be thrown for duplicate Charitable record with the same dates.');
    }

	 /**
     * @description Test to ensure that a Charitable record can be updated successfully when the enrollment form file name follows the correct naming convention.
     */
        @IsTest
    static void checkFileNameForEnrollmentFormCorrectNameTest() {

         //Create Territory
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_CC
        );
        iTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'California',
            Name = J_TestUtils.TERRITORY_NAME_PEL
        );
        iTerritory.add(territoryPEL);

        insert iTerritory;

        //Create Patient
        Account patient = new Account(
            FirstName        = 'TestFirstName',
            LastName        = 'TestLastName',
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonMailingCity = 'Test City',
            PersonMailingState = 'California',
            PersonBirthdate = Date.today().addYears(-19),
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '00099'
        );
        insert patient;
        
        
         // Create a CareProgram record
		CareProgram cp = new CareProgram(
            Name = 'Test Care Program',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(1),
            Status = 'Active'
        );
		insert cp;

		// Create a CareProgramEnrollee record and set the lookup field to the CareProgram record created above
			CareProgramEnrollee enrollee = new CareProgramEnrollee(
                Name = 'Test Enrollee', 
                Status = 'Pending',
                Sub_Status__c='	New Enrollment',
                Clinical_trial_participant__c = 'Yes',
                AccountId = patient.Id,
                CareProgramId = cp.Id
        );
		insert enrollee;

        J_Charitable__c charitable = new J_Charitable__c (
            Care_Program_Enrollee__c = enrollee.Id,
            
            J_CharitableStatus__c = 'In Process'
            //J_Enrollment_End_Date__c = Date.today()
        );
        insert charitable;
        ContentVersion contentVersion = new ContentVersion(
                                            Title = 'TestFirstName TestLastName - PAP Enrollment Form',
                                            PathOnClient = 'estFirstName TestLastName - PAP Enrollment Form.pdf',
                                            VersionData = Blob.valueOf('Test Content'),
                                            IsMajorVersion = true
                                        );
        insert contentVersion;
        ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = testContent.ContentDocumentId;
        newLink.LinkedEntityId = charitable.Id;
        insert newLink;
        Test.startTest();
        Exception ex = null;
        try {
            charitable.J_CharitableStatus__c = 'Active';
            update charitable;
        }catch (Exception e) {
            ex = e;
        }
        Test.stopTest();
         // Assert an exception was thrown for the duplicate Charitable record
         System.assertNotEquals(charitable, null, 'The result should not be null.'); 
    }
    
}