/**
 * @description This class is used to upload file to salesforce server
 
 */
public with sharing class J_FileUpload_Custom {
     /** 
      * @description This method is used to upload file to salesforce server
      * @param base64 - base64 string of the file
      * @param filename - file name
      * @param recordId - record id
      * @return String returns the id of the content version
     */
  
    
   @AuraEnabled
   public static String uploadFile(String base64, String filename, String recordId) {
        String sObjectType = 'CoverageBenefit';
        String fields = 'id, MemberId ';
        String conditions = 'id = \'' +recordId +'\'';
        list<CoverageBenefit> cb= COM_QueryUtility.executeQuery(sObjectType,fields,conditions,true);

         ContentVersion cv = createContentVersion(base64, filename);         
         ContentDocumentLink cdl = createContentLink(cv.Id, cb[0].MemberId,recordId );
         //ContentDistribution distributionLink = createContentDistribution(cv.id);
         if (cv == null || cdl == null) { return null; }
         return cdl.Id;
   }

   /**
    * @description This method is used to get the file name from the content version
    * @param recordId - record id
    * @return list<FileWrapper> - list of the file wrapper
    */

   @AuraEnabled
     public static list<FileWrapper> getLinkedFile(String recordId) {
          list<FileWrapper> lstWrapper = new list<FileWrapper>();
          set<id> setCD = new set<id>();
          String sObjectType = 'ContentDocumentLink';
          String fields = 'Id, ContentDocument.id, ContentDocument.Title, ContentDocument.FileExtension, LinkedEntityId';
          String conditions = 'LinkedEntityId = \'' +recordId +'\'';
          list<ContentDocumentLink> lstCDL= COM_QueryUtility.executeQuery(sObjectType,fields,conditions,true);

          for(ContentDocumentLink lnk:lstCDL){
            setCD.add(lnk.ContentDocument.id);
          }
          list<ContentVersion> lstContVersion = [select id,ContentDocumentId, ContentDocument.Title, ContentDocument.FileExtension from Contentversion where contentdocumentID=:setCD WITH SECURITY_ENFORCED];
          for(ContentVersion cv:lstContVersion){
               FileWrapper wrapper = new FileWrapper();
               wrapper.recordID = cv.ContentDocumentId;
               wrapper.fileName = cv.ContentDocument.Title;
               wrapper.fileExt = cv.ContentDocument.FileExtension;
               wrapper.fileURL = '/sfc/servlet.shepherd/version/download/' + cv.id+'?';
               lstWrapper.add(wrapper);
          }
          return lstWrapper;
   }
   /*
    * @method createContentVersion() [private]
    * @desc Creates a content version from a given file's base64 and name
    * 
    * @param {String} base64 - base64 string that represents the file
    * @param {String} filename - full file name with extension, i.e. 'products.csv'
    * 
    * @return {ContentVersion} - returns the newly created ContentVersion, or null
    *   if there was an error inserting the record
    */
   private static ContentVersion createContentVersion(String base64, String filename) {
     ContentVersion cv = new ContentVersion();
     cv.VersionData = EncodingUtil.base64Decode(base64);
     cv.Title = filename;
     cv.PathOnClient = filename;
     List<ContentVersion> cvRecords = new List<ContentVersion>{cv};
     try {
       if (Schema.sObjectType.ContentVersion.fields.Title.isCreateable()){  
        COM_DatabaseOperationsUtility.insertOperation(cvRecords,J_FileUpload_Custom.class.toString(),
                true);
       	//insert cv;
       }
       return cv;
     } catch(DMLException e) {
      GenericLogger.exceptionLog('J_FileUpload_Custom','createContentVersion',e);
       return null;
     }
   }
 
    /*
    * @method createContentLink() [private]
    * @desc Creates a content link for a given ContentVersion and record
    * 
    * @param {String} contentVersionId - Id of the ContentVersion of the file
    * @param {String} recordId - Id of the record you want to attach this file to
    * 
    * @return {ContentDocumentLink} - returns the newly created ContentDocumentLink, 
    *   or null if there was an error inserting the record
    */
   private static ContentDocumentLink createContentLink(String contentVersionId,string patientID, String recordId) {
        if (contentVersionId == null || recordId == null) { return null; }
        ContentDocumentLink cdl = new ContentDocumentLink();
        String sObjectType = 'ContentVersion';
        String fields = 'ContentDocumentId';
        String conditions = 'Id = \'' +contentVersionId +'\'';
        list<ContentVersion> lst= COM_QueryUtility.executeQuery(sObjectType,fields,conditions,true);

        cdl.ContentDocumentId = lst[0].ContentDocumentId;
        cdl.LinkedEntityId =recordId ;
        cdl.ShareType = 'V';
        List<ContentDocumentLink> recordsToInsert = new List<ContentDocumentLink>{cdl};
        try {
            if (Schema.sObjectType.ContentDocumentLink.fields.LinkedEntityId.isCreateable()){
              COM_DatabaseOperationsUtility.insertOperation(recordsToInsert,J_FileUpload_Custom.class.toString(),
                true
            );
            }

            return cdl;
        } catch(DMLException e) {
            GenericLogger.exceptionLog('J_FileUpload_Custom','createContentLink',e);
            return null;
        }
   }

@TestVisible private static ContentDistribution createContentDistribution(Id contentVersionId){
    List<ContentDistribution> newDistList = new List<ContentDistribution>();
    ContentDistribution newDist = new ContentDistribution();
    
     try{
         if (Schema.sObjectType.ContentDistribution.fields.Name.isCreateable()){
          
          newDist.ContentVersionId = contentVersionId;
          newDist.Name = 'External Link';
          newDist.PreferencesNotifyOnVisit = false;
          newDist.PreferencesAllowViewInBrowser = true;
          newDist.PreferencesAllowOriginalDownload=true;
          newDistList.add(newDist);
          COM_DatabaseOperationsUtility.insertOperation(
            newDistList,
            'J_FileUpload_Custom',
            true
        );
        
         }
     } catch(exception ex){
      GenericLogger.exceptionLog('J_FileUpload_Custom','ContentDocumentLink',ex);

     }
     return newDist;
 }

  /**
   *@description This class is used to wrap the file information
   *  */   
   public class FileWrapper {
          @AuraEnabled
          public string recordID;
        @AuraEnabled
        public string fileName;
        @AuraEnabled
        public string fileExt;
        @AuraEnabled
        public string fileURL;
   }
}