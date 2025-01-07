/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-10-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@IsTest
private class J_TestUtilsTest {



    @IsTest
    static void testCreatePatient() {
        Account patient = J_TestUtils.createPatient();
        System.assert(patient.Id != null, 'Patient record should be created successfully');
    }

    @IsTest
    static void testCreateCareProgram() {
        CareProgram cp = J_TestUtils.createCareProgram();
        System.assert(cp.Id != null, 'Care Program record should be created successfully');
    }
    
        @IsTest
static void testCreateLead() {
    // Create prerequisite data
    CareProgram cp = J_TestUtils.createCareProgram(); // Assuming this method is already implemented
    
    // Call the method to test
    String recordTypeName = J_ObjectUtils.LEAD_PATIENT_RECORD_TYPE;
    Lead lead = J_TestUtils.createLead(recordTypeName, cp.Id);

    // Assertions
    System.assertNotEquals(null, lead, 'Lead record should be created.');
    System.assertNotEquals(null, lead.Id, 'Lead record should have an Id.');
    System.assertEquals('TestName', lead.FirstName, 'Lead FirstName should match the expected value.');
    System.assert(lead.LastName.startsWith('LastName_'), 'Lead LastName should start with "LastName_" for uniqueness.');
    System.assertEquals(Date.today().addYears(-25), lead.J_Date_of_Birth__c, 'Lead Date of Birth should be set correctly.');
    System.assertEquals('Address 1', lead.Street, 'Lead Street should match the expected value.');
    System.assertEquals('California', lead.State, 'Lead State should match the expected value.');
    System.assertEquals('65434', lead.PostalCode, 'Lead PostalCode should match the expected value.');
    System.assertEquals(cp.Id, lead.Care_Program__c, 'Lead should be associated with the correct Care Program.');
    System.assertEquals('City1', lead.City, 'Lead City should match the expected value.');
    System.assertEquals('1234567890', lead.J_Cell_Phone__c, 'Lead Cell Phone should match the expected value.');
    System.assertEquals('Cell', lead.Preferred_Phone__c, 'Lead Preferred Phone should match the expected value.');
    System.assertEquals('Phone', lead.J_Prescriber_Preferred_Method_of_Contact__c, 'Lead Preferred Method of Contact should match the expected value.');
    System.assertEquals('Male', lead.J_Sex__c, 'Lead Sex should match the expected value.');
    System.assertEquals(
        J_ObjectUtils.getRecordTypeId(recordTypeName, 'LEAD'),
        lead.RecordTypeId,
        'Lead RecordTypeId should match the expected value.'
    );
}
    

    @IsTest
    static void testCreateCareProgramEnrollee() {
        Account patient = J_TestUtils.createPatient();
        CareProgram cp = J_TestUtils.createCareProgram();
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);
        System.assert(enrollee.Id != null, 'Care Program Enrollee record should be created successfully');
    }

    @IsTest
    static void testCreateMemberPlan() {
        Account patient = J_TestUtils.createPatient();
        MemberPlan mp = J_TestUtils.createMemberPlan(patient.Id);
        System.assert(mp.Id != null, 'Member Plan record should be created successfully');
    }

    @IsTest
    static void testCreateCoverageBenefit() {
        Account patient = J_TestUtils.createPatient();
        CareProgram cp = J_TestUtils.createCareProgram();
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);
        MemberPlan mp = J_TestUtils.createMemberPlan(patient.Id);
        CoverageBenefit cb = J_TestUtils.createCoverageBenefit(enrollee.Id, mp.Id);
        System.assert(cb.Id != null, 'Coverage Benefit record should be created successfully');
    }
    
       /**
     * @description Test the creation of a CarePreauth record.
     */
    @IsTest
    static void testCreateCarePreauth() {
        // Create test data
        Account patient = J_TestUtils.createPatient();
        CareProgram cp = J_TestUtils.createCareProgram();
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);
        MemberPlan memberPlan = J_TestUtils.createMemberPlan(patient.Id);
        CoverageBenefit coverageBenefit = J_TestUtils.createCoverageBenefit(enrollee.Id, memberPlan.Id);

        // Call the method to test
        CarePreauth carePreauth = J_TestUtils.createCarePreauth(memberPlan.Id, coverageBenefit.Id);

        // Assertions
        System.assertNotEquals(null, carePreauth, 'CarePreauth record should be created.');
        System.assertNotEquals(null, carePreauth.Id, 'CarePreauth should have an Id.');
        System.assertEquals('PA', carePreauth.Name, 'CarePreauth Name should match the expected value.');
        System.assertEquals('Inactive', carePreauth.Status, 'CarePreauth Status should match the expected value.');
        System.assertEquals('2', carePreauth.J_DoseSpecific__c, 'CarePreauth J_DoseSpecific__c should match the expected value.');
        System.assertEquals('Expiring', carePreauth.Outcome__c, 'CarePreauth Outcome__c should match the expected value.');
        System.assertEquals(coverageBenefit.Id, carePreauth.J_CoverageBenefit__c, 'CarePreauth should be linked to the correct Coverage Benefit.');
    }

    /**
     * @description Test the creation of a caregiver Account record.
     */
    @IsTest
    static void testCreateAccountCaregiver() {
        // Call the method to test
        Account caregiver = J_TestUtils.CreateAccountCaregiver();

        // Assertions
        System.assertNotEquals(null, caregiver, 'Caregiver Account record should be created.');
        System.assertNotEquals(null, caregiver.Id, 'Caregiver Account should have an Id.');
        System.assertEquals('caregiver', caregiver.FirstName, 'Caregiver FirstName should match the expected value.');
        System.assertEquals('caregiverLastName', caregiver.LastName, 'Caregiver LastName should match the expected value.');
        System.assertEquals('123-456-7890', caregiver.Phone, 'Caregiver Phone should match the expected value.');
        System.assertEquals('Active', caregiver.J_Status__c, 'Caregiver Status should match the expected value.');
        System.assertEquals(
            J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_CAREGIVER_NAME, true),
            caregiver.RecordTypeId,
            'Caregiver RecordTypeId should match the expected value.'
        );
    }

    /**
     * @description Test the creation of an Enrollee_Caregiver record.
     */
    @IsTest
    static void testCreateEnrolleeCaregiver() {
        // Create test data
        Account caregiver = J_TestUtils.CreateAccountCaregiver();
        Account patient = J_TestUtils.createPatient();
        CareProgram cp = J_TestUtils.createCareProgram();
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);

        // Call the method to test
        Enrollee_Caregiver__c enrolleeCaregiver = J_TestUtils.CreateEnrolleeCaregiver(caregiver.Id, enrollee.Id);

        // Assertions
        System.assertNotEquals(null, enrolleeCaregiver, 'Enrollee_Caregiver record should be created.');
        System.assertNotEquals(null, enrolleeCaregiver.Id, 'Enrollee_Caregiver should have an Id.');
        System.assertEquals(caregiver.Id, enrolleeCaregiver.Caregiver__c, 'Enrollee_Caregiver should be linked to the correct Caregiver.');
        System.assertEquals(enrollee.Id, enrolleeCaregiver.Care_Program_Enrollee__c, 'Enrollee_Caregiver should be linked to the correct Enrollee.');
        System.assertEquals(true, enrolleeCaregiver.Consented_Caregiver__c, 'Enrollee_Caregiver Consented_Caregiver__c should be True.');
        System.assertEquals('Active', enrolleeCaregiver.Status__c, 'Enrollee_Caregiver Status__c should be Active.');
        System.assertEquals('Parent', enrolleeCaregiver.Relationship__c, 'Enrollee_Caregiver Relationship__c should match the expected value.');
    }

    @IsTest
    static void testQueryAccount() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            testAccounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert testAccounts;

        // Query accounts
        List<Account> result = J_TestUtils.queryAccount();
        System.assert(result.size() == 10, 'Expected 10 accounts to be returned');
    }

  @isTest
    static void testCreateTestJourneysUser() {
        // Start a test execution context
        Test.startTest();
        
        // Call the method to create a test user
        User testUser = J_TestUtils.createTestJourneysUser();
        
        // Stop the test execution context
        Test.stopTest();
        
        // Assert that the user was created successfully
        System.assertNotEquals(null, testUser, 'The test user should be created.');
        System.assertNotEquals(null, testUser.Id, 'The test user should have an Id.');
        System.assertEquals('abcdTest', testUser.LastName, 'The user LastName should match the expected value.');
        System.assertEquals('standarduser@testorg.com', testUser.Email, 'The user Email should match the expected value.');
        System.assertEquals('en_US', testUser.LanguageLocaleKey, 'The user LanguageLocaleKey should be en_US.');
        System.assertEquals('en_US', testUser.LocaleSidKey, 'The user LocaleSidKey should be en_US.');
        System.assertEquals('America/Los_Angeles', testUser.TimeZoneSidKey, 'The user TimeZoneSidKey should be America/Los_Angeles.');
        System.assertEquals(
            J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER), 
            testUser.ProfileId, 
            'The user ProfileId should match the profile ID for the Journeys Standard User.'
        );
    }
}