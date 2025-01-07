/**
 * @description       : Web service class to handle inbound fax notifications.
 * @author            : 
 * @group             : 
 * @last modified on  : 09-26-2023
 * 
**/
@RestResource(urlMapping='/efax/notification/inbound')
global without sharing class EFaxInboundNotificationWebservice {

    /**
     * @description       : Handles inbound fax notifications via HTTP POST request.
     *                       Deserializes the incoming request, processes the fax, 
     *                       and publishes an event.
     * @HttpPost          : Exposed as a REST endpoint for POST requests.
     **/
    @HttpPost
    global static void handleInboundFax() {
        RestResponse res = RestContext.response;
        try{
            String requestBody = RestContext.request.requestBody.toString();
            InboundFax inboundFax = (InboundFax) JSON.deserialize(requestBody, InboundFax.class);
            Response response = new Response();
            // Logic to save inbound Fax
            saveFax(inboundFax);

            response.status = 'SUCCESS';
            res.responseBody = Blob.valueOf(JSON.serialize(response));
            res.statusCode = 200;
        }catch(Exception ex){
            GenericLogger.exceptionLog('EFaxInboundNotificationWebservice','handleInboundFax',ex);
            res.responseBody = Blob.valueOf(ex.getMessage());
            res.statusCode = 500;
        }
    }

    /**
     * @description       : Saves the inbound fax details to Salesforce and publishes 
     *                       an event with the relevant fax details.
     * @param inboundFax  : The deserialized InboundFax object containing fax details.
     **/
    public static void saveFax(InboundFax inboundFax){
        Received_Fax__c receivedFax = new Received_Fax__c();

        GenericLogger.debugLog('Inside save fax');
        GenericLogger.debugLog(inboundFax.receiving_fax_number);

        receivedFax.Fax_number_of_the_recipient__c = inboundFax.receiving_fax_number;
        receivedFax.Fax_number_of_the_sender__c = inboundFax.originating_fax_tsid;
        receivedFax.Status__c = 'Received';
        receivedFax.Total_pages__c = inboundFax.pages;

        COM_DatabaseOperationsUtility.insertOperation(new List<Received_Fax__c>{receivedFax},'EFaxInboundNotificationWebservice ',true);

        List<Inbound_Fax_Event__e> inboundFaxEvents = new List<Inbound_Fax_Event__e>();
        inboundFaxEvents.add(new Inbound_Fax_Event__e(Fax_Id__c = inboundFax.fax_id, User_Id__c = inboundFax.user_id, Received_Fax_Salesforce_Id__c = receivedFax.Id));

        // Call method to publish events
        List<Database.SaveResult> results = EventBus.publish(inboundFaxEvents);
        GenericLogger.debugLog('results:' + results);
    }

    /**
     * @description       : Data structure representing the inbound fax details received
     *                       from the external service.
     **/
    global class InboundFax {
        global String app_id;                 // Application ID
        global String user_id;               // User ID
        global String notification_id;       // Notification ID
        global String direction;             // Direction of fax (INBOUND)
        global String completed_timestamp;   // Timestamp of completion
        global Integer duration;             // Duration of fax in seconds
        global Integer pages;                // Total pages received
        global String fax_id;                // Fax ID
        global String sending_fax_number;    // Sending fax number
        global String receiving_fax_number;  // Receiving fax number
        global String resource_url;          // Resource URL for fax data
        global String originating_fax_tsid;  // Originating fax TSID
    }

    /**
     * @description       : Response structure for the web service endpoint, 
     *                       indicating the status of the operation.
     **/
    global class Response {
        global String status;  // Status of the operation (e.g., SUCCESS or FAILURE)
    }
}