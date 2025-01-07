public class OT_consentCallOut {
    // Create Data Subject/Transaction
    @future(callout=true)
    public static void createConsentTransaction(string OT_schema) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://privacyportal-de.onetrust.com/request/v1/consentreceipts');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody(OT_schema);
    	HttpResponse response = null;
        
        try {
            if(Test.isRunningTest()){
                response = new HttpResponse();
                response.setStatus('Bad Request');
                response.setStatusCode(400);
            } else {
                response = http.send(request);
            }
            
            if(response.getStatusCode() != 200) {
                throw new OT_Error_Exception('OneTrust: Unsuccessful delivery: Status Code: '+ response.getStatusCode() +'  Request Body: '+ request.getBody() +'  Response Body: '+ response.getBody());
            }
        } catch(System.CalloutException e) {
            System.debug('Error:'+e);
        } catch(OT_Error_Exception e) {
            System.debug('Error:'+e);
        }
    }
}