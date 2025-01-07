/**
 * @description       : Test class for EFax Inbound Notification Webservice.
 * @author            : Mickram
 * @group             : 
 * @last modified on  : 10-03-2023
 
**/
@isTest
public class EFaxInboundNotificationWebserviceTest {

    @isTest
    static void testHandleInboundFax() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
    
        req.requestURI = '/services/apexrest/efax/notification/inbound';  //Request URL
        req.httpMethod = 'POST';//HTTP Request Type
        req.requestBody =  Blob.valueof(constructInboundRequest());
        RestContext.request = req;
        RestContext.response= res;
      
        // Call the handleInboundFax method
        EFaxInboundNotificationWebservice.handleInboundFax();

        // Verify that the Inbound Fax record was updated with the Response status
        String sObjectType = 'Received_Fax__c';
        String fields = 'Id, Fax_number_of_the_recipient__c, Fax_number_of_the_sender__c';
        List<SObject> receivedFaxList = COM_QueryUtility.executeQuery(
            sObjectType, 
            fields, 
            null, 
            true
        );
        Received_Fax__c receivedFax = (Received_Fax__c)receivedFaxList[0];
        System.assertEquals('123243445', receivedFax.Fax_number_of_the_sender__c, 'Fax number not expected');
    }
     /**
     * @description Constructs a sample inbound fax request in JSON format.
     * 
     * @return A serialized JSON string representing the inbound fax request.
     */
    public static String constructInboundRequest(){
        EFaxInboundNotificationWebservice.InboundFax inboundFax = new EFaxInboundNotificationWebservice.InboundFax();
        inboundFax.fax_id = 'ea7382cf-8483-4bc5-954e-d3bc7074246a';
        inboundFax.completed_timestamp = '2023-08-24T14:15:22Z';
        inboundFax.sending_fax_number = '123243445';
        inboundFax.receiving_fax_number = '123243444';
        inboundFax.originating_fax_tsid = '123243445';
        inboundFax.pages = 1;
        inboundFax.user_id = '6fac2c6c-8b15-47eb-ba28-e5c96344aaf1';
        return JSON.serialize(inboundFax);
    }
}