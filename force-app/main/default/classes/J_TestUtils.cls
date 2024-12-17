/**
*   @author         Arkadii Sychov
*   @date           10/25/20
*   @description    Class contains common constants and methods for unit tests
**/
public without sharing class J_TestUtils {
    
    // Constants for patient and address data
    public static final String PATIENT_LAST_NAME = 'patient_test';
    public static final String ACCOUNT_PRIMARY_ADDRESS_MAILING = 'Mailing';
    public static final String ACCOUNT_PRIMARY_ADDRESS_OTHER = 'Other';
    public static final String STREET_MAILING = '123 Street';
    public static final String CITY_MAILING = 'Mailing City';
    public static final String STATE_MAILING = 'New York';
    public static final String ZIP_MAILING = '11111';
    public static final String ZIP_MAILING_NOT_EXISTED = '11112';
    public static final String COUNTRY_MAILING = 'United States';
    
    // Territory constants
    public static final String TERRITORY_TYPE_CC = 'CC';
    public static final String TERRITORY_TYPE_PEL = 'PEL';
    public static final String TERRITORY_NAME_CC = 'territoryCC';
    public static final String TERRITORY_NAME_CC_DEF = 'territoryCCDef';
    public static final String TERRITORY_NAME_PEL = 'territoryPEL';
    public static final String TERRITORY_NAME_PEL_DEF = 'territoryPELDef';
    
    // Test user constants
    public static final String USERNAME_TEST_CC = 'abcdTestCC@testorg.com';
    public static final String USERNAME_TEST_PEL = 'abcdTestPEL@testorg.com';
    
    // Method to create test user with a specified permission set group API name
    public static User createTestJourneysUser() {
        // Get the base URL of the Salesforce Org
        String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
        UserRole role = [SELECT Id FROM UserRole WHERE DeveloperName = 'Journeys_Manager'];
        // Parse the instance from the URL to ensure a unique username
        String orgInstance = baseUrl.substringAfter('https://').substringBefore('.');
        String uniqueUserName = 'testUser_' + DateTime.now().getTime() + '_' + Math.random() + '@' + orgInstance + '.com';
        
        // Create the User object with the necessary fields
        User userDetails = new User(
            Alias = 'jStand',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueUserName,
            UserRoleId = role.Id
        );
        
        // Check if the LastName field is creatable before inserting the user
        if (Schema.sObjectType.User.fields.LastName.isCreateable()) {  
            insert userDetails;
        } else {
            throw new DmlException('Insufficient permissions to create a User record.');
        }
        return userDetails;
    }
    
    // Method to query accounts in the org
    public static List<Account> queryAccount() {
        return [
            SELECT Id
            FROM Account WITH SECURITY_ENFORCED LIMIT 20
        ];
    }
    
    // Create Patient Account
    public static Account createPatient() {
        Account patient = new Account(
            FirstName = 'TestFirstName',
            LastName = PATIENT_LAST_NAME,
            RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = ZIP_MAILING,
            PersonMailingStreet = STREET_MAILING,
            PersonMailingState = STATE_MAILING,
            PersonMailingCity = CITY_MAILING,
            PersonBirthdate = Date.today().addYears(-19),
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '00099'
        );
        insert patient;
        return patient;
    }
    
    // Create Care Program
    public static CareProgram createCareProgram() {
        CareProgram cp = new CareProgram(
            Name = 'Test Care Program',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(1),
            Status = 'Active'
        );
        insert cp;
        return cp;
    }
    
    
    /**
     * @description Creates a Lead record with the specified Care Program and other required fields.
     * @param careProgramId The ID of the Care Program associated with the Lead.
     * @return The inserted Lead record.
     */
    public static Lead createLead(String recordTypeName, Id careProgramId) {
        String uniqueLastName = 'LastName_' + DateTime.now().getTime(); // Ensure uniqueness
        Lead leadRecord = new Lead(
            FirstName = 'TestName',
            LastName = uniqueLastName,
           J_Date_of_Birth__c = Date.today().addYears(-25),
            Street = 'Address 1',
            State = 'California',
            PostalCode = '65434',
            Care_Program__c = careProgramId,
            City = 'City1',
            J_Cell_Phone__c = '1234567890',
            Preferred_Phone__c = 'Cell',
            J_Prescriber_Preferred_Method_of_Contact__c = 'Phone',
            J_Sex__c = 'Male',
            RecordTypeId = J_ObjectUtils.getRecordTypeId(recordTypeName, 'LEAD') // Fetch RecordTypeId dynamically
        );
        insert leadRecord;
        return leadRecord;
    }
    
    // Create Care Program Enrollee
    public static CareProgramEnrollee createCareProgramEnrollee(Id patientId, Id careProgramId) {
        CareProgramEnrollee enrollee = new CareProgramEnrollee(
            Name = 'Test Enrollee', 
            Status = 'Pending',
            Sub_Status__c = 'New Enrollment',
            Clinical_trial_participant__c = 'Yes',
            AccountId = patientId,
            CareProgramId = careProgramId
        );
        insert enrollee;
        return enrollee;
    }
    
    // Create Member Plan
    public static MemberPlan createMemberPlan(Id patientId) {
        MemberPlan mp = new MemberPlan(
            Name = 'MEMBER_PLAN_NAME',
            MemberId = patientId,
            Status = 'Active',
            J_InsuranceType__c = 'Commercial',
            J_PolicyNumber__c = '001',
            J_Role__c = 'Primary'
        );
        insert mp;
        return mp;
    }
    
    // Create Coverage Benefit
    public static CoverageBenefit createCoverageBenefit(Id enrolleeId, Id memberPlanId) {
        CoverageBenefit cb = new CoverageBenefit(
            Name = 'COVERAGE_BENEFIT_PLAN_NAME',
            MemberPlanId = memberPlanId,
            Care_Program_Enrollee__c = enrolleeId,
            J_CoverageBenefitStatus__c = 'Active',
            J_BenefitsStartDate__c = Date.today(),
            J_DateBenefitVerified__c = Date.today().addYears(-19),
            J_Prior_Authorization_Requirement__c = 'Pending Authorization'
        );
        insert cb;
        return cb;
    }
    
    public static CarePreauth createCarePreauth(Id memberPlanId, Id coverageBenefitid){
        CarePreauth pa = new CarePreauth(
            Name = 'PA',
            MemberPlanId = memberPlanId,
            Status = 'Inactive',
            J_DoseSpecific__c = '2',
            Outcome__c = 'Expiring',
            J_CoverageBenefit__c = coverageBenefitid
        );
        insert pa;
        return pa;
    }


    public static Account CreateAccountCaregiver(){
    Account caregiver = new Account(FirstName   = 'caregiver',
                                        LastName  = 'caregiverLastName',
                                        Phone = '123-456-7890',
                                        RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_CAREGIVER_NAME, true),
                                        J_Status__c = 'Active'
                                       );
        insert caregiver;
        return caregiver;
    }

    public static Enrollee_Caregiver__c  CreateEnrolleeCaregiver(Id caregiverId,Id CareProgramEnrolleeId){
        Enrollee_Caregiver__c ec = new Enrollee_Caregiver__c(
            Name = 'Caregiver Test',
            Care_Program_Enrollee__c = CareProgramEnrolleeId,
            Caregiver__c = caregiverId,
            Consented_Caregiver__c = True,
            Status__c = 'Active',
            Relationship__c = 'Parent'
            
        );
        insert ec;
        return ec;
    }
}