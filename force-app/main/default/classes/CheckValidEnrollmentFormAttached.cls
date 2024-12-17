/**
 * @description    Class to check if a valid Enrollment Form is attached to a Lead record.
 * @category       Lead
 * @author         
 * @date           
 */
public with sharing class CheckValidEnrollmentFormAttached {

    /**
     * @description    Checks if the valid Enrollment Document is attached to the provided record IDs.
     * @param          recordIDs List of record IDs to check.
     * @return         List of ContentDocumentLink records that match the criteria or null if none found.
     */
    @InvocableMethod(label='Check Valid Enrollment Form Attached' description='Method checks if the valid Enrollment Document is Attached' category='Lead')
    public static List<ContentDocumentLink> checkValidEnrollmentFormAttachedByRecordID(List<Id> recordIDs) {
        try {
            // Validate input
            if (recordIDs == null || recordIDs.isEmpty()) {
                return null;
            }

            // Identify the object type of the first record ID
            String sObjName = recordIDs[0].getSObjectType().getDescribe().getName();

            // Check if the object is Lead and proceed with validation
            if (sObjName == 'Lead') {
                Lead leadRecord = fetchLead(recordIDs[0]);
                if (leadRecord != null && isValidRecordType(leadRecord)) {
                    return findValidEnrollmentForm(leadRecord);
                }
            }

            return null;
        } catch (Exception ex) {
            GenericLogger.debugLog('Error in checkValidEnrollmentFormAttachedByRecordID: ' + ex.getMessage());
            return null;
        }
    }

    /**
     * @description    Fetches the Lead record based on the provided record ID.
     * @param          recordId ID of the Lead record to fetch.
     * @return         Lead record or null if not found.
     */
   private static Lead fetchLead(Id recordId) {
    // Define the parameters for the utility method
    String sObjectType = 'Lead';
    String fields = 'Id, Expected_Enrollment_File_Name__c, RecordType.Name';
    String conditions = 'Id = \'' + recordId + '\'';

    // Use the utility class to execute the query
    List<SObject> result = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);

    // Check if the result is empty and return null if no lead is found
    if (result.isEmpty()) {
        return null;
    }

    // Return the first Lead record from the result
    return (Lead) result[0];
}


    /**
     * @description    Checks if the Lead record belongs to a valid RecordType.
     * @param          leadRecord Lead record to validate.
     * @return         True if the RecordType is valid; false otherwise.
     */
    private static Boolean isValidRecordType(Lead leadRecord) {
        return leadRecord.RecordType.Name == 'Patients/Caregivers' || leadRecord.RecordType.Name == 'Healthcare Providers';
    }

    /**
     * @description    Finds valid enrollment forms attached to the given Lead record.
     * @param          leadRecord Lead record to search for attached documents.
     * @return         List of ContentDocumentLink records or null if none found.
     */
private static List<ContentDocumentLink> findValidEnrollmentForm(Lead leadRecord) {
    List<ContentDocumentLink> documentLinks = new List<ContentDocumentLink>();

    // Check field accessibility and ensure ContentDocumentLink is accessible
    if (ContentDocumentLink.SObjectType.getDescribe(SObjectDescribeOptions.FULL).isAccessible() &&
        Schema.SObjectType.ContentDocumentLink.fields.ContentDocumentId.isAccessible() &&
        Schema.SObjectType.ContentDocumentLink.fields.LinkedEntityId.isAccessible()) {

        // Build the parameters for the query
        String sObjectType = 'ContentDocumentLink';
        String fields = 'ContentDocumentId, LinkedEntityId, ContentDocument.LatestPublishedVersionId, '
                        + 'ContentDocument.Title, ContentDocument.CreatedById, ContentDocument.LastModifiedDate';
        String conditions = 'LinkedEntityId = \'' + leadRecord.Id + '\' '
                            + 'AND LinkedEntity.Type = \'Lead\' '
                            + 'AND ContentDocument.Title = \'' + leadRecord.Expected_Enrollment_File_Name__c + '\' '
                            + 'AND ContentDocument.FileExtension = \'PDF\'';

        // Execute the query using the utility class
        List<ContentDocumentLink> contentDocumentLinks = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);

        // Check if results exist and add the first valid record to the documentLinks list
        if (!contentDocumentLinks.isEmpty()) {
            documentLinks.add((ContentDocumentLink) contentDocumentLinks[0]);
        }
    }
    // Return the documentLinks list, or null if empty
    return documentLinks.isEmpty() ? null : documentLinks;
}

}