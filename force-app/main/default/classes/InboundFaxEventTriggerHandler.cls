/**
 * @description       : This class handles Inbound Fax Events. It includes methods to retrieve and save fax images 
 *                      associated with Salesforce records.
 * @author            : Mickram
 * @group             : Fax Handling
 * @last modified on  : 09-22-2023
 * @last modified by  : Mickram
 * @modification log  : 
 *                      09-22-2023 - Initial version
**/
public without sharing class InboundFaxEventTriggerHandler {
   
    /**
     * @description : Invocable method to retrieve a fax image using an external callout and save it in Salesforce.
     * @param requests : A list of Request objects containing fax and user-related details.
    **/
    @InvocableMethod(Label='Save Image' Callout=true)
    public static void getImage(List<Request> requests){
        try {
            if(requests != null && !requests.isEmpty()){
            Request request = requests[0];
            String imageResponse = EFaxCalloutService.getFaxImageCallout(request.faxId, request.userId);
            FaxImage faxImage = (FaxImage)JSON.deserialize(imageResponse, FaxImage.class);

            if (!String.isBlank(faxImage.image)) {
                saveImage(faxImage, request.receivedFaxId);
             }
            }
        } catch (Exception ex) {
            GenericLogger.exceptionLog('InboundFaxEventTriggerHandler', 'getImage', ex);
        }
    }

    /**
     * @description : Saves the fax image as a ContentVersion record and links it to a Salesforce record.
     * @param faxImage    : An object containing the fax image data and file details.
     * @param receivedFaxId : The ID of the Salesforce record to which the fax image is linked.
    **/
    public static void saveImage(FaxImage faxImage, Id receivedFaxId) {
        J_ObjectUtils.ignoreAccessCheck = true;

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = EncodingUtil.base64Decode(faxImage.image);
        cv.Title = faxImage.fileName;
        cv.PathOnClient = faxImage.fileName;
        cv.FirstPublishLocationId  = receivedFaxId;
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{cv}, 'InboundFaxEventTriggerHandler', false);

        ContentDocumentLink cdl = new ContentDocumentLink();
        ContentVersion contentVersion = (ContentVersion)COM_QueryUtility.executeQuery(
            'ContentVersion', 
            'Id, ContentDocumentId', 
            'Id = \'' + cv.Id + '\'', 
            false
        )[0];
        cdl.ContentDocumentId = contentVersion.ContentDocumentId;
        cdl.LinkedEntityId = receivedFaxId;
        cdl.ShareType = 'V';
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{cdl}, 'InboundFaxEventTriggerHandler', false);
      
    }

    /**
     * @description : Inner class to define the structure of the request object passed to the invocable method.
    **/
    public class Request {
        /**
         * @description : The ID of the fax document to be retrieved.
        **/
        @InvocableVariable(label='Fax Id' required=true)
        public String faxId;

        /**
         * @description : The ID of the user initiating the request.
        **/
        @InvocableVariable(label='User Id' required=true)
        public String userId;

        /**
         * @description : The Salesforce record ID to link the retrieved fax image.
        **/
        @InvocableVariable(label='Received Fax Salesforce Id' required=true)
        public String receivedFaxId;
    }
    
    /**
     * @description : Inner class to define the structure of the fax image object.
    **/
    class FaxImage {
        
        //string fax_id;
        /**
         * @description : The name of the file being saved.
        **/
        String fileName;

        /**
         * @description : The base64-encoded image data.
        **/
        String image;
    }
}