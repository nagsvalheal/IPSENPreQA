/**
 * @description       : 
 * @author            : Mickram
 * @group             : 
 * @last modified on  : 10-03-2023

**/
@isTest
public with sharing class InboundFaxEventTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        Received_Fax__c receivedFax = new Received_Fax__c();
        receivedFax.Fax_number_of_the_recipient__c = '145435634';
        receivedFax.Fax_number_of_the_sender__c = '122343342';
        receivedFax.Status__c = 'Received';
        receivedFax.Total_pages__c = 2;
        insert receivedFax;
    }

    @isTest
    static void testInboundFaxEventTriggerHandler() {
        // Create a MultiStaticResourceCalloutMock instance
        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();

        // Set a mock response for the first endpoint
        mock.setStaticResource(
            'callout:eFaxService/tokens',
            'EFaxOAuthSampleResponse'
        );

        // Set a mock response for the second endpoint
        mock.setStaticResource(
            'callout:eFaxService/faxes/ea7382cf-8483-4bc5-954e-d3bc7074246a/image?desired_format=PDF',
            'GetFaxImageSampleResponse'
        );

        // Set the HTTP mock response for the HTTPTestCallout
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);

        Received_Fax__c receivedFax = [Select id from Received_Fax__c limit 1];
        InboundFaxEventTriggerHandler.Request request = new InboundFaxEventTriggerHandler.Request();
        request.faxId = 'ea7382cf-8483-4bc5-954e-d3bc7074246a';
        request.receivedFaxId = receivedFax.Id;
        request.userId = '6fac2c6c-8b15-47eb-ba28-e5c96344aaf1';

        Test.startTest();
        InboundFaxEventTriggerHandler.getImage(new List<InboundFaxEventTriggerHandler.Request>{request});
        Test.stopTest();

        List<ContentDocumentLink> cdlList = [Select Id from ContentDocumentLink where LinkedEntityId =:receivedFax.Id ];
        System.assertEquals(1, cdlList.size(), 'No Image attached');
    }
}