@isTest
public class EnrolleeHCPTriggerHandlerTest {

    static final String PATIENT_FIRST_NAME = 'patient_test';
    static final String STATE_MAILING = 'Arkansas';
    static final String CITY_MAILING = 'CITY'; 
    
    @isTest
    static void createEnrolleeHCPTest()
    {
        
        //Create Patient
        Account patient = new Account(
            FirstName	 = PATIENT_FIRST_NAME,
            LastName        = J_TestUtils.PATIENT_LAST_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonBirthdate = Date.today().addYears(-19),
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '00099',
            PersonMailingState= STATE_MAILING,
            PersonMailingCity = CITY_MAILING
        );
        insert patient; 
        Contact con = new Contact(FirstName = 'Test',
                                  LastName = 'afterinsertContact',
                                  //AccountId = patient.Id,
                                  J_Preferred_Contact_Method__c = 'Email',
                                  Email = 'test1434323@indegene.com',
                                  J_Contact_Type__c = '	Journeys Physician',
                                  RecordTypeId = '0125a000000VdCkAAK'
                                 );
        
        insert con;        
        
        // create a care program
        CareProgram cp = new CareProgram(Name = 'Care Program',
                                         StartDate = system.today(),
                                         Status = 'Active'
                                        );
        insert cp;
        
        // create enrollee
        CareProgramEnrollee cpEnrollee = new CareProgramEnrollee(Name = 'Enrollee Test',
                                                                 Status = 'Pending',
                                                                 Sub_Status__c='	New Enrollment',
                                                                 CareProgramId = cp.id,
                                                                 Clinical_trial_participant__c = 'Yes',
                                                                 AccountId = patient.id
                                                                );
        insert cpEnrollee;
        
        Enrollee_HCP__c enrolleeHcp = new Enrollee_HCP__c(Name = 'Enrollee Test - Care program',
                                                         HCP__c = con.Id,
                                                         Care_Program_Enrollee__c = cpEnrollee.Id,
                                                         Status__c = 'Active');
        
        Test.startTest();
		insert enrolleeHcp;        
        Test.stopTest();
        
    }
    
    @isTest
    static void checkEnrolleeHCPUpdate()
    {
         //Create Patient
        Account patient = new Account(
            FirstName	 = PATIENT_FIRST_NAME,
            LastName        = J_TestUtils.PATIENT_LAST_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonBirthdate = Date.today().addYears(-19),
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
            Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
            PersonHomePhone = '00099',
            PersonMailingState= STATE_MAILING,
            PersonMailingCity = CITY_MAILING
        );
        insert patient;
        
        Contact con = new Contact(FirstName = 'Test',
                                  LastName = 'afterinsertContact',
                                  //AccountId = patient.Id,
                                  J_Preferred_Contact_Method__c = 'Email',
                                  Email = 'test1434323@indegene.com',
                                  J_Contact_Type__c = '	Journeys Physician',
                                  RecordTypeId = '0125a000000VdCkAAK'
                                 );
        
        insert con;        
        
        // create a care program
        CareProgram cp = new CareProgram(Name = 'Care Program',
                                         StartDate = system.today(),
                                         Status = 'Active'
                                        );
        insert cp;
        
        // create enrollee
        CareProgramEnrollee cpEnrollee = new CareProgramEnrollee(Name = 'Enrollee Test',
                                                                 Status = 'Pending',
                                                                 Sub_Status__c='	New Enrollment',
                                                                 CareProgramId = cp.id,
                                                                 Clinical_trial_participant__c = 'Yes',
                                                                 AccountId = patient.id
                                                                );
        insert cpEnrollee;
        
        Enrollee_HCP__c enrolleeHcp = new Enrollee_HCP__c(Name = 'Enrollee Test - Care program',
                                                         HCP__c = con.Id,
                                                         Care_Program_Enrollee__c = cpEnrollee.Id,
                                                         Status__c = 'Inactive');
        
        insert enrolleeHcp;
        
        Test.startTest();
        enrolleeHcp.Status__c = 'Active';
        update enrolleeHcp;
        Test.stoptest();
        

    }
    
}