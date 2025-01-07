@isTest
public class PatientMedicationDosageTrigHandlrTest {
	@TestSetup
    static void makeData() {
        //Create Patient
        Account patient = new Account(
            LastName = J_TestUtils.PATIENT_LAST_NAME,
            FirstName = 'patient_last',
            RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonMailingCity = 'City',
            PersonMailingState = 'Kansas'
        );
        insert patient;
        
        // Required to create Patient Medication Dosage
        CodeSetBundle code = new CodeSetBundle(Name='Sohonos');
        insert code;    
                  
    }
    
    @IsTest
    static void insertPatientMedicationDosages() 
    {
        Account patient = [SELECT ID from Account LIMIT 1];
        
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
        
        Contact con = new Contact(FirstName = 'Test First',
                                  LastName = 'Test Last',
                                  //AccountId = patient.Id,
                                  J_Preferred_Contact_Method__c = 'Email',
                                  Email = 'test123@indegene.com',
                                  J_Contact_Type__c = 'Journeys Physician Assistant',
                                  J_Contact_SubType__c = 'Office Staff',
                                  RecordTypeId = J_ObjectUtils.getRecordTypeId('J_Journey_Physician','Contact')
                                 );
        
        insert con;        
        
        
        // create a care program
        CareProgram CPP = new CareProgram(Name = 'Care Program',
                                          StartDate = system.today(),
                                          Status = 'Active'
                                         );
        insert CPP;
        

        
        // create enrollee
        CareProgramEnrollee CPPEnrollee = new CareProgramEnrollee(Name = 'Enrollee Test',
                                                                  Status = 'Pending',
                                                                  Sub_Status__c='	New Enrollment',
                                                                  PA_Consent_Status__c = 'Active',
                                                                  CareProgramId = CPP.id,
                                                                  Clinical_trial_participant__c = 'Yes',
                                                                  AccountId = patienten.id
                                                                 );
        insert CPPEnrollee;
        
   //Create Enrollee HCP
        Enrollee_HCP__c HCP = new Enrollee_HCP__c(Name = 'Test',
                                    Status__c = 'Active', 
                                    Care_Program_Enrollee__c = CPPEnrollee.id,
                                    HCP__c = con.id
                                   );
        insert HCP;
        
        //prodct
        Product2 pro = new Product2(Name = 'prodcut name',
                                    ProductCode = '0987654321',  
                                    NDC_Code__c = '62856070430',
                                    Description = 'test',
                                    IsActive=true
                                   );
        insert pro;
        
        //care program enrollee product
        CareProgramProduct careprogprd = new CareProgramProduct(ProductId = pro.id,
                                                                CareProgramId = CPP.id,
                                                                Status = 'Active',
                                                                Description__c = 'test',
                                                                Name = 'Test'
                                                                
                                                               ); 
        insert careprogprd;
        
        //CareProgramEnrolleeProduct        
        CareProgramEnrolleeProduct cpprod = new CareProgramEnrolleeProduct(Name = 'Test',CareProgramEnrolleeId = CPPEnrollee.id,
                                                                           CareProgramProductId  = careprogprd.id,
                                                                           Status = 'Active'
                                                                          );
        insert cpprod;
        
        //Add Treatment plan
        Case casee = new Case(Care_Program_Enrollee__c = CPPEnrollee.id,
                              Status = 'On Treatment',
                              J_TherapyStartDate__c = system.today(),
                              J_TherapyEndDate__c = system.today()
                             );
        
        insert casee;
        
        
        // insert dosage;
        List<PatientMedicationDosage> dosageList = new List<PatientMedicationDosage>();
        PatientMedicationDosage dosage1 = new PatientMedicationDosage(Treatment_Plan__c = casee.Id,
                                                                      Patients_Current_Prescribed_Dose__c ='1000.0000',
                                                                      Care_Program_Enrollee_Name__c = CPPEnrollee.Id,
                                                                      Care_Program_Enrollee_Product__c = cpprod.id,                        
                                                                      MD_Prescription_Date__c = System.today(),
                                                                      DosageDefinitionType = 'Ordered',
                                                                      Enrollee_HCP__c = HCP.Id);
        dosageList.add(dosage1);
        PatientMedicationDosage dosage2 = new PatientMedicationDosage(Treatment_Plan__c = casee.Id,
                                                                      Patients_Current_Prescribed_Dose__c ='1000.0000',
                                                                      Care_Program_Enrollee_Name__c = CPPEnrollee.Id,
                                                                      Care_Program_Enrollee_Product__c = cpprod.id,                        
                                                                      MD_Prescription_Date__c = System.today(),
                                                                      DosageDefinitionType = 'Ordered',
                                                                      Enrollee_HCP__c = HCP.Id);
        dosageList.add(dosage2);
        insert dosageList;
    }
    
    @IsTest
    static void checkCurrentDoseRecordTest()
    {
        Account patient = [SELECT ID from Account LIMIT 1];

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
        
        Contact con = new Contact(FirstName = 'Test First',
                                  LastName = 'Test Last',
                                  //AccountId = patient.Id,
                                  J_Preferred_Contact_Method__c = 'Email',
                                  Email = 'test123@indegene.com',
                                  J_Contact_Type__c = 'Journeys Physician Assistant',
                                  J_Contact_SubType__c = 'Office Staff',
                                  RecordTypeId = J_ObjectUtils.getRecordTypeId('J_Journey_Physician','Contact')
                                 );
        
        insert con;        
        
        
        // create a care program
        CareProgram CPP = new CareProgram(Name = 'Care Program',
                                          StartDate = system.today(),
                                          Status = 'Active'
                                         );
        insert CPP;
        

        
        // create enrollee
        CareProgramEnrollee CPPEnrollee = new CareProgramEnrollee(Name = 'Enrollee Test',
                                                                  Status = 'Pending',
                                                                  Sub_Status__c='	New Enrollment',
                                                                  PA_Consent_Status__c = 'Active',
                                                                  CareProgramId = CPP.id,
                                                                  Clinical_trial_participant__c = 'Yes',
                                                                  AccountId = patienten.id
                                                                 );
        insert CPPEnrollee;
        
   //Create Enrollee HCP
        Enrollee_HCP__c HCP = new Enrollee_HCP__c(Name = 'Test',
                                    Status__c = 'Active', 
                                    Care_Program_Enrollee__c = CPPEnrollee.id,
                                    HCP__c = con.id
                                   );
        insert HCP;
        
        //prodct
        Product2 pro = new Product2(Name = 'prodcut name',
                                    ProductCode = '0987654321',  
                                    NDC_Code__c = '62856070430',
                                    Description = 'test',
                                    IsActive=true
                                   );
        insert pro;
        
        //care program enrollee product
        CareProgramProduct careprogprd = new CareProgramProduct(ProductId = pro.id,
                                                                CareProgramId = CPP.id,
                                                                Status = 'Active',
                                                                Description__c = 'test',
                                                                Name = 'Test'
                                                                
                                                               ); 
        insert careprogprd;
        //CareProgramEnrolleeProduct
        
        CareProgramEnrolleeProduct cpprod = new CareProgramEnrolleeProduct( Name = 'Test', CareProgramEnrolleeId = CPPEnrollee.id,
                                                                           CareProgramProductId  = careprogprd.id,
                                                                           Status = 'Active'
                                                                          );
        insert cpprod;
        
        Case casee = new Case(Care_Program_Enrollee__c = CPPEnrollee.id,
                              Status = 'On Treatment',
                              J_TherapyStartDate__c = system.today(),
                              J_TherapyEndDate__c = system.today()
                             );
        
        insert casee;
        
        List<PatientMedicationDosage> dosageList = new List<PatientMedicationDosage>();
        PatientMedicationDosage dosage1 = new PatientMedicationDosage(Treatment_Plan__c = casee.Id,
                                                                      Patients_Current_Prescribed_Dose__c ='1000.0000',
                                                                      Care_Program_Enrollee_Name__c = CPPEnrollee.Id,
                                                                      Care_Program_Enrollee_Product__c = cpprod.id,                        
                                                                      MD_Prescription_Date__c = System.today(),
                                                                      DosageDefinitionType = 'Ordered',
                                                                      Enrollee_HCP__c = HCP.id);
        dosageList.add(dosage1);
        
        PatientMedicationDosage dosage2 = new PatientMedicationDosage(Treatment_Plan__c = casee.Id,
                                                                      Patients_Current_Prescribed_Dose__c ='1000.0000',
                                                                      Care_Program_Enrollee_Name__c = CPPEnrollee.Id,
                                                                      Care_Program_Enrollee_Product__c = cpprod.id,                        
                                                                      MD_Prescription_Date__c = System.today()+1,
                                                                      DosageDefinitionType = 'Ordered',
                                                                      Enrollee_HCP__c = HCP.id);
        dosageList.add(dosage2);
        insert dosageList;
        
        try{
            update dosageList;
            dosageList[1].Current_Dose_Record__c = true;
            update dosageList;
            
            PatientMedicationDosage dosage3 = new PatientMedicationDosage(Treatment_Plan__c = casee.Id,
                                                                          Patients_Current_Prescribed_Dose__c='2000.0000',
                                                                          MD_Prescription_Date__c = System.today()+1,
                                                                          DosageDefinitionType= 'Flare',Current_Dose_Record__c = true);
            insert dosage3;
        }
        catch(Exception ex){
            System.debug(ex.getMessage());
        }
    }
    
     @IsTest
    static void AfterinsertTestmethod() 
    {
        Account patient = [SELECT ID from Account LIMIT 1];
        
        Account patienten = new Account(
            LastName = 'checkInsert',
            FirstName = 'patient_last',
            RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonMailingCity = 'City',
            PersonMailingState = 'Kansas'
        );
        insert patienten;
        
        Contact con = new Contact(FirstName = 'Test',
                                  LastName = 'afterinsertContact',
                                  //AccountId = patient.Id,
                                  J_Preferred_Contact_Method__c = 'Email',
                                  Email = 'test1434323@indegene.com',
                                  J_Contact_Type__c = 'Journeys Physician Assistant',
                                  J_Contact_SubType__c = 'Office Staff',
                                  RecordTypeId = J_ObjectUtils.getRecordTypeId('J_Journey_Physician','Contact')
                                 );
        
        insert con;        
        
        
        // create a care program
        CareProgram CPP = new CareProgram(Name = 'Care Program',
                                          StartDate = system.today(),
                                          Status = 'Active'
                                         );
        insert CPP;
        

        
        // create enrollee
        CareProgramEnrollee CPPEnrollee = new CareProgramEnrollee(Name = 'Enrollee Test434',
                                                                  Status = 'Pending',
                                                                  Sub_Status__c='	New Enrollment',
                                                                  PA_Consent_Status__c = 'Active',
                                                                  CareProgramId = CPP.id,
                                                                  Clinical_trial_participant__c = 'Yes',
                                                                  AccountId = patienten.id
                                                                 );
        insert CPPEnrollee;
        
   //Create Enrollee HCP
        Enrollee_HCP__c HCP = new Enrollee_HCP__c(Name = 'Test',
                                    Status__c = 'Active', 
                                    Care_Program_Enrollee__c = CPPEnrollee.id,
                                    HCP__c = con.id
                                   );
        insert HCP;
        
        //prodct
        Product2 pro = new Product2(Name = 'prodcut name',
                                    ProductCode = '09873234321',  
                                    NDC_Code__c = '64356070430',
                                    Description = 'test',
                                    IsActive=true
                                   );
        insert pro;
        
        //care program enrollee product
        CareProgramProduct careprogprd = new CareProgramProduct(ProductId = pro.id,
                                                                CareProgramId = CPP.id,
                                                                Status = 'Active',
                                                                Description__c = 'test3',
                                                                Name = 'Test3'
                                                                
                                                               ); 
        insert careprogprd;
        //CareProgramEnrolleeProduct
        
        CareProgramEnrolleeProduct cpprod = new CareProgramEnrolleeProduct(Name = 'Test32',CareProgramEnrolleeId = CPPEnrollee.id,
                                                                           CareProgramProductId  = careprogprd.id,
                                                                           Status = 'Active'
                                                                          );
        insert cpprod;
        
        Case casee = new Case(Care_Program_Enrollee__c = CPPEnrollee.id,
                              Status = 'On Treatment',
                              J_TherapyStartDate__c = system.today(),
                              J_TherapyEndDate__c = system.today()
                             );
        
        insert casee;
        
         Account pharmacyAccount = new Account(
            Name = 'CVS Pharmacy',
            RecordTypeId = J_ObjectUtils.getAccountRecordTypeId('Pharmacy', false),
            J_Email_payer__c = 'testpharmacy@test.com'          
        );
        insert pharmacyAccount;       
        
        // insert dosage;
        List<PatientMedicationDosage> dosageList = new List<PatientMedicationDosage>();
        PatientMedicationDosage dosage1 = new PatientMedicationDosage(Treatment_Plan__c = casee.Id,
                                                                      Patients_Current_Prescribed_Dose__c ='1000.0000',
                                                                      Care_Program_Enrollee_Name__c = CPPEnrollee.Id,
                                                                      Care_Program_Enrollee_Product__c = cpprod.id,                        
                                                                      MD_Prescription_Date__c = System.today(),
                                                                      DosageDefinitionType = 'Ordered',
                                                                      Specialty_Pharmacy__c = pharmacyAccount.Id,
                                                                      Current_Dose_Record__c = true,
                                                                      Enrollee_HCP__c = HCP.id);
        dosageList.add(dosage1);       
        insert dosageList;
    }
}