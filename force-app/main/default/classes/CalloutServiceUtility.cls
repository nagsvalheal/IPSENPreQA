/**
 * @description  : Common class for all callout services
 * @author            : 
 * @group             : 
 * @last modified on  : 09-14-2023
 * 
**/
public with sharing class CalloutServiceUtility {
    /**
     * @description  : Constructs HttpRequest
     * @param endpoint : Endpoint URL
     * @param method   : HTTP Method
     * @param body     : Request Body
     * @param headers  : Headers
     */
    public static HttpRequest constructRequest(String endpoint, String method, String body, Map<String, String> headers){
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        if(!String.isBlank(body)){
            req.setBody(body);
        }
        if(headers !=null && headers.size()>0){
            for(String key : headers.keySet()){
                req.setHeader(key, headers.get(key));
            }
        }
        return req;
    }
    /**
     * description : Method to call out to an external service
     * @param req : HttpRequest
     * @return String : Response body
     */
    public static String callout(HttpRequest req){
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
    /**
     * description : Method to add to cache
     * @param key : Key
     * @param value : Value
     */
    public static void addToCache(String key, String value){
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.OrgCache');
        orgPart.put(key, value);
    }
    /**
     * description : Method to get from cache
     * @param key : Key
     * @return String : Value
     */

    public static String getFromCache(String key){
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.OrgCache');
        return (String)orgPart.get(key);
    }
}