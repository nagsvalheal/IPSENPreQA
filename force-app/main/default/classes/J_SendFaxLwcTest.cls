/**
 * @description       : Test class for the SendFaxLWC functionality, covering different scenarios related to retrieving enrollee ID, enrollee name,
 *                      and care program fax number.
 * @author            : Mickram
 * @group             : 
 * @last modified on  : 13-12-2024
 */
@isTest
public class J_SendFaxLwcTest {
    /**
     * @description       : Sets up the test data required for testing various scenarios in SendFaxLWC functionality.
     */
    @testSetup
    static void dataSetup(){
    //Create Account
        Account patient = new Account(
            FirstName        = 'First Name',
            LastName        = 'Last Name',
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = 'Mailing',
            PersonMailingPostalCode = '10023',
            PersonMailingStreet = 'Test Street',
            PersonMailingCity = 'Test City',
            PersonMailingState = 'Arizona',
            PersonMailingCountry = 'United States'
        );

        insert patient;
        
         patient.Patient_Status__pc = 'Active';
		update patient;
        
        // Required to create Patient Medication Dosage
        CodeSetBundle code = new CodeSetBundle(Name='Sohonos');
        insert code;  
    
        Contact con = new Contact(FirstName = 'Test First',
                                  LastName = 'Test Last',
                                  //AccountId = patient.Id,
                                  J_Preferred_Contact_Method__c = 'Email',
                                  Email = 'test123@indegene.com',
                                  J_Contact_Type__c = 'Journeys Physician Assistant',
                                  J_Contact_SubType__c = 'Office Staff',
                                  RecordTypeId = J_ObjectUtils.getRecordTypeId('Physician','Contact'),
                                  Fax = '17614567438'
                                 );
        
        insert con; 
        
        Account phar = new Account(
        	Name = 'Pharmacy',
            Fax = '4567892345'
        );
        insert phar;
        
    //Create MemberPlan
         MemberPlan mp = new MemberPlan(
             Name= 'Insurance Plan',
			 MemberId= patient.Id,
         	 Status = 'Active',
			 J_InsuranceType__c = 'Commercial',
			 J_PolicyNumber__c = '001',
			 J_Role__c = 'Secondary'
         );
         insert mp;
        
        //Create Care Program
        CareProgram cp = new CareProgram(
            Name = 'Test Care Program',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(1),
            Status = 'Active',
            Organisation_Fax_number__c = '17654334563'
        );
		insert cp;

		// Create a CareProgramEnrollee record and set the lookup field to the CareProgram record created above
			CareProgramEnrollee enrollee = new CareProgramEnrollee(
                Name = 'Test Enrollee', 
                Status = 'Pending',
                Clinical_trial_participant__c = 'Yes',
                AccountId = patient.Id,
                CareProgramId = cp.Id
        );
		insert enrollee;
        
        //Create Product
        Product2 prod = new Product2(Name = 'Activin A',
                                     ProductCode = '756567',
                                     NDC_Code__c = '87545839273',
                                     Description = 'This way, you will have separate test methods for insert and update scenarios',
                                     QuantityUnitOfMeasure = 'Milligrams (mg)',
                                     IsActive=true
                                    );
        insert prod;

		CareProgramProduct cpp = new CareProgramProduct(
            Name ='CareProgramProductname',
            Description__c='Test',
            Status='Active',
            CareProgramId=cp.Id,
            ProductId=prod.Id);
        insert cpp;
        
        //Create Care Program Enrollee Product
        CareProgramEnrolleeProduct cpep = new CareProgramEnrolleeProduct(
            Name ='CareProgramenrolleProductname', 
            CareProgramEnrolleeId = enrollee.Id,
			CareProgramProductId = cpp.Id,
			Status = 'Active'                                        
        );
        insert cpep; 
        
        //Create CoverageBenefit
         CoverageBenefit cb = new CoverageBenefit (
             Name= 'Coverage Benefit',
             Care_Program_Enrollee__c = enrollee.id,
             MemberPlanId = mp.id,
             J_CoverageBenefitStatus__c	 = 'Active'
         );
         insert cb;
        
        //Create Prior AUthorization
        	CarePreauth pa = new CarePreauth(
            	Name = 'PA',
                MemberPlanId = mp.id,
                Status = 'Inactive',
                J_DoseSpecific__c = '2',
                Outcome__c = 'In progress',
                Sub_Status__c = 'Awaiting HCP response',
                J_CoverageBenefit__c = cb.id,
                J_AuthorizationStartDate__c = system.today(),
                J_AuthorizationEndDate__c = system.today()+5,
                Care_Program_Enrollee__c = enrollee.id
            );
        insert pa;
        
        //Create Appeal
        	Appeal__c app = new Appeal__c(
            	Authorization__c = pa.id,
                Reason_for_appeal__c = 'Medical Exception Request',
                Appeal_note__c = 'Appeal Note'
            );
        insert app;
        
        //Create Copay
        	J_Copay__c co = new J_Copay__c(
            	Care_Program_Enrollee__c = enrollee.id,
                Insurance_Plan__c = mp.id,
                J_CurrentCopayStatus__c = 'Active',
                J_EnrollmentStartDate__c = system.today(),
                J_Journeys_Copay_ID__c = '2345678',
                J_CopayEnrollmentID__c = '12345',
                J_DeactivationDate__c = system.today()+10,
                J_EnrollmentEndDate__c = system.today()+5
            );
        insert co;
        
        //Create PAP
        	J_Charitable__c pap = new J_Charitable__c(
            	Care_Program_Enrollee__c = enrollee.id,
                J_CharitableProgramType__c = 'TPAP',
                J_CharitableStatus__c = 'In process',
                J_Persons_in_Family_Household__c = 2,
                J_Enrollment_Start_Date__c = system.today(),
                J_Enrollment_End_Date__c = system.today()+10
                
            );
        insert pap;
        
        //Create Case
        Id caseType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('CarePlan').getRecordTypeId();
        Case cas = new Case(
            RecordTypeId = caseType,
        	AccountId = patient.id,
            Status = 'New',
            J_TreatmentStatus__c = 'Not on Treatment',
            Care_Program_Enrollee__c = enrollee.id
        );
        insert cas;
        
        //Create PMDosage
        PatientMedicationDosage dosage = new PatientMedicationDosage(
        	Treatment_Plan__c = cas.id,
            Care_Program_Enrollee_Name__c = enrollee.id,
            Care_Program_Enrollee_Product__c = cpep.id,
            Patients_Current_Prescribed_Dose__c ='1000.0000',
            MD_Prescription_Date__c = System.today(),
            DosageDefinitionType = 'Ordered',
            Prescribing_Physician__c = con.Id,
            Current_Dose_Record__c = true,
            Specialty_Pharmacy__c = phar.id
            
        );
        insert dosage;
    }
    /**
     * @description       : Tests the functionality of retrieving enrollee ID using various related records.
     */
    @isTest
    static void testGetEnrolleeId() {
        Test.startTest();
        
        CareProgramEnrollee enr = [select id from CareProgramEnrollee];
        Case ae = [select id from Case];
        CoverageBenefit co = [select id from CoverageBenefit];
        CarePreauth pa = [select id from CarePreauth];
        Appeal__c app = [select id from Appeal__c];
        J_Copay__c cop = [select id from J_Copay__c];
        J_Charitable__c pap = [select id from J_Charitable__c];
        
        String enrResult = J_SendFaxLwc.getEnrolleeId(enr.id);
        J_SendFaxLwc.getEnrolleeId(ae.id);
        J_SendFaxLwc.getEnrolleeId(co.id);
        J_SendFaxLwc.getEnrolleeId(pa.id);
        J_SendFaxLwc.getEnrolleeId(app.id);
        J_SendFaxLwc.getEnrolleeId(cop.id);
        J_SendFaxLwc.getEnrolleeId(pap.id);
        System.assertNotEquals(null, enrResult, 'Enrollee ID should not be null for CareProgramEnrollee.');
        Test.stopTest();
    }
    /**
     * @description       : Tests the functionality of retrieving enrollee name using various related records.
     */

    @isTest
    static void testGetEnrolleeName() {
        Test.startTest();
        
        Case cas = [select id, Care_Program_Enrollee__c from Case];
        CoverageBenefit co = [select id, Care_Program_Enrollee__c from CoverageBenefit];
        CarePreauth pa = [select id, Care_Program_Enrollee__c from CarePreauth];
        Appeal__c app = [select id, Authorization__r.Care_Program_Enrollee__c from Appeal__c];
        J_Copay__c cop = [select id, Care_Program_Enrollee__c from J_Copay__c];
        J_Charitable__c pap = [select id, Care_Program_Enrollee__c from J_Charitable__c];
        
        String casEnrolleeName =  J_SendFaxLwc.getEnrolleeName(cas.id);
        System.assertNotEquals(null, casEnrolleeName, 'Enrollee Name should not be null for Case.');
        J_SendFaxLwc.getEnrolleeName(co.id);
        J_SendFaxLwc.getEnrolleeName(pa.id);
        J_SendFaxLwc.getEnrolleeName(app.id);
        J_SendFaxLwc.getEnrolleeName(cop.id);
        J_SendFaxLwc.getEnrolleeName(pap.id);
        
        Test.stopTest();
    }
/**
     * @description       : Tests the functionality of retrieving care program fax numbers using various related records.
     */
    @isTest
    static void testGetCpFaxNum() {
        
        Test.startTest();
        
        Case cas = [select id, Care_Program_Enrollee__c from Case];
        CoverageBenefit co = [select id, Care_Program_Enrollee__c from CoverageBenefit];
        CarePreauth pa = [select id, Care_Program_Enrollee__c from CarePreauth];
        Appeal__c app = [select id, Authorization__r.Care_Program_Enrollee__c from Appeal__c];
        J_Copay__c cop = [select id, Care_Program_Enrollee__c from J_Copay__c];
        J_Charitable__c pap = [select id, Care_Program_Enrollee__c from J_Charitable__c];
        
        String casFaxNum = J_SendFaxLwc.getCpFaxNum(cas.Id);
    System.assertNotEquals(null, casFaxNum, 'Fax Number should not be null for Case.');
    System.assert(casFaxNum.startsWith('+'), 'Fax Number should start with a "+" sign for Case.');

        J_SendFaxLwc.getCpFaxNum(co.id);
        J_SendFaxLwc.getCpFaxNum(pa.id);
        J_SendFaxLwc.getCpFaxNum(app.id);
        J_SendFaxLwc.getCpFaxNum(cop.id);
        J_SendFaxLwc.getCpFaxNum(pap.id);
        
        Test.stopTest();
        
    }
/**
 * Test class for validating the functionalities related to fax operations
 * including retrieving fax numbers, saving fax records, and managing related files.
 */
    @isTest
    static void testGetFaxNum() {
        Test.startTest();
        
        Case cas = [select id, Care_Program_Enrollee__c from Case];
        CoverageBenefit co = [select id, Care_Program_Enrollee__c from CoverageBenefit];
        CarePreauth pa = [select id, Care_Program_Enrollee__c from CarePreauth];
        Appeal__c app = [select id, Authorization__r.Care_Program_Enrollee__c from Appeal__c];
        J_Copay__c cop = [select id, Care_Program_Enrollee__c from J_Copay__c];
        J_Charitable__c pap = [select id, Care_Program_Enrollee__c from J_Charitable__c];
        
        String casFaxNum = J_SendFaxLwc.getFaxNum(cas.Id);
        System.assertNotEquals(null, casFaxNum, 'Fax Number should not be null for Case.');
    
        J_SendFaxLwc.getFaxNum(co.id);
        J_SendFaxLwc.getFaxNum(pa.id);
        J_SendFaxLwc.getFaxNum(app.id);
        J_SendFaxLwc.getFaxNum(cop.id);
        J_SendFaxLwc.getFaxNum(pap.id);
        
        Test.stopTest();
    }
/**
     * Test method to validate the functionality of the getPharFax method in the sendFaxLwc class.
     * Verifies that the pharmacy fax number for different objects is not null.
     */
    @isTest
    static void testGetPharFax() {
        Test.startTest();
        
        Case cas = [select id, Care_Program_Enrollee__c from Case];
        CoverageBenefit co = [select id, Care_Program_Enrollee__c from CoverageBenefit];
        CarePreauth pa = [select id, Care_Program_Enrollee__c from CarePreauth];
        Appeal__c app = [select id, Authorization__r.Care_Program_Enrollee__c from Appeal__c];
        J_Copay__c cop = [select id, Care_Program_Enrollee__c from J_Copay__c];
        J_Charitable__c pap = [select id, Care_Program_Enrollee__c from J_Charitable__c];
        
        String casPharFax = J_SendFaxLwc.getPharFax(cas.Id);
        System.assertNotEquals(null, casPharFax, 'Pharmacy Fax Number should not be null for Case.');
        
        J_SendFaxLwc.getPharFax(co.id);
        J_SendFaxLwc.getPharFax(pa.id);
        J_SendFaxLwc.getPharFax(app.id);
        J_SendFaxLwc.getPharFax(cop.id);
        J_SendFaxLwc.getPharFax(pap.id);
        
        Test.stopTest();
    }
/**
     * Test method to validate the functionality of the getRelatedFiles method in the sendFaxLwc class.
     * Verifies that related files are linked to the CareProgramEnrollee.
     */
    @isTest
    static void testGetRelatedFiles() {
		Test.startTest();
		CareProgramEnrollee enr = [select id from CareProgramEnrollee];

        ContentVersion content= new ContentVersion(); 
        content.Title='test crm patient - Benefit Investigation Summary (9).PDF'; 
        content.PathOnClient='/' + content.Title + '.PDF'; 
        content.VersionData = Blob.valueOf('Test Content');
        content.origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=enr.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        //contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
             
        insert contentlink;
        System.assertEquals(enr.id, contentlink.LinkedEntityId, 'The LinkedEntityId should match the Sent Fax record.');

    
        
		//sendFaxLwc.getRelatedFiles(enr.id);
 		Test.stopTest();	   
	}
/**
     * Test method to validate the functionality of the getRecFaxFiles method in the sendFaxLwc class.
     * Verifies that received fax files are correctly associated with the records.
     */
    @isTest
    static void testGetRecFaxFiles() {
        Test.startTest();  
       
        CareProgramEnrollee enr = [select id, CareProgramId from CareProgramEnrollee];
        
		//Create Received Fax
		Received_Fax__c rf = new Received_Fax__c(
			Fax_number_of_the_sender__c = '34567890987',
			Status__c = 'Received',
            Fax_number_of_the_recipient__c = '34567890987',
            Care_Program_Enrollee__c = enr.id,
            Care_Program__c = enr.CareProgramId
		);
		
		insert rf;
		
        ContentVersion content= new ContentVersion(); 
        content.Title='test crm patient - Benefit Investigation Summary (9).PDF'; 
        content.PathOnClient='/' + content.Title + '.PDF'; 
        content.VersionData = Blob.valueOf('Test Content');
        content.origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=rf.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.Visibility = 'AllUsers'; 
             
        insert contentlink;

        //Create Case
        Id caseType = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AE and PQC').getRecordTypeId();
        Case cas = new Case(
            RecordTypeId = caseType,
            Status = 'New',
            J_TreatmentStatus__c = 'Not on Treatment',
            Care_Program_Enrollee__c = enr.id
        );
        insert cas;
        
		Received_Fax__c rf1 = new Received_Fax__c(
			Fax_number_of_the_sender__c = '34567890987',
			Status__c = 'Received',
            Fax_number_of_the_recipient__c = '34567890987',
            AE_PQC__c = cas.id,
            Care_Program__c = enr.CareProgramId
		);
        insert rf1;
        
        ContentVersion content1= new ContentVersion(); 
        content1.Title='test crm patient - Benefit Investigation Summary (9).PDF'; 
        content1.PathOnClient='/' + content1.Title + '.PDF'; 
        content1.VersionData = Blob.valueOf('Test Content');
        content1.origin = 'H';
        insert content1;
        
        ContentDocumentLink contentlink1=new ContentDocumentLink();
        contentlink1.LinkedEntityId=rf1.id;
        contentlink1.contentdocumentid=[select contentdocumentid from contentversion where id =: content1.id].contentdocumentid;
        //contentlink1.ShareType = 'I';
        contentlink1.Visibility = 'AllUsers'; 
             
        insert contentlink1;
        
        CoverageBenefit cbe = [select id, Care_Program_Enrollee__r.CareProgramId from CoverageBenefit];
        
        //Create Received Fax for Coverage Benefit
        Received_Fax__c rf2 = new Received_Fax__c(
			Fax_number_of_the_sender__c = '34567890987',
			Status__c = 'Received',
            Fax_number_of_the_recipient__c = '34567890987',
            Coverage_Benefit__c = cbe.id,
            Care_Program__c = cbe.Care_Program_Enrollee__r.CareProgramId
		);
        insert rf2;
        
        ContentVersion content2= new ContentVersion(); 
        content2.Title='test crm patient - Benefit Investigation Summary (9).PDF'; 
        content2.PathOnClient='/' + content2.Title + '.PDF'; 
        content2.VersionData = Blob.valueOf('Test Content');
        content2.origin = 'H';
        insert content2;
        
        ContentDocumentLink contentlink2=new ContentDocumentLink();
        contentlink2.LinkedEntityId=rf1.id;
        contentlink2.contentdocumentid=[select contentdocumentid from contentversion where id =: content2.id].contentdocumentid;
        contentlink2.Visibility = 'AllUsers'; 
             
        insert contentlink2;
        
        CarePreauth cpr = [select id, Care_Program_Enrollee__r.CareProgramId from CarePreauth];
        //Create Received Fax for Prior Authorization
        Received_Fax__c rf3 = new Received_Fax__c(
			Fax_number_of_the_sender__c = '34567890987',
			Status__c = 'Received',
            Fax_number_of_the_recipient__c = '34567890987',
            Prior_Authorization__c = cpr.id,
            Care_Program__c = cpr.Care_Program_Enrollee__r.CareProgramId
		);
        insert rf3;
        
        ContentVersion content3= new ContentVersion(); 
        content3.Title='test crm patient - Benefit Investigation Summary (9).PDF'; 
        content3.PathOnClient='/' + content3.Title + '.PDF'; 
        content3.VersionData = Blob.valueOf('Test Content');
        content3.origin = 'H';
        insert content3;
        
        ContentDocumentLink contentlink3=new ContentDocumentLink();
        contentlink3.LinkedEntityId=rf3.id;
        contentlink3.contentdocumentid=[select contentdocumentid from contentversion where id =: content3.id].contentdocumentid;
        contentlink3.Visibility = 'AllUsers'; 
             
        insert contentlink3;
        
        Appeal__c appe = [select id, Care_Program_Enrollee__r.CareProgramId from Appeal__c];
        //Create Received Fax for Appeal
        Received_Fax__c rf4 = new Received_Fax__c(
			Fax_number_of_the_sender__c = '34567890987',
			Status__c = 'Received',
            Fax_number_of_the_recipient__c = '34567890987',
            Appeal__c = appe.id,
            Care_Program__c = appe.Care_Program_Enrollee__r.CareProgramId
		);
        insert rf4;
        
        ContentVersion content4= new ContentVersion(); 
        content4.Title='test crm patient - Benefit Investigation Summary (9).PDF'; 
        content4.PathOnClient='/' + content4.Title + '.PDF'; 
        content4.VersionData = Blob.valueOf('Test Content');
        content4.origin = 'H';
        insert content4;
        
        ContentDocumentLink contentlink4=new ContentDocumentLink();
        contentlink4.LinkedEntityId=rf3.id;
        contentlink4.contentdocumentid=[select contentdocumentid from contentversion where id =: content4.id].contentdocumentid;
        contentlink4.Visibility = 'AllUsers'; 
             
        insert contentlink4;
        
        J_Copay__c cop = [select id, Care_Program_Enrollee__r.CareProgramId from J_Copay__c];
        //Create Received Fax for Appeal
        Received_Fax__c rf5 = new Received_Fax__c(
			Fax_number_of_the_sender__c = '34567890987',
			Status__c = 'Received',
            Fax_number_of_the_recipient__c = '34567890987',
            Copay__c = cop.id,
            Care_Program__c = cop.Care_Program_Enrollee__r.CareProgramId
		);
        insert rf5;
        
        ContentVersion content5= new ContentVersion(); 
        content5.Title='test crm patient - Benefit Investigation Summary (9).PDF'; 
        content5.PathOnClient='/' + content5.Title + '.PDF'; 
        content5.VersionData = Blob.valueOf('Test Content');
        content5.origin = 'H';
        insert content5;
        
        ContentDocumentLink contentlink5=new ContentDocumentLink();
        contentlink5.LinkedEntityId=rf5.id;
        contentlink5.contentdocumentid=[select contentdocumentid from contentversion where id =: content5.id].contentdocumentid;
        //contentlink5.ShareType = 'I';
        contentlink5.Visibility = 'AllUsers'; 
             
        insert contentlink5;
        
        J_Charitable__c pap = [select id, Care_Program_Enrollee__r.CareProgramId from J_Charitable__c];
        //Create Received Fax for Appeal
        Received_Fax__c rf6 = new Received_Fax__c(
			Fax_number_of_the_sender__c = '34567890987',
			Status__c = 'Received',
            Fax_number_of_the_recipient__c = '34567890987',
            PAP_TPAP__c = pap.id,
            Care_Program__c = pap.Care_Program_Enrollee__r.CareProgramId
		);
        insert rf6;
         
        ContentVersion content6= new ContentVersion(); 
        content6.Title='test crm patient - Benefit Investigation Summary (9).PDF'; 
        content6.PathOnClient='/' + content6.Title + '.PDF'; 
        content6.VersionData = Blob.valueOf('Test Content');
        content6.origin = 'H';
        insert content6;
        
        ContentDocumentLink contentlink6=new ContentDocumentLink();
        contentlink6.LinkedEntityId=rf6.id;
        contentlink6.contentdocumentid=[select contentdocumentid from contentversion where id =: content6.id].contentdocumentid;
        contentlink6.Visibility = 'AllUsers'; 
             
        insert contentlink6;

    // Assertions
    System.assertEquals(rf6.id, contentlink6.LinkedEntityId, 'The LinkedEntityId should  be equal.');
    
        Test.stopTest();
    }

/**
     * Test method to validate the functionality of saving a sent fax record.
     * Verifies that a Sent Fax record can be inserted and linked to Content.
     */
    @isTest
    static void testSaveFax() {
        Test.startTest();
        
		CareProgramEnrollee enr = [select id from CareProgramEnrollee];

		Sent_Fax__c sf = new Sent_Fax__c(
			Fax_Number__c = '3456789875',
			Status__c = 'Sent',
			Care_Program_Enrollee__c = enr.id,
            Send_Date_Time__c = system.now(),
            Delivery_Date_Time__c = system.now(),
            To__c = 'Provider',
            Organisation_Fax_number__c = '456798765'
		);
	insert sf;
        
        ContentVersion content= new ContentVersion(); 
        content.Title='test crm patient - Benefit Investigation Summary (9).PDF'; 
        content.PathOnClient='/' + content.Title + '.PDF'; 
        content.VersionData = Blob.valueOf('Test Content');
        content.origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=sf.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.Visibility = 'AllUsers'; 
             
        insert contentlink;   
        System.assertEquals(sf.Id, contentlink.LinkedEntityId, 'The LinkedEntityId should match the Sent Fax record.');
         
        Test.stopTest();

    }
    
}