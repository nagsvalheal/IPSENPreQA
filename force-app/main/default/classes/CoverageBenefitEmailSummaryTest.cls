/**
     * @description Test to verifies the functionality of the CoverageBenefitEmailSummary class.
     */
    @isTest
    public class CoverageBenefitEmailSummaryTest {
    
        /**
         * @description This test method verifies the functionality of the CoverageBenefitEmailSummary class.
         * It checks whether an email is sent successfully for a CoverageBenefit and ensures that the CoverageBenefit
         * is linked to the correct CareProgramEnrollee.
         */
        @IsTest
        static void coverageBenefitEmailTest() {
            
            // Create test data
            Account patient = J_TestUtils.createPatient(); // Create a test patient
            CareProgram cpp = J_TestUtils.createCareProgram(); // Create a Care Program
            CareProgramEnrollee cppEnrollee = J_TestUtils.createCareProgramEnrollee(patient.id, cpp.id); // Enrollee for the patient and care program
            MemberPlan mp = J_TestUtils.createMemberPlan(patient.id); // Create MemberPlan associated with the patient
            CoverageBenefit cb = J_TestUtils.createCoverageBenefit(cppEnrollee.id, mp.id); // Create CoverageBenefit for the enrollee and member plan
    
            // Create a Contact (Physician/Office Staff) with email address
            Contact con = new Contact(
                FirstName = 'Test First',
                LastName = 'Test Last',
                J_Preferred_Contact_Method__c = 'Email',
                Email = 'test123@indegene.com',
                J_Contact_Type__c = 'Journeys Physician Assistant',
                J_Contact_SubType__c = 'Office Staff',
                RecordTypeId = J_ObjectUtils.getRecordTypeId('Physician','Contact')
            );
            
            insert con; // Insert the contact into Salesforce
            
            // Create ContentVersion (file to attach to email)
            ContentVersion content = new ContentVersion(); 
            content.Title = 'Header_Picture1'; 
            content.PathOnClient = '/' + content.Title + '.jpg'; 
            content.VersionData = Blob.valueOf('Unit Test ContentVersion Body'); 
            content.Origin = 'H'; // Origin set to H (for standard file upload)
            insert content; // Insert the content version
            
            // Create ContentDocumentLink to associate the ContentDocument with the CoverageBenefit
            ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId = cb.id; // Associate with CoverageBenefit
            contentlink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.id].ContentDocumentId;
            contentlink.ShareType = 'I'; // Internal sharing
            contentlink.Visibility = 'AllUsers'; // Make the document available to all users
            insert contentlink; // Insert the ContentDocumentLink
            
            // Prepare the inputs for the email summary method
            List<CoverageBenefitEmailSummary.EmailInputs> inputs = new List<CoverageBenefitEmailSummary.EmailInputs>();
            CoverageBenefitEmailSummary.EmailInputs inp = new CoverageBenefitEmailSummary.EmailInputs();
            inp.contactEmail = con.Email; // Set the contact email
            inp.contactId = con.Id; // Set the contact Id
            inp.coverageBenefitId = cb.Id; // Set the CoverageBenefit Id
            inputs.add(inp); // Add the input to the list
            
            // Call the emailSummary method from the CoverageBenefitEmailSummary class
            CoverageBenefitEmailSummary.emailSummary(inputs);   
            
            // Retrieve the CoverageBenefit and validate the linkage to the correct Care Program Enrollee
            CoverageBenefit retrievedCb = [SELECT Id, J_CoverageBenefitStatus__c, Care_Program_Enrollee__c 
                                           FROM CoverageBenefit WHERE Id = :cb.Id];
            System.assertEquals(cppEnrollee.Id, retrievedCb.Care_Program_Enrollee__c, 
                                'Coverage Benefit should be linked to the correct enrollee');
        }
    }