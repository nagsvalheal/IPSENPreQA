/**
 * @description       : Web service class to handle outbound fax notifications.
 * @author            : 
 * @group             : 
 * @last modified on  : 09-22-2023
 * 
**/
@RestResource(urlMapping='/efax/notification/outbound')
global without sharing class EFaxOutboundNotificationWebservice {

    /**
     * @description       : Handles outbound fax notifications via HTTP POST request.
     *                       Deserializes the incoming request, processes the fax, 
     *                       and updates the corresponding Salesforce record.
     * @HttpPost          : Exposed as a REST endpoint for POST requests.
     **/
    @HttpPost
    global static void handleOutboundFax() {
        RestResponse res = RestContext.response;
        try {
            String requestBody = RestContext.request.requestBody.toString();
            OutboundFax outboundFax = (OutboundFax) JSON.deserialize(requestBody, OutboundFax.class);
            Response response = new Response();
            // Logic to update outbound fax
            updateSentFax(outboundFax);

            response.status = 'SUCCESS';
            res.responseBody = Blob.valueOf(JSON.serialize(response));
            res.statusCode = 200;
        } catch(Exception ex) {
            // Set the response before logging the exception
            Response errorResponse = new Response();
            errorResponse.status = 'FAILURE';

            res.responseBody = Blob.valueOf(JSON.serialize(errorResponse));
            res.statusCode = 500;

            // Log the exception
            GenericLogger.exceptionLog('EFaxOutboundNotificationWebservice', 'handleOutboundFax', ex);
        }
    }

    /**
     * @description       : Updates the details of a sent fax in Salesforce 
     *                       based on the information received from the notification.
     * @param outboundFax : The deserialized OutboundFax object containing fax details.
     **/
    public static void updateSentFax(OutboundFax outboundFax) {
        String sObjectType = 'Sent_Fax__c';
        String fields = 'Id, Status__c, Total_Pages__c, Error_Reason__c, Delivery_Date_Time__c';
        String whereClause = 'Fax_Id__c = \'' + outboundFax.fax_id + '\'';
        
        // Fetch the records using the query utility
        List<Sent_Fax__c> sentFaxList = (List<Sent_Fax__c>) COM_QueryUtility.executeQuery(
            sObjectType, 
            fields, 
            whereClause, 
            true
        );
        
        if (!sentFaxList.isEmpty()) {
            // Update the first record with details from the outbound fax
            Sent_Fax__c sentFax = sentFaxList[0];
            sentFax.Status__c = outboundFax.status;
            sentFax.Total_Pages__c = outboundFax.pages;
            sentFax.Error_Reason__c = outboundFax.error_reason;
            sentFax.Delivery_Date_Time__c = (DateTime) JSON.deserialize('"' + outboundFax.completed_timestamp + '"', DateTime.class);
    
            COM_DatabaseOperationsUtility.updateOperation(new List<Sent_Fax__c>{sentFax}, 'EFaxOutboundNotificationWebservice ', true);
        }
    }
    
    /**
     * @description       : Data structure representing the outbound fax details received
     *                       from the external service.
     **/
    global class OutboundFax {
        global String app_id;                  // Application ID
        global String user_id;                 // User ID
        global String notification_id;         // Notification ID
        global String fax_id;                  // Fax ID
        global String direction;               // Direction of fax (OUTBOUND)
        global String completed_timestamp;     // Timestamp of completion
        global Integer duration;               // Duration of fax in seconds
        global Integer pages;                  // Total pages sent
        global String destination_fax_number;  // Destination fax number
        global String status;                  // Status of the fax
        global Integer billable_retries;       // Number of billable retries
        global String error;                   // Error code (if any)
        global String error_reason;            // Error reason (if any)
        global ClientData client_data;         // Client data associated with the fax
    }

    /**
     * @description       : Data structure for client-specific data associated with 
     *                       an outbound fax notification.
     **/
    global class ClientData {
        global String billing_code;            // Billing code for the client
        global String client_code;             // Client code
        global String client_id;               // Client ID
        global String client_matter;           // Client matter details
        global String client_name;             // Name of the client
        global String client_reference_id;     // Reference ID for the client
    }

    /**
     * @description       : Response structure for the web service endpoint, 
     *                       indicating the status of the operation.
     **/
    global class Response {
        global String status;  // Status of the operation (e.g., SUCCESS or FAILURE)
    }
}