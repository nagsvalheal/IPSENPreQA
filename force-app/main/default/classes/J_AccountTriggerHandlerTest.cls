/**
*   @author         Arkadii Sychov
*   @date           10/23/20
*   @description    Unit tests for J_AccountTrigger
*       IPSC-203, IPSC-198
**/
@isTest
public class J_AccountTriggerHandlerTest {
    static final String PATIENT_FIRST_NAME = 'patient_test';
    static final String PATIENT_LAST_NAME = 'patient_test';
    static final String MEMBER_PLAN_NAME = 'mp_test';
    static final String COVERAGE_BENEFIT_PLAN_NAME = 'cb_test';

    static final String CARE_PREAUTH_NAME_ACTIVE_1 = 'carePreauth active 1';
    static final String CARE_PREAUTH_NAME_ACTIVE_2 = 'carePreauth active 2';
    static final String CARE_PREAUTH_NAME_INACTIVE = 'carePreauth inactive';
    static final String CARE_PREAUTH_STATUS_ACTIVE = 'Active';
    static final String CARE_PREAUTH_STATUS_INACTIVE = 'Inactive';
    static final String ACCOUNT_PRIMARY_ADDRESS_MAILING = 'Mailing';
    static final String ACCOUNT_PRIMARY_ADDRESS_OTHER = 'Other';
    public static final string PHARMACY_ACCOUNT_TYPE = 'Pharmacy';

    static final String ZIP_MAILING = '11111';
    static final String ZIP_MAILING_NOT_EXISTED = '11112';
    static final String STATE_MAILING = 'Arkansas';
    static final String STREET_MAILING = 'Street';
    static final String CITY_MAILING = 'CITY';
    static final String TERRITORY_TYPE_CC = 'CC';
    static final String TERRITORY_TYPE_PEL = 'PEL';
    static final String TERRITORY_NAME_CC = 'territiryCC';
    static final String TERRITORY_NAME_CC_DEF = 'territiryCCDef';
    static final String TERRITORY_NAME_PEL = 'territiryPEL';
    static final String TERRITORY_NAME_PEL_DEF = 'territiryPELDef';
    static final String PHARMACY_EMAIL = 'isha.h@valuehealthsol.com';
    static final string PHARMACY_NAME = 'Test Pharmacy';

    @TestSetup
    static void makeData(){
        //Create Territory
        List<J_Territory__c> iTerritory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = ZIP_MAILING,
            J_TerritoryType__c = TERRITORY_TYPE_CC,
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'test 1',
            Name = TERRITORY_NAME_CC
        );
        iTerritory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = ZIP_MAILING,
            J_TerritoryType__c = TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'test 2',
            Name = TERRITORY_NAME_PEL
        );
        iTerritory.add(territoryPEL);

        J_Territory__c territoryCCDef = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = '',
            J_TerritoryType__c = TERRITORY_TYPE_CC,
            J_TerritoryCode__c = '',
            J_States__c = 'test 1',
            Name = TERRITORY_NAME_CC_DEF
        );
        iTerritory.add(territoryCCDef);

        J_Territory__c territoryPELDef = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = '',
            J_TerritoryType__c = TERRITORY_TYPE_PEL,
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'test 2',
            Name = TERRITORY_NAME_PEL_DEF
        );
        iTerritory.add(territoryPELDef);

        insert iTerritory;
    }

    @isTest
    static void assignTerritoryMailing() {
        //Create Account
        Account patient = new Account(
            FirstName	 = PATIENT_FIRST_NAME,
            LastName        = PATIENT_LAST_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonMailingCity = J_TestUtils.CITY_MAILING,	
            PersonMailingState = J_TestUtils.STATE_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingCountry=J_TestUtils.COUNTRY_MAILING
        );

        Test.startTest();
            insert patient;
        Test.stopTest();

        //Ensure that we have only one first active CarePreauth
        List<Account> iAccounts = [
            SELECT J_CCTerritory__c, J_CCTerritory__r.Name, J_PELTerritory__c, J_PELTerritory__r.Name
            FROM Account
        ];

        System.assertEquals(1, iAccounts.size(), 'found Account');
        System.assertEquals(TERRITORY_NAME_CC, iAccounts[0].J_CCTerritory__r.Name,  'found cc territory name');
        System.assertEquals(TERRITORY_NAME_PEL, iAccounts[0].J_PELTerritory__r.Name,  'found PEL territory name');
    }

    @isTest
    static void assignTerritoryOther() {
        //Create Account
        Account patient = new Account(
             FirstName	 = PATIENT_FIRST_NAME,
            LastName        = PATIENT_LAST_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = ACCOUNT_PRIMARY_ADDRESS_OTHER,
            PersonOtherPostalCode = ZIP_MAILING,
            PersonOtherStreet = STREET_MAILING,
            PersonOtherState= STATE_MAILING,
            PersonOtherCity = CITY_MAILING,
            PersonMailingPostalCode = ZIP_MAILING,
            PersonMailingStreet = STREET_MAILING,
            PersonMailingState= STATE_MAILING,
            PersonMailingCity = CITY_MAILING
        );

        Test.startTest();
            insert patient;
        Test.stopTest();

        //Ensure that we have only one first active CarePreauth
        List<Account> iAccounts = [
            SELECT J_CCTerritory__c, J_CCTerritory__r.Name, J_PELTerritory__c, J_PELTerritory__r.Name
            FROM Account
        ];

        System.assertEquals(1, iAccounts.size(), 'found Account');
        System.assertEquals(TERRITORY_NAME_CC, iAccounts[0].J_CCTerritory__r.Name, 'found cc territory name');
        System.assertEquals(TERRITORY_NAME_PEL, iAccounts[0].J_PELTerritory__r.Name, 'found PEL territory name');
    }

    @isTest
    static void assignTerritoryDefault() {
        //Create Account
        Account patient = new Account(
            FirstName	 = PATIENT_FIRST_NAME,
            LastName        = PATIENT_LAST_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = ZIP_MAILING_NOT_EXISTED,
            
            PersonMailingStreet = STREET_MAILING,
            PersonMailingState= STATE_MAILING,
            PersonMailingCity = 'City 1'
        );

        Test.startTest();
            insert patient;
        Test.stopTest();

        //Ensure that we have only one first active CarePreauth
        List<Account> iAccounts = [
            SELECT J_CCTerritory__c, J_CCTerritory__r.Name, J_PELTerritory__c, J_PELTerritory__r.Name
            FROM Account
        ];

        System.assertEquals(1, iAccounts.size(),  'found Account');
        System.assertEquals(TERRITORY_NAME_CC_DEF, iAccounts[0].J_CCTerritory__r.Name,  'found cc territory name');
        System.assertEquals(TERRITORY_NAME_PEL_DEF, iAccounts[0].J_PELTerritory__r.Name,  'found PEL territory name');
    }

    @isTest
    static void assignTerritoryUpdate() {
        //Create Account
        Account patient = new Account(
            FirstName	 = PATIENT_FIRST_NAME,
            LastName        = PATIENT_LAST_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = ACCOUNT_PRIMARY_ADDRESS_OTHER,
            PersonOtherPostalCode = ZIP_MAILING,
            PersonOtherStreet = STREET_MAILING,
            PersonOtherState= STATE_MAILING,
            PersonOtherCity = CITY_MAILING,
            PersonMailingPostalCode = ZIP_MAILING,
             PersonMailingStreet = STREET_MAILING,
            PersonMailingState= STATE_MAILING,
            PersonMailingCity = CITY_MAILING
        );
        insert patient;

        Test.startTest();
            patient.J_PrimaryAddress__c = ACCOUNT_PRIMARY_ADDRESS_MAILING;
            patient.PersonMailingPostalCode = ZIP_MAILING_NOT_EXISTED;
            patient.PersonMailingStreet = STREET_MAILING;
            update patient;
        Test.stopTest();

        //Ensure that we have only one first active CarePreauth
        List<Account> iAccounts = [
            SELECT J_CCTerritory__c, J_CCTerritory__r.Name, J_PELTerritory__c, J_PELTerritory__r.Name
            FROM Account
        ];

        System.assertEquals(1, iAccounts.size(),   'found Account');
        System.assertEquals(TERRITORY_NAME_CC_DEF, iAccounts[0].J_CCTerritory__r.Name,  'found cc territory name');
        System.assertEquals(TERRITORY_NAME_PEL_DEF, iAccounts[0].J_PELTerritory__r.Name,  'found PEL territory name');
    }
   
    @isTest
    static void testPharmacyEmail()
    { 
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
        
        // Required to create Patient Medication Dosage
        CodeSetBundle code = new CodeSetBundle(Name='Sohonos');
        insert code; 
        
        Contact con = new Contact(FirstName = 'Test',
                                  LastName = 'afterinsertContact',
                                  //AccountId = patient.Id,
                                  J_Preferred_Contact_Method__c = 'Email',
                                  Email = 'test1434323@indegene.com',
                                  J_Contact_Type__c = 'Journeys Physician Assistant',
                                  J_Contact_SubType__c = 'Office Staff',
                                  RecordTypeId = J_ObjectUtils.getRecordTypeId('Contact','J_Journey_Physician')
                                 );
        
        insert con;        
        
        
        // create a care program
        CareProgram cpp = new CareProgram(Name = 'Care Program',
                                          StartDate = system.today(),
                                          Status = 'Active'
                                         );
        insert cpp;
        
        // create enrollee
        CareProgramEnrollee cppEnrollee = new CareProgramEnrollee(Name = 'Enrollee Test434',
                                                                  Status = 'Pending',
                                                                  Sub_Status__c='	New Enrollment',
                                                                  PA_Consent_Status__c = 'Active',
                                                                  CareProgramId = cpp.id,
                                                                  Clinical_trial_participant__c = 'Yes',
                                                                  AccountId = patienten.id
                                                                 );
        insert cppEnrollee;
        
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
                                                                CareProgramId = cpp.id,
                                                                Status = 'Active',
                                                                Description__c = 'test3',
                                                                Name = 'Test3'
                                                                
                                                               ); 
        insert careprogprd;
        //CareProgramEnrolleeProduct
        
        CareProgramEnrolleeProduct cpprod = new CareProgramEnrolleeProduct(Name = 'Test32',CareProgramEnrolleeId = cppEnrollee.id,
                                                                           CareProgramProductId  = careprogprd.id,
                                                                           Status = 'Active'
                                                                          );
        insert cpprod;
        
        Case casee = new Case(Care_Program_Enrollee__c = cppEnrollee.id,
                              Status = 'On Treatment',
                              J_TherapyStartDate__c = system.today(),
                              J_TherapyEndDate__c = system.today()
                             );
        
        insert casee;
        
 		Account pharmacy = new Account(
            Name	 = PHARMACY_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(PHARMACY_ACCOUNT_TYPE, false),
            J_Email_payer__c= PHARMACY_EMAIL
        );      
        insert pharmacy;
        // insert dosage;
        
        List<PatientMedicationDosage> dosageList = new List<PatientMedicationDosage>();
        PatientMedicationDosage dosage1 = new PatientMedicationDosage(Treatment_Plan__c = casee.Id,
                                                                      Patients_Current_Prescribed_Dose__c ='1000.0000',
                                                                      Care_Program_Enrollee_Name__c = cppEnrollee.Id,
                                                                      Care_Program_Enrollee_Product__c = cpprod.id,                        
                                                                      MD_Prescription_Date__c = System.today(),
                                                                      DosageDefinitionType = 'Ordered',
                                                                      Specialty_Pharmacy__c = pharmacy.Id,
                                                                      Current_Dose_Record__c = true,
                                                                      Prescribing_Physician__c = con.Id);
        dosageList.add(dosage1);       
        insert dosageList;
        
        Test.startTest();
        pharmacy.J_Email_payer__c = 'testingemailchange@test.com';
        update pharmacy;
        
        Test.stopTest();

            // Assert that CareProgramEnrollee was updated with new Pharmacy email
    CareProgramEnrollee updatedCpe = [SELECT PharmacyEmail__c FROM CareProgramEnrollee WHERE Id = :cppEnrollee.Id];
    System.assertEquals('testingemailchange@test.com', updatedCpe.PharmacyEmail__c, 'Pharmacy email was not updated correctly.');
    
    // Assert that the Bypass_Apex__c field has been toggled
    updatedCpe = [SELECT Bypass_Apex__c FROM CareProgramEnrollee WHERE Id = :cppEnrollee.Id];
    System.assertNotEquals(null, updatedCpe.Bypass_Apex__c, 'Bypass_Apex__c should not be null after update.');
       
    }
    
    
}