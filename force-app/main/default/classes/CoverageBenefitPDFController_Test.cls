@isTest
public class CoverageBenefitPDFController_Test {
    
    @testSetup 
    static void setupData()
    {
        Account patient = new Account(LastName = J_TestUtils.PATIENT_LAST_NAME,
                                      FirstName = 'patient_First',
                                      RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
                                      J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
                                      PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
                                      PersonMailingStreet = J_TestUtils.STREET_MAILING,
                                      PersonMailingCity = 'Coimbatore',
                                      PersonMailingCountry='Australia',
                                      PersonMailingState = 'Queensland',
                                      PersonBirthdate = Date.newInstance(2002, 12, 9),
                                      PersonEmail = 'test@test.com'
                                     );
        insert patient;
        
        // create a care program
        CareProgram CP = new CareProgram(Name = 'Care Program',
                                         StartDate = system.today(),
                                         Status = 'Active'
                                        );
        insert CP;
        
        // create enrollee
        CareProgramEnrollee CPEnrollee = new CareProgramEnrollee(Name = 'Enrollee Test',
                                                                 Status = 'Pending',
                                                                 Sub_Status__c='	New Enrollment',
                                                                 PA_Consent_Status__c = 'Active',
                                                                 CareProgramId = CP.id,
                                                                 Clinical_trial_participant__c = 'Yes',
                                                                 AccountId = patient.id
                                                                );
        insert CPEnrollee;
        
        //Required to create Patient Medication Dosage
        CodeSetBundle code = new CodeSetBundle(Name='Sohonos');
        insert code;
        
        //Contact
        
        Contact con = new Contact(FirstName = 'Test First',
                                  LastName = 'Test Last',
                                  MobilePhone = '9812873456', 
                                  J_NPI__c = '87436',
                                  J_TaxID__c = '111-22-1111',
                                  MailingStreet = 'Taxes Road ',
                                  MailingCity = 'Dimapur',
                                  MailingState = 'California',
                                  MailingPostalCode = '797113', 
                                  J_Primary_ICD_10_Code__c = 'PHY0001', 
                                  RecordTypeId = J_ObjectUtils.getRecordTypeId('Physician','Contact')
                                 );
        insert con;
        
        //prodct
        Product2 pro = new Product2(Name = 'prodcut name',
                                    ProductCode = '0987654321',  
                                    NDC_Code__c = '62856070430',
                                    Description = 'test',
                                    IsActive=true
                                   );
        insert pro;
        
        //care program  product
        CareProgramProduct careprogprd = new CareProgramProduct(Name ='CareProgramProductname',
                                                                ProductId = pro.id,
                                                                CareProgramId = CP.id,
                                                                Status = 'Active',
                                                                Description__c = 'test'
                                                                
                                                               ); 
        insert careprogprd;
        
        //CareProgramEnrolleeProduct
        CareProgramEnrolleeProduct cpprod = new CareProgramEnrolleeProduct(Name = 'PA text',
                                                                           CareProgramEnrolleeId = CPEnrollee.id,
                                                                           CareProgramProductId  = careprogprd.id,
                                                                           Status = 'Active'
                                                                          );
        insert cpprod;
        
        Case casee = new Case(Care_Program_Enrollee__c = CPEnrollee.id,
                              Status = 'On Treatment',
                              J_TherapyStartDate__c = system.today(),
                              J_TherapyEndDate__c = system.today()
                             );
        
        insert casee;
        
        //Dosing
        PatientMedicationDosage Dosing = new PatientMedicationDosage(Treatment_Plan__c = casee.Id,
                                                                     Prescribing_Physician__c = con.id, 
                                                                     Current_Dose_Record__c = TRUE,
                                                                     Care_Program_Enrollee_Name__c = CPEnrollee.id,
                                                                     Care_Program_Enrollee_Product__c = cpprod.id,
                                                                     Patients_Current_Prescribed_Dose__c ='1000.0000',
                                                                     
                                                                     MD_Prescription_Date__c = System.today(),
                                                                     DosageDefinitionType = 'Ordered'
                                                                    );
        insert Dosing;
        
        //Create Referal
        //J_Referral__c referral = new J_Referral__c(J_Physician__c = con.Id,J_Patient_Account__c = patient.id);
        //insert referral;
        
        //Create Order
        //J_Order__c order = new J_Order__c(J_Drug_Name__c = 'Sohonos',J_Referral__c = referral.id, J_Patient__c =patient.Id,J_NDC_Number__c = '1020202');
        //insert order;
        
        //Create MemberPlan
        MemberPlan mp = new MemberPlan(Name = 'MEMBER_PLAN_NAME',
                                       MemberId    = patient.Id,
                                       Status = 'Active',
                                       J_InsuranceType__c = 'Commercial',
                                       J_PolicyNumber__c = '001',
                                       J_Role__c = 'Primary'
                                      );
        insert mp;
        
        //Create CoverageBenefit
        CoverageBenefit cb = new CoverageBenefit ( Name = 'Coverage Benefit',
                                                  J_BenefitAdministratorPhone__c = '9812873456',
                                                  MemberPlanId    = mp.Id,
                                                  //MemberId = patient.Id,
                                                  Care_Program_Enrollee__c = CPEnrollee.id,
                                                  J_DateBenefitVerified__c =  System.today(),
                                                  J_BenefitsStartDate__c = Date.newInstance(2021, 12, 9),
                                                  J_Prior_Authorization_Requirement__c= 'yes, it does have requirement',
                                                  J_CoverageBenefitStatus__c = 'Active'
                                                 );
        insert cb;
        
    }
    static testmethod void TestCoverageBenefitPDFController(){
        
        CoverageBenefit cb = [select Id,Name from CoverageBenefit limit 1];
        test.startTest();
        PageReference pgRef = Page.CoverageBenefitPDF; 
        test.setCurrentPage(pgRef); //Set the page for Test Method
        ApexPages.currentPage().getParameters().put('id', cb.id);
        CoverageBenefitPDFController cbpdf = new CoverageBenefitPDFController();
        test.stopTest();
        
    }
    
}