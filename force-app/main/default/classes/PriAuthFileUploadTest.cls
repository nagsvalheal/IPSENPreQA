/**
     * @description This test method validates the functionality of the PriAuthFileUpload class, including the ability to upload files and retrieve linked files.
     */
@isTest
public class PriAuthFileUploadTest {

    /**
     ** @description
    * This is a unit test for the PriAuthFileUpload functionality. It tests the process of uploading a file
    * to a CarePreauth record and verifies the successful linking of the file to the CarePreauth record.
     * This test method validates the functionality of the PriAuthFileUpload class,
     * including the ability to upload files and retrieve linked files.
     */
    @IsTest
    static void testFileUpload() {
        Test.startTest(); // Begin the test execution context

        // Step 1: Create a test Account representing a patient
        Account patient = J_TestUtils.createPatient();

        // Step 2: Create a MemberPlan associated with the test patient
        MemberPlan mp = J_TestUtils.createMemberPlan(patient.Id);
        
        // Step 3: Create a Care Program to be associated with the enrollee
        CareProgram cp = J_TestUtils.createCareProgram();

        // Step 4: Create a CareProgramEnrollee record linked to the test patient and Care Program
        CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(patient.Id, cp.Id);
             
        // Step 5: Create a CoverageBenefit record associated with the enrollee and MemberPlan
        CoverageBenefit cb = J_TestUtils.createCoverageBenefit(enrollee.Id, mp.Id);

        // Step 6: Create a CarePreauth record linked to the MemberPlan and CoverageBenefit
        CarePreauth pa = J_TestUtils.createCarePreauth(mp.id, cb.id);

        // Step 7: Create a ContentVersion record representing the file to be uploaded
        ContentVersion content = new ContentVersion();
        content.Title = 'test crm patient - Benefit Investigation Summary (9).PDF'; // Set file title
        content.PathOnClient = '/' + content.Title + '.PDF'; // Set the file path
        content.VersionData = Blob.valueOf('Test Content'); // Set file content as a Blob
        content.origin = 'H'; // Set the origin of the file
        insert content; // Insert the ContentVersion record

        // Step 8: Link the uploaded ContentDocument to the CarePreauth record using ContentDocumentLink
        ContentDocumentLink contentLink = new ContentDocumentLink();
        contentLink.LinkedEntityId = pa.Id; // Link to CarePreauth record
        contentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id].ContentDocumentId;
        contentLink.Visibility = 'AllUsers'; // Set visibility
        insert contentLink; // Insert the ContentDocumentLink record

        // Step 9: Invoke the PriAuthFileUpload.uploadFile method to test file upload functionality
        String uploadFileResult = PriAuthFileUpload.uploadFile(
            'base64', 
            'test crm patient - Benefit Investigation Summary (9).PDF', 
            pa.Id
        );

        // Assert that the file upload was successful and a ContentDocumentLink ID was returned
        System.assertNotEquals(null, uploadFileResult, 'File upload failed and no ContentDocumentLink Id returned.');

        // Step 10: Retrieve linked files using PriAuthFileUpload.getLinkedFile method
        List<PriAuthFileUpload.FileWrapper> linkedFiles = PriAuthFileUpload.getLinkedFile(pa.Id);

        // Assert that linked files were retrieved successfully
        System.assertNotEquals(0, linkedFiles.size(), 'No linked files were found for the CarePreauth record.');

        // Assert that the linked file's name matches the expected file name
        System.assertEquals(
            linkedFiles[0].fileName, 
            'test crm patient - Benefit Investigation Summary (9).PDF', 
            'File name in linked files does not match the expected value.'
        );

        Test.stopTest(); // End the test execution context
    }
}