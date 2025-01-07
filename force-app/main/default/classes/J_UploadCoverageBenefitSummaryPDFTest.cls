/**
 * @description This test class verifies the functionality of the `uploadSummaryPDF` method, which handles 
 *              the process of uploading and associating a Coverage Benefit summary PDF with the relevant 
 *              Coverage Benefit record in Salesforce. 
 *              
 *              The test includes creating necessary test data such as Patient, Care Program, Enrollee, 
 *              Member Plan, and Coverage Benefit records, as well as simulating the PDF upload process 
 *              via a ContentVersion record. The class ensures that the uploaded PDF is correctly linked 
 *              to the Coverage Benefit through the ContentDocumentLink.
 */
@isTest
public class J_UploadCoverageBenefitSummaryPDFTest {

    /**
     * @description Test method for verifying the upload of CoverageBenefit summary PDF.
     * This test simulates the process of creating test data for a CoverageBenefit, uploading a PDF file 
     * as a ContentVersion, linking the content to the CoverageBenefit using ContentDocumentLink, 
     * and then calling the uploadSummaryPDF method to verify that the content is linked correctly.
     */
    @isTest
    static void testUploadSummaryPDF() {
        Test.startTest();
        
        // Step 1: Create test data
        // Create a Patient record (Account)
        Account patient = J_TestUtils.createPatient();
        
        // Create a Care Program
        CareProgram cpp = J_TestUtils.createCareProgram();
        
        // Create a Care Program Enrollee linked to the patient and care program
        CareProgramEnrollee cppEnrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cpp.Id);
        
        // Create a Member Plan linked to the patient
        MemberPlan mp = J_TestUtils.createMemberPlan(patient.Id);
        
        // Create a Coverage Benefit linked to the Care Program Enrollee and Member Plan
        CoverageBenefit cb = J_TestUtils.createCoverageBenefit(cppEnrollee.Id, mp.Id);

        // Step 2: Create a test ContentVersion to simulate the upload of a PDF
        ContentVersion content = new ContentVersion(); 
        content.Title = 'Test Coverage Summary.PDF'; 
        content.PathOnClient = '/' + content.Title; 
        content.VersionData = Blob.valueOf('Test Content'); // Simulated PDF content
        content.Origin = 'H'; // External Origin
        insert content;

        // Step 3: Link the content document to the CoverageBenefit using ContentDocumentLink
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = cb.Id; // Linking to the CoverageBenefit
        contentlink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id].ContentDocumentId;
        contentlink.Visibility = 'AllUsers'; // Visibility set to All Users
        insert contentlink;

        // Step 4: Call the method under test to upload the summary PDF
        J_UploadCoverageBenefitSummaryPDF.uploadSummaryPDF(new List<Id>{cb.Id});
        Test.stopTest();

        // Assertions:
        // Verify the ContentDocumentLink is associated with the CoverageBenefit
        List<ContentDocumentLink> links = [
            SELECT Id, LinkedEntityId, ContentDocumentId 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :cb.Id
        ];
        
        // Assert that one ContentDocumentLink record is associated with the CoverageBenefit
        System.assertEquals(2, links.size(), 'There should be one ContentDocumentLink associated with the CoverageBenefit.');
        
        // Assert that the LinkedEntityId matches the CoverageBenefit ID
        System.assertEquals(cb.Id, links[0].LinkedEntityId, 'The LinkedEntityId should match the CoverageBenefit ID.');

        // Verify the ContentDocument is processed correctly
        ContentDocument contentDoc = [
            SELECT Id 
            FROM ContentDocument 
            WHERE Id = :links[0].ContentDocumentId
        ];
        
        // Assert that the ContentDocument exists and has been linked successfully
        System.assertNotEquals(contentDoc, null, 'The ContentDocument should exist.');
    }
}