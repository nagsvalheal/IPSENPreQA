@isTest
public class CoverageBenefitPDFControllerTest {
    
    /**
     * @description This method sets up the test data required for testing the CoverageBenefitPDFController. 
     * It creates a series of Salesforce records such as patient, care program, enrollee, physician, product, 
     * care program product, coverage benefit, and others necessary for the test.
     */
    @testSetup 
    static void setupData() {
        // Create patient account
        Account patient = J_TestUtils.createPatient();
        
        // Create care program
        CareProgram cp = J_TestUtils.createCareProgram();
        
        // Create care program enrollee
        CareProgramEnrollee cpEnrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.id);
        
        // Create a CodeSetBundle for Patient Medication Dosage reference
        CodeSetBundle code = new CodeSetBundle(Name='Sohonos');
        insert code;
        
        // Create physician contact for prescribing physician
        Contact con = new Contact(
            FirstName = 'Test First',
            LastName = 'Test Last',
            MobilePhone = '9812873456', 
            J_NPI__c = '87436',
            J_TaxID__c = '111-22-1111',
            MailingStreet = 'Taxes Road',
            MailingCity = 'Dimapur',
            MailingState = 'California',
            MailingPostalCode = '797113', 
            J_Primary_ICD_10_Code__c = 'PHY0001', 
            RecordTypeId = J_ObjectUtils.getRecordTypeId('Physician', 'Contact')
        );
        insert con;
        
        // Create product for the care program
        Product2 pro = new Product2(
            Name = 'product name',
            ProductCode = '0987654321',  
            NDC_Code__c = '62856070430',
            Description = 'test',
            IsActive = true
        );
        insert pro;
        
        // Create care program product
        CareProgramProduct careprogprd = new CareProgramProduct(
            Name = 'CareProgramProductname',
            ProductId = pro.id,
            CareProgramId = cp.id,
            Status = 'Active',
            Description__c = 'test'
        ); 
        insert careprogprd;
        
        // Create CareProgramEnrolleeProduct linked to the enrollee
        CareProgramEnrolleeProduct cpprod = new CareProgramEnrolleeProduct(
            Name = 'PA text',
            CareProgramEnrolleeId = cpEnrollee.id,
            CareProgramProductId = careprogprd.id,
            Status = 'Active'
        );
        insert cpprod;
        
        // Create case for the enrollee's treatment
        Case casee = new Case(
            Care_Program_Enrollee__c = cpEnrollee.id,
            Status = 'On Treatment',
            J_TherapyStartDate__c = System.today(),
            J_TherapyEndDate__c = System.today()
        );
        insert casee;
        
        // Create Patient Medication Dosage for the care program enrollee
        PatientMedicationDosage dosing = new PatientMedicationDosage(
            Treatment_Plan__c = casee.Id,
            Prescribing_Physician__c = con.id, 
            Current_Dose_Record__c = TRUE,
            Care_Program_Enrollee_Name__c = cpEnrollee.id,
            Care_Program_Enrollee_Product__c = cpprod.id,
            Patients_Current_Prescribed_Dose__c = '1000.0000',
            MD_Prescription_Date__c = System.today(),
            DosageDefinitionType = 'Ordered'
        );
        insert dosing;
        
        // Create a MemberPlan for the patient
        MemberPlan mp = J_TestUtils.createMemberPlan(patient.Id);
        
        // Create CoverageBenefit for the enrollee and member plan
        CoverageBenefit cb = J_TestUtils.createCoverageBenefit(cpEnrollee.id, mp.id);
        GenericLogger.debugLog('Coverage Benefit Created' + cb);
    }
    
    /**
     * @description This test method verifies the functionality of the CoverageBenefitPDFController. 
     * It checks whether the controller can retrieve the correct CoverageBenefit record and 
     * generates the PDF page reference for that coverage benefit.
     */
    @isTest
    static void testCoverageBenefitPDFController() {
        // Retrieve the CoverageBenefit record to use in the test
        CoverageBenefit cb = [SELECT Id, Name FROM CoverageBenefit LIMIT 1];
        
        // Start test context to measure execution time and ensure proper test setup
        Test.startTest();
        
        // Set the current page context to the CoverageBenefitPDF page
        PageReference pgRef = Page.CoverageBenefitPDF; 
        Test.setCurrentPage(pgRef); // Set the page for Test Method
        
        // Pass the CoverageBenefit Id as a parameter to the page
        ApexPages.currentPage().getParameters().put('id', cb.Id);
        
        // Instantiate the CoverageBenefitPDFController
        CoverageBenefitPDFController cbpdf = new CoverageBenefitPDFController();
        
        // Stop the test context
        Test.stopTest();
        
        // Assert that the CoverageBenefit ID retrieved in the controller matches the one passed in the parameter
        System.assertEquals(cb.Id, cbpdf.ic.Id, 'CoverageBenefit ID should match the provided parameter');
    }
}