/**
* @description A class for handling the upload of the latest coverage summary PDF.
*              Retrieves associated content document links and uploads the summary PDF.
* @category CoverageBenefit
*/
public with sharing class J_UploadCoverageBenefitSummaryPDF {
    
    /**
* @description Uploads the latest coverage summary PDF for the provided CoverageBenefit records.
*              Associates ContentDocument with the provided IDs and performs necessary operations.
* @param ids List of CoverageBenefit record IDs to process.
*/
    @InvocableMethod(label='Upload Coverage Benefit PDF' description='Uploads latest coverage summary pdf' category='CoverageBenefit')
    public static void uploadSummaryPDF(List<ID> ids) {
        try {
            String sObjectType = 'ContentDocumentLink';
            String fields = 'Id, ContentDocument.Id';
            String conditions = 'LinkedEntityId IN (\'' + String.join((ids), '\', \'') + '\')';
            // Retrieve ContentDocumentLink records for the provided CoverageBenefit IDs
            List<ContentDocumentLink> docs =  COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            GenericLogger.debugLog('--docId--' + docs);
            
            if (!docs.isEmpty()) {
                // Prepare a list containing a single ContentDocument for upsert operation
                ContentDocument dc = new ContentDocument();
                dc.Id = docs[0].ContentDocument.Id;
                List<ContentDocument> docList = new List<ContentDocument> { dc };
                    
                    // Perform the upsert operation using the utility class
                    COM_DatabaseOperationsUtility.upsertOperation(docList, J_UploadCoverageBenefitSummaryPDF.class.toString(), true);
            }
            
            // Log the provided IDs
            GenericLogger.debugLog('--ids--' + ids);
            
            // Upload the Coverage Benefit PDFs
            J_CoverageBenefitTriggerHandler.uploadCoverageBenefitPDF(ids);
            
        } catch (Exception e) {
            // Log any exceptions that occur
            GenericLogger.exceptionLog(e);
        }
    }
}