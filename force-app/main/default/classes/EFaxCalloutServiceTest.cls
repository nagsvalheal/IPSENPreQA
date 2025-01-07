/**
 * @description       : 
 * @author            : Mickram
 * @group             : 
 * @last modified on  : 10-03-2023
**/
@isTest
public with sharing class EFaxCalloutServiceTest {
    /**
     * @description       : Tests the sendFax method of EFaxCalloutService to ensure it successfully sends a fax 
     *                      and returns the correct fax ID using mock HTTP responses.
     **/
    @isTest
    static void testSendFaxCallout() {

        // Create a MultiStaticResourceCalloutMock instance
        MultiStaticResourceCalloutMock mock = new MultiStaticResourceCalloutMock();

        // Set a mock response for the first endpoint
        mock.setStaticResource(
            'callout:eFaxService/tokens',
            'EFaxOAuthSampleResponse'
        );

        // Set a mock response for the second endpoint
        mock.setStaticResource(
            'callout:eFaxService/faxes',
            'SendFaxSampleResponse'
        );

        // Set the HTTP mock response for the HTTPTestCallout
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'application/json');
        
        // Set the mock callout mode
        Test.setMock(HttpCalloutMock.class, mock);
        
        List<EFaxCalloutService.Destination> destinations = new List<EFaxCalloutService.Destination>();
        List<EFaxCalloutService.Document> documents = new List<EFaxCalloutService.Document>();
        EFaxCalloutService.Destination destination = new EFaxCalloutService.Destination();
        String orgNumber = '16178700971';
        destination.fax_number = orgNumber;
        destinations.add(destination);

        EFaxCalloutService.CoverPagOptions coverPageOptions = new EFaxCalloutService.CoverPagOptions();
        coverPageOptions.from_name = 'Test';
        coverPageOptions.message = 'test message';
        coverPageOptions.subject = 'test subject';

        EFaxCalloutService.FaxOptions faxOptions = new EFaxCalloutService.FaxOptions();
        faxOptions.image_resolution = 'FINE';
        faxOptions.include_cover_page = false;
        faxOptions.custom_CSID = orgNumber;

        EFaxCalloutService.Document document = new EFaxCalloutService.Document();
        document.document_type = 'TXT';
        document.document_content = 'VGhpcyBpcyBhIHRlc3QuIFRlc3QgMi4=';
        documents.add(document);
        
        // Call the method that makes the callout
        String result = EFaxCalloutService.sendFax(destinations, documents, faxOptions,'6fac2c6c-8b15-47eb-ba28-e5c96344aaf1');
        
        // Verify that the response is successful and contains the expected data
        System.assertEquals('ea7382cf-8483-4bc5-954e-d3bc7074246a', result, 'Not the expected faxid');
    }
    
    @isTest
    static void testGetFaxImageCallout() {
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
        
        // Call the method that makes the callout
        String result = EFaxCalloutService.getFaxImageCallout('ea7382cf-8483-4bc5-954e-d3bc7074246a', '6fac2c6c-8b15-47eb-ba28-e5c96344aaf1');
        
        // Verify that the response is successful and contains the expected data
        System.assertNotEquals(null, result, 'Not the expected response');
    }
}