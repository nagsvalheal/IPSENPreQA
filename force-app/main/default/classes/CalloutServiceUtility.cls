/**
 * @description  : Common class for all callout services
 * @author            : 
 * @group             : 
 * @last modified on  : 09-14-2023
 * 
**/
public with sharing class CalloutServiceUtility {
   /**
 * @description    Constructs and returns an `HttpRequest` object with the specified endpoint, method, body, and headers.
 *                 This utility method is used to build HTTP requests for RESTful web service interactions.
 * @param          endpoint String representing the URL to which the request is sent (e.g., an API endpoint).
 * @param          method String specifying the HTTP method (e.g., 'GET', 'POST', 'PUT', 'DELETE').
 * @param          body String containing the request body to be sent (optional, can be null or blank for methods like GET).
 * @param          headers Map<String, String> containing the key-value pairs of HTTP headers to include in the request (optional).
 * @return         HttpRequest The constructed HttpRequest object with the specified configurations.
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
 * @description    Executes an HTTP callout using the provided `HttpRequest` object and returns the response body as a string.
 *                 This method simplifies the process of sending an HTTP request and retrieving its response.
 * @param          req HttpRequest object that contains the endpoint, method, headers, and body for the HTTP request.
 * @return         String The response body returned by the HTTP callout. 
 *                 If the callout fails or returns an error, Salesforce will throw an exception.
 * @throws         System.CalloutException If there is an issue with the HTTP callout (e.g., timeout, invalid endpoint).
 */
    public static String callout(HttpRequest req){
        Http http = new Http();
        HTTPResponse res = http.send(req);
        return res.getBody();
    }
/**
 * @description    Adds a key-value pair to the Salesforce Org Cache within the 'local.OrgCache' partition.
 *                 This method is used to store data in the cache for quick retrieval.
 * @param          key String representing the key to associate with the cached value.
 * @param          value String representing the value to store in the cache.
 * @throws         NullPointerException If the cache partition does not exist or cannot be accessed.
 */
    public static void addToCache(String key, String value){
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.OrgCache');
        orgPart.put(key, value);
    }
/**
 * @description    Retrieves a value from the Salesforce Org Cache using the specified key.
 *                 This method is used to fetch cached data stored in the 'local.OrgCache' partition.
 * @param          key String representing the key used to look up the value in the cache.
 * @return         String The cached value associated with the provided key, or null if the key is not found.
 * @throws         NullPointerException If the cache partition does not exist or cannot be accessed.
 */

    public static String getFromCache(String key){
        Cache.OrgPartition orgPart = Cache.Org.getPartition('local.OrgCache');
        return (String)orgPart.get(key);
    }
}