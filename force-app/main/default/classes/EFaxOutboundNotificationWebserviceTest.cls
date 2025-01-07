/**
 * @description       : 
 * @author            : Mickram
 * @group             : 
 * @last modified on  : 10-03-2023
 
**/
@isTest
public class EFaxOutboundNotificationWebserviceTest {

    @TestSetup
    static void makeData(){
        Sent_Fax__c sentFax = new Sent_Fax__c(
            Fax_Number__c = '123243444',
            //Care_Program_Enrollee__c = enrolleeId,
            Fax_Id__c = 'ea7382cf-8483-4bc5-954e-d3bc7074246a',
            Organisation_Fax_number__c = '123423433'
        );
        insert sentFax;
    }

    @isTest
    static void testHandleOutboundFax() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
    
        req.requestURI = '/services/apexrest/efax/notification/outbound';  //Request URL
        req.httpMethod = 'POST';//HTTP Request Type
        req.requestBody =  Blob.valueof(constructOutboundRequest());
        RestContext.request = req;
        RestContext.response= res;
      
        // Call the handleOutboundFax method
        EFaxOutboundNotificationWebservice.handleOutboundFax();

        // Verify that the outbound Fax record was updated with the Response status
        Sent_Fax__c sentFax = [Select Id,Status__c from Sent_Fax__c where Fax_Id__c='ea7382cf-8483-4bc5-954e-d3bc7074246a' limit 1];
        System.assertEquals('COMPLETE', sentFax.Status__c, 'Status not updated');
    }
    /**
     * @description Constructs a sample outbound fax request in JSON format.
     * 
     * @return A serialized JSON string representing the outbound fax request.
     */
    public static String constructOutboundRequest(){
        EFaxOutboundNotificationWebservice.OutboundFax outboundFax = new EFaxOutboundNotificationWebservice.OutboundFax();
        outboundFax.fax_id = 'ea7382cf-8483-4bc5-954e-d3bc7074246a';
        outboundFax.completed_timestamp = '2023-08-24T14:15:22Z';
        outboundFax.destination_fax_number = '123243444';
        outboundFax.status = 'COMPLETE';
        outboundFax.user_id = '6fac2c6c-8b15-47eb-ba28-e5c96344aaf1';
        return JSON.serialize(outboundFax);
    }
}