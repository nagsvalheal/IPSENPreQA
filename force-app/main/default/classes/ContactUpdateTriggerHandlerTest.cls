@isTest
public class ContactUpdateTriggerHandlerTest {

    @isTest
    static void testUpdatePhysicianEmail() {
        // Create a test account
        Account patienten = new Account(
            LastName = 'check',
            FirstName = 'patient_last',
            RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonMailingCity = 'City',
            PersonMailingState = 'Kansas'
        );
        insert patienten;
        
        // Required to create Patient Medication Dosage
        CodeSetBundle code = new CodeSetBundle(Name='Sohonos');
        insert code;

        // Create a test contact (physician)
        Contact con = new Contact(
            FirstName = 'Test First',
            LastName = 'Test Last',
            Email = 'test123@indegene.com',
            J_Contact_Type__c = 'Journeys Physician Assistant',
            J_Contact_SubType__c = 'Office Staff',
            RecordTypeId = J_ObjectUtils.getRecordTypeId('J_Journey_Physician', 'Contact')
        );
        insert con;

        // Create a care program
        CareProgram cProgram = new CareProgram(
            Name = 'Care Program',
            StartDate = Date.today(),
            Status = 'Active'
        );
        insert cProgram;

        // Create enrollee for the care program
        CareProgramEnrollee cpEnrollee = new CareProgramEnrollee(
            Name = 'Enrollee Test',
            Status = 'Pending',
            Sub_Status__c = 'New Enrollment',
            PA_Consent_Status__c = 'Active',
            CareProgramId = cProgram.Id,
            Clinical_trial_participant__c = 'Yes',
            AccountId = patienten.Id
        );
        insert cpEnrollee;

        // Create Enrollee HCP relationship
        Enrollee_HCP__c hcP = new Enrollee_HCP__c(
            Name = 'Test',
            Status__c = 'Active',
            Care_Program_Enrollee__c = cpEnrollee.Id,
            HCP__c = con.Id
        );
        insert hcP;
        
        //Add Treatment plan
        Case casee = new Case(Care_Program_Enrollee__c = cpEnrollee.id,
                              Status = 'On Treatment',
                              //J_TreatmentStatusSubCat__c = 'HCP not recommending',
                              J_TherapyStartDate__c = system.today(),
                              J_TherapyEndDate__c = system.today()
                             );
        
        insert casee;

        // Create a patient medication dosage related to the enrollee
        PatientMedicationDosage dosage1 = new PatientMedicationDosage(
            Treatment_Plan__c = casee.id,
            Patients_Current_Prescribed_Dose__c = '1000.0000',
            Care_Program_Enrollee_Name__c = cpEnrollee.Id,
            Enrollee_HCP__c = hcP.Id,
            Current_Dose_Record__c = true,
            DosageDefinitionType = 'Ordered'
        );
        insert dosage1;

        Test.startTest();

        // Simulate updating the physician's email
        con.Email = 'testEmailChange@test.com';
        update con;

        Test.stopTest();

        // Verify that the care program enrollee's provider email is updated
        CareProgramEnrollee updatedEnrollee = [SELECT ProviderEmail__c FROM CareProgramEnrollee WHERE Id = :cpEnrollee.Id];
        System.assertEquals('testemailchange@test.com', updatedEnrollee.ProviderEmail__c, 'The ProviderEmail__c field was not updated as expected.');

    }
}