@IsTest
public class CheckCaregiverRelationshipTest {

    @TestSetup
    static void makeData(){
        //Create Account
        Account patient = new Account(FirstName = 'TestFNameMerge',
                                      LastName = 'LastNameMerge'+datetime.now(),
                                      PersonBirthdate = system.today()-6666,
                                      RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
                                      J_PrimaryAddress__c = 'Mailing',
                                      PersonMailingPostalCode = '10023',
                                      PersonMailingStreet = 'Test Street',
                                      PersonMailingCity = 'Test City',
                                      PersonMailingState = 'Arizona',
                                      PersonMailingCountry = 'United States',
                                      Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE
                                     );
        insert patient;
        
        Account caregiver = new Account(FirstName   = 'caregiver',
                                        LastName        = 'caregiverLastName',
                                        Phone = '123-456-7890',
                                        RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_CAREGIVER_NAME, true),
                                        J_Status__c = 'Active'
                                       );
        insert caregiver;
        
        //Create Cre Program
        CareProgram cp = new CareProgram(Name = 'Test Care Program',
                                         StartDate = Date.today(),
                                         EndDate = Date.today().addDays(1),
                                         Status = 'Active'
                                        );
        insert cp;
        
        //Create CareProgramEnrollee
        CareProgramEnrollee cpe = new CareProgramEnrollee(Name = 'Test Enrollee',
                                                          CareProgramId = CP.id,
                                                          Status = 'Pending',
                                                          Sub_Status__c= 'New Enrollment',
                                                          PA_Consent_Status__c = 'Active',
                                                          AccountId = patient.id
                                                         );
        insert cpe;
    }
    
    @isTest
    public static void checkExistTest()
    {
        Account patient = [SELECT ID from Account WHERE FirstName = 'TestFNameMerge' LIMIT 1];
        Account caregiver = [SELECT ID from Account WHERE FirstName = 'caregiver' LIMIT 1];
        CareProgramEnrollee cpe = [select id from CareProgramEnrollee limit 1];
        
        //create Enrollee caregiver
        Enrollee_Caregiver__c ec = new Enrollee_Caregiver__c(
            Name = 'Caregiver Test',
            Care_Program_Enrollee__c = cpe.Id,
            Caregiver__c = caregiver.Id,
            Consented_Caregiver__c = True,
            Status__c = 'Active',
            Relationship__c = 'Parent'
            
        );
        insert ec;
        
        // Create a list of iCaregiverData objects
        List<CheckCaregiverRelationship.iCaregiverData> lstRequest = new List<CheckCaregiverRelationship.iCaregiverData>();
        CheckCaregiverRelationship.iCaregiverData caregiverData = new CheckCaregiverRelationship.iCaregiverData();
        caregiverData.iAccount = patient.id;
        caregiverData.iFirstName = 'caregiver';
        caregiverData.iLastName = 'caregiverLastName';
        caregiverData.iPhone = '123-456-7890';
        caregiverData.iRelationship = 'Child';
        lstRequest.add(caregiverData);
        
        // Call the CheckExist method
        List<Id> result = CheckCaregiverRelationship.CheckExist(lstRequest);

         // Assert results
         System.assertNotEquals(null, result, 'Result should not be null.');
         System.assertEquals(1, result.size(), 'Result should contain one record.');
         System.assertEquals(ec.Id, result[0], 'The returned ID should match the created Enrollee_Caregiver__c record.');
        
    }
}