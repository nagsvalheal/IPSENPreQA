/**
* @description        : This class handles file uploads and links them to records in Salesforce.
*                       It creates ContentVersion and ContentDocumentLink records, 
*                       and provides a method for retrieving linked files for a record.
* @author             : Mickram
* @last modified on   : 09-22-2023
*/
public with sharing class PriAuthFileUpload {
    
    /**
* @method uploadFile
* @description       : Creates a ContentVersion from a base64 encoded string and a filename, 
*                       and links it to the specified record.
* @param base64 - base64 string that represents the file.
* @param filename - Full file name with extension, e.g. 'products.csv'.
* @param recordId - The ID of the record to attach the file to.
* @return {String} - Returns the ContentDocumentLink Id if the upload was successful, otherwise returns null.
*/
    @AuraEnabled
    public static String uploadFile(String base64, String filename, String recordId) {
        // Null checks for input parameters
        if (String.isBlank(base64) || String.isBlank(filename) || String.isBlank(recordId)) {
            return null;
        }
        
        try {
            // Query for CarePreauth record based on recordId
            String sObjectType = 'CarePreauth';
            String fields = 'Id, Care_Program_Enrollee__c';
            String conditions = 'Id = \'' + recordId + '\'';
            
            List<CarePreauth> cb = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            
            // Ensure cb[0] is not null before proceeding
            if (cb.isEmpty() || cb[0] == null) {
                GenericLogger.debugLog('No CarePreauth record found');
                return null; // Exit the method or handle as needed
            }
            
            // Create ContentVersion and ContentDocumentLink
            ContentVersion cv = createContentVersion(base64, filename);
            ContentDocumentLink cdl = createContentLink(cv.Id, cb[0].Care_Program_Enrollee__c, recordId);
            
            // Check for null ContentVersion or ContentDocumentLink
            if (cv == null || cdl == null) {
                return null;
            }
            // Return the ContentDocumentLink Id if successful
            return cdl.Id;
        } catch (Exception e) {
            GenericLogger.exceptionLog(e); // Log any other exception
            return null;
        }
    }
    
    /**
* @method getLinkedFile
* @description       : Retrieves the list of files linked to a specific record.
* @param recordId - The ID of the record whose linked files you want to retrieve.
* @return {List<FileWrapper>} - A list of FileWrapper objects containing file details.
*/
    @AuraEnabled
    public static List<FileWrapper> getLinkedFile(String recordId) {
        List<FileWrapper> lstWrapper = new List<FileWrapper>();
        Set<Id> setCD = new Set<Id>();
        try {
            String sObjectType = 'ContentDocumentLink';
            String fields = 'Id, ContentDocument.Id, ContentDocument.Title, ContentDocument.FileExtension, LinkedEntityId';
            String conditions = 'LinkedEntityId = \'' + recordId + '\'';
            List<ContentDocumentLink> lstCDL = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            
            for (ContentDocumentLink lnk : lstCDL) {
                setCD.add(lnk.ContentDocument.Id);
            }
            String sObjectType1 = 'ContentVersion';
            String fields1 = 'Id, ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension';
            String conditionIds = '(\'' + String.join((setCD), '\', \'') + '\')';
            String conditions1 = 'ContentDocumentId IN ' + conditionIds;
            List<ContentVersion> lstContVersion = COM_QueryUtility.executeQuery(sObjectType1, fields1, conditions1, true);
            
            // Retrieve the custom label for the file download URL
            String downloadUrlTemplate = Label.FileDownloadURL;
            
            for (ContentVersion cv : lstContVersion) {
                FileWrapper wrapper = new FileWrapper();
                wrapper.recordID = cv.ContentDocumentId;
                wrapper.fileName = cv.ContentDocument.Title;
                wrapper.fileExt = cv.ContentDocument.FileExtension;
                wrapper.fileURL = downloadUrlTemplate.replace('{0}', cv.Id);
                lstWrapper.add(wrapper); 
            }
            return lstWrapper;
        } catch (Exception e) {
            GenericLogger.exceptionLog(e); // Log any other exception
            return null;
        }
    }
    
    /**
* @method createContentVersion
* @description       : Creates a ContentVersion record from the given base64 string and filename.
* @param base64 - The base64 encoded file data.
* @param filename - The name of the file being uploaded.
* @return {ContentVersion} - Returns the created ContentVersion record, or null if an error occurs.
*/
    private static ContentVersion createContentVersion(String base64, String filename) {
        // Null checks for input parameters
        if (String.isBlank(base64) || String.isBlank(filename)) {
            return null;
        }
        
        ContentVersion cv = new ContentVersion();
        cv.VersionData = EncodingUtil.base64Decode(base64);
        cv.Title = filename;
        cv.PathOnClient = filename;
        
        // Pass cv inside a list for the insert operation
        List<ContentVersion> contentVersions = new List<ContentVersion>{cv};
            COM_DatabaseOperationsUtility.insertOperation(contentVersions, PriAuthFileUpload.class.toString(), true);
        
        // After successful insert, return the inserted ContentVersion record
        return cv;
    }
    
    /**
* @method createContentLink
* @description       : Creates a ContentDocumentLink to link the uploaded ContentVersion to a record.
* @param contentVersionId - The ID of the ContentVersion record.
* @param patientID - The ID of the related patient record.
* @param recordId - The ID of the record to link the file to.
* @return {ContentDocumentLink} - Returns the created ContentDocumentLink, or null if an error occurs.
*/
    private static ContentDocumentLink createContentLink(String contentVersionId, String patientID, String recordId) {
        if (contentVersionId == null || recordId == null) {
            return null;
        }
        
        String sObjectType = 'ContentVersion';
        String fields = 'ContentDocumentId';
        String conditions = 'Id = \'' + contentVersionId + '\'';
        List<ContentVersion> result = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
        
        if (result.isEmpty()) {
            return null;
        }
        
        // Extract ContentDocumentId from the result
        String contentDocumentId = (String) result[0].get('ContentDocumentId');
        
        // Create ContentDocumentLink
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocumentId;
        cdl.LinkedEntityId = recordId;
        cdl.ShareType = 'V'; // Set ShareType to 'V' for Viewer
        
        // Pass cv inside a list for the insert operation
        List<ContentDocumentLink> contentDlink = new List<ContentDocumentLink>{cdl};
            COM_DatabaseOperationsUtility.insertOperation(contentDlink, PriAuthFileUpload.class.toString(), true);
        return cdl;
    }
    
    /**
* @class FileWrapper
* @description     : Wrapper class to hold file details for linked files.
*/
    public class FileWrapper {
        @AuraEnabled
        public String recordID;
        
        @AuraEnabled
        public String fileName;
        
        @AuraEnabled
        public String fileExt;
        
        @AuraEnabled
        public String fileURL;
    }
}