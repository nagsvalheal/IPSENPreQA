/**
 * @description       : Test class for validating the attachment of enrollment forms to Leads.
 *                      Ensures the utility method behaves correctly for both positive and negative cases.
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @last modified on  : 12-13-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public class CheckValidEnrollmentFormAttachedTest {

 /**
     * @description Helper method to create and attach a ContentDocumentLink to a Lead.
     * @param lead The Lead record to which the document will be attached.
     * @param expectedFileName The expected name of the file being attached.
     * @return The ContentDocumentLink object created and linked to the Lead.
     */
    private static ContentDocumentLink attachDocument(Lead lead, String expectedFileName) {
        ContentVersion content = new ContentVersion(
            Title = expectedFileName,
            PathOnClient = '/' + expectedFileName + '.pdf',
            VersionData = Blob.valueOf('Unit Test ContentVersion Body'),
            Origin = 'H'
        );
        insert content;

        ContentDocumentLink contentLink = new ContentDocumentLink(
            LinkedEntityId = lead.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :content.Id].ContentDocumentId,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert contentLink;
        return contentLink;
    }
 /**
     * @description Test to validate the attachement format.
     *               Covers both positive and negative cases for valid enrollment form attachments.
     */
    @isTest
    public static void testValidEnrollmentFormForPatientsAndCaregivers() {
      // Create a Care Program as a prerequisite for the Lead
        CareProgram cp = J_TestUtils.createCareProgram();

        // Create Lead with Patients_Caregivers record type
        Lead lead = J_TestUtils.createLead(J_ObjectUtils.LEAD_PATIENT_RECORD_TYPE, cp.id);
        
        String expectedFileName = lead.FirstName + ' ' + lead.LastName + ' - Journeys Enrollment Form';

        // Negative case: No documents attached
        List<ContentDocumentLink> docLinks = CheckValidEnrollmentFormAttached.checkValidEnrollmentFormAttachedByRecordID(new List<Id>{lead.Id});
        System.assert(docLinks == null, 'No Document Link should exist initially.');

        // Positive case: Attach valid document
        attachDocument(lead, expectedFileName);
        docLinks = CheckValidEnrollmentFormAttached.checkValidEnrollmentFormAttachedByRecordID(new List<Id>{lead.Id});
        System.assert(docLinks != null && docLinks.size() == 1, 'Valid Document Link should exist after attachment.');
    }
 /**
     * @description Test to validate the attachement format.
     *               Covers both positive and negative cases for valid enrollment form attachments.
     */
  @isTest
    public static void testValidEnrollmentFormForHealthcareProviders() {
     
         // Create a Care Program as a prerequisite for the Lead
        CareProgram cp = J_TestUtils.createCareProgram();
        
         // Create Lead with Healthcare Provider record type
         Lead lead = J_TestUtils.createLead(J_ObjectUtils.LEAD_HCF_RECORD_TYPE, cp.id);
        
         String expectedFileName = lead.FirstName + ' ' + lead.LastName + ' - Journeys HCP Enrollment Form';

        // Negative case: No documents attached
        List<ContentDocumentLink> docLinks = CheckValidEnrollmentFormAttached.checkValidEnrollmentFormAttachedByRecordID(new List<Id>{lead.Id});
        System.assert(docLinks == null, 'No Document Link should exist initially.');

        // Positive case: Attach valid document
        attachDocument(lead, expectedFileName);
        docLinks = CheckValidEnrollmentFormAttached.checkValidEnrollmentFormAttachedByRecordID(new List<Id>{lead.Id});
        System.assert(docLinks != null && docLinks.size() == 1, 'Valid Document Link should exist after attachment.');
    }
 /**
     * @description Test to validate the attachement format.
     *               Covers both positive and negative cases for valid enrollment form attachments.
     */
    @isTest
    public static void testInvalidRecordType() {
        String firstName = 'TestInvalid';
        String lastName = 'InvalidType';
        Lead lead = new Lead(
            FirstName = firstName,
            LastName = lastName,
            J_Date_of_Birth__c = System.today(),
            RecordTypeId = J_ObjectUtils.getRecordTypeId('Increlex_HCP_Enrollment', 'Lead')
        );
        insert lead;

        // Method should return null for unsupported record types
        List<ContentDocumentLink> docLinks = CheckValidEnrollmentFormAttached.checkValidEnrollmentFormAttachedByRecordID(new List<Id>{lead.Id});
        System.assert(docLinks == null, 'No Document Link should be found for unsupported record type.');
    }
 /**
     * @description Test to validate the attachement format.
     *               Covers both positive and negative cases for valid enrollment form attachments.
     */
    @isTest
    public static void testNullAndEmptyRecordIDs() {
        // Test with null record IDs
        List<ContentDocumentLink> docLinks = CheckValidEnrollmentFormAttached.checkValidEnrollmentFormAttachedByRecordID(null);
        System.assert(docLinks == null, 'Method should return null for null record IDs.');

        // Test with empty record IDs
        docLinks = CheckValidEnrollmentFormAttached.checkValidEnrollmentFormAttachedByRecordID(new List<Id>());
        System.assert(docLinks == null, 'Method should return null for empty record IDs.');
    }
}