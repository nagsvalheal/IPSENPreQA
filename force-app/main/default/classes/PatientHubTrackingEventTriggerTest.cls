/**
 * @description       : 
 * @author            : Ipsen   
 * @group             : 
 * @last modified on  : 11-17-2022
 * 
**/
@IsTest
public with sharing class PatientHubTrackingEventTriggerTest {
 	static final String ZIP_MAILING = '11111';
    static final String TERRITORY_TYPE_CC = 'CC';
    static final String TERRITORY_NAME_CC = 'territiryCC';
    public static final String ROLE_NAME_CC_USER = 'Care_Coordinator';
    public static final String PROFILE_NAME_STANDARD_JOURNEYS_USER = 'Standard Journeys User';


    @TestSetup
    static void makeData(){
        
        //Create Account
        Account patient = new Account(
            FirstName        = 'First Name',
            LastName        = 'Last Name',
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = 'Mailing',
            PersonMailingPostalCode = '11111',
            PersonMailingStreet = 'Test Street',
            PersonMailingCity = 'Test City',
            PersonMailingState = 'Arizona',
            PersonMailingCountry = 'United States'
        );

        insert patient;
        
        //Create Account2
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Journeys HCO').getRecordTypeId();
        Account patient2 = new Account(
            Name = 'Test',
            RecordTypeId    = AccountRecordTypeId,
            Patient_Type__c = 'US'
            //J_PrimaryAddress__c = 'Mailing'
            /*PersonMailingPostalCode = '10023',
            PersonMailingStreet = 'Test Street',
            PersonMailingCity = 'Test City',
            PersonMailingState = 'Arizona',
            PersonMailingCountry = 'United States'*/
        );
        insert patient2;
        
        //Create Contact
        Id contactRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Journey Contact').getRecordTypeId();
        Contact cont = new Contact(
        FirstName        = 'First Name',
            LastName        = 'Last Name',
            AccountId = patient2.id,
            RecordTypeId = contactRecordTypeId
        );
        insert cont;
        
        //Create Cre Program
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
        
        //Create Product
        Product2 prod = new Product2(
        Name = 'Sohonos',
            ProductCode = 'SO0001',
            NDC_Code__c = '15054001001',
            Description = 'SOHONOS (palovarotene capsules)',
            IsActive = True,
            Dosage__c = '1',
            QuantityUnitOfMeasure	 = 'Milligrams (mg)'
        );
        insert prod;
        
        //Create Care Program Product
        CareProgramProduct cpp = new CareProgramProduct(
        ProductId = prod.Id,
            Name = 'Test Care Program - Sohonos',
            Description__c = 'Palovarotene is a retinoic acid receptor gamma',
            CareProgramId = cp.id,
            Status = 'Active',
            Availability = 'All'
        );
        insert cpp;	
        
        //Create Care Pgm Enrollee Product
        CareProgramEnrolleeProduct cpep = new CareProgramEnrolleeProduct(
        CareProgramEnrolleeId = enrollee.id,
            CareProgramProductId = cpp.id,
            Status = 'Active'
        );
        insert cpep;
        
        //Create MemberPlan
        MemberPlan mp1 = new MemberPlan(
            MemberId = patient.id,
            Name = 'Insurance Plan',
            J_Role__c = 'Primary',
            Status = 'Active',
            J_PolicyNumber__c = 'KP12345678901',
            J_InsuranceType__c = 'Commercial'
            
        );
        insert mp1;  
        
        
        CoverageBenefit cb = new CoverageBenefit();
            cb.Care_Program_Enrollee__c = enrollee.Id;
        	cb.MemberPlanId = mp1.id;
            cb.Name = 'Coverage Benefit';
        	cb.J_CoverageBenefitStatus__c = 'Active';
            cb.J_BenefitType__c = 'Medical benefit';
            cb.J_BenefitYear__c = 'N/A Monthly';
            cb.J_Outcome__c = 'Not Covered';
            cb.J_Outcome_Summary__c = 'Test';
            cb.J_Deductible__c = 23;
            cb.J_DeductibleMet__c = 'Yes';
            cb.J_DeductibleIncludeinOOPMax__c = 'Yes';
            cb.J_OOPMax__c = 98;
            cb.J_OOPMet__c = 'Yes';
            cb.J_CoPay__c = 23;
            cb.J_CoInsurance__c = 65;
            cb.J_RxDEDPartofMajorMedical__c = 'Yes';
            cb.J_RxDEDCombinedwithMajorMedical__c = 'Yes';
            cb.J_AccumulatorAdjustmentPlan__c = 'Yes';
            cb.J_AnnualMax__c = 'Yes';
        	cb.J_AnnualMaxAmount__c = 230;
        	cb.J_PriorAuthorizationRequired__c = 'Yes';
        	cb.J_Prior_Authorization_Requirement__c = 'Test';
        insert cb;
        
        CarePreauth preauth = new CarePreauth();
        	preauth.Name = 'Care Preauth';
        	preauth.MemberPlanId = mp1.id;
        	preauth.Status = 'Active';
        	preauth.J_AuthorizationEndDate__c = Date.today().addDays(1);
        	preauth.J_CoverageBenefit__c = cb.Id;
        insert preauth;
        
        //Create AuthorizationForm
        AuthorizationForm af = new AuthorizationForm(Name = 'Journeys Authorization Form');
        insert af; 
        
        //Create AuthorizationFormText
        AuthorizationFormText aft = new AuthorizationFormText(AuthorizationFormId = af.id,
                                                              Name = 'Journeys Authorization Form Text',
                                                              SummaryAuthFormText = 'Summary Authorization Form Text',
                                                              IsActive = true,
                                                              Locale = 'en_US'
                                                             );
        insert aft;
        
        AuthorizationFormConsent afc = new AuthorizationFormConsent(Name = 'Patient Authorization',
                                                                    ConsentGiverId = enrollee.id,
                                                                    Care_Program_Enrollee__c = enrollee.id,
                                                                    AuthorizationFormTextId = aft.id,
                                                                    J_TypeOfConsent__c = 'Patient Authorization',
                                                                    J_ConsentStatus__c = 'Active',
                                                                    J_EnrollmentFormAttached__c = true,            
                                                                    Consented_by_others__c = 'No',
                                                                    ConsentCapturedDateTime = Date.today(),
                                                                    J_ConsentExpirationDate__c = Date.today()+10,
                                                                    Signature_of_Patient_or_Parent_LG_PHI__c = True,
                                                                    Signatured_Date_PHI__c = Date.today(),
                                                                    //Consented_Caregiver__c = encare.id,
                                                                    J_Email__c = 'Opt-in',
                                                                    J_Mail__c = 'Opt-in',
                                                                    J_SMS__c  = 'Opt-in',
                                                                    J_Meetings__c = 'Opt-in',
                                                                    J_Phone__c = 'Opt-in',
                                                                    J_MarketingMeterial__c = 'Opt-in'    
                                                                   );
        insert afc;
        
        Consent_Doc__c cd = new Consent_Doc__c (Authorization_Form_Consent__c = afc.id, Name='Patient Authorization Document');
        Insert cd;

		Id caseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId();
        
		Case cs = new Case(
        	
            RecordTypeId = caseRecordTypeId,
            Care_Program_Enrollee__c = enrollee.id,
            Disease__c = '',
            Status = 'New'
        );
        insert cs;
        
        
        
        MemberPlan mp2 = new MemberPlan(
        MemberId = patient.id,
            
            Name = 'Insurance Plan',
            J_Role__c = 'Secondary'
            
            
        );
        insert mp2;  
        
        J_Charitable__c PAP = new J_Charitable__c(
        	Care_Program_Enrollee__c = enrollee.Id,
            
            J_CharitableStatus__c = 'Active',
            J_CharitableProgramType__c = 'TPAP',
            J_Enrollment_Start_Date__c = Date.Today()
        );
        insert PAP;
        
        CodeSetBundle csb = new CodeSetBundle(
        Name = 'Sohonos'
        );
        insert csb;
        
        PatientMedicationDosage pmd = new PatientMedicationDosage(
            Treatment_Plan__c = cs.id,
        	Care_Program_Enrollee_Name__c = enrollee.id,
            Care_Program_Enrollee_Product__c = cpep.id,
            Current_Dose_Record__c = True,
            Patients_Current_Prescribed_Dose__c = '5',
            Prescribing_Physician__c = cont.id,
            DosageDefinitionType = 'Chronic',
            MD_Prescription_Date__c = system.today()
        );
        insert pmd;

        T_Hub_Tracking__c hub = new T_Hub_Tracking__c();
        	
        	hub.Primary_Prior_Authorization_Required__c = 'Y';
        	hub.PRIMARY_BENEFIT_TYPE__c = cb.J_BenefitType__c;
        	hub.PRIMARY_COPAY_AMOUNT__c = cb.J_CoPay__c;
        	hub.FINAL_PATIENT_OUT_OF_POCKET_COST__c = cb.J_OOPMax__c;
        	hub.PHI_Consent__c = 'Y';
        	hub.Consent_Expiration_Date__c = String.valueOf(afc.J_ConsentExpirationDate__c);
        	hub.HIPPA_Consent__c = 'Y';
        	hub.HIPPA_Consent_Date__c = String.valueOf(afc.J_ConsentExpirationDate__c);
        insert hub;
    }
    
    @IsTest
    static void test1(){
    
        Account acc = [Select id from account LIMIT 1];
        CareProgramEnrollee enr = [Select id from CareProgramEnrollee LIMIT 1];
        Test.startTest();
        PatientHubTrackingEventTriggerHandler.populateHubTracking(enr.id, acc.Id);
        Test.stopTest();
        
    }
        
    

    @IsTest
    static void testProcess(){
        /*List<String> accountIds = new List<String>();
        for(Account acc: [SELECT Id from Account]){
            accountIds.add(acc.Id);
        }*/
        
        List<CareProgramEnrollee> enrolleeIds = new List<CareProgramEnrollee>();
        for(CareProgramEnrollee enr: [SELECT Id, AccountId  from CareProgramEnrollee LIMIT 1]){
            enrolleeIds.add(enr);
        }
        
        Test.startTest();	
        
        PatientHubTrackingEventTriggerHandler.triggerEvent(enrolleeIds);
 
        Test.stopTest();
        
        
    }
}