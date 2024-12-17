/**
 * @description     A utility class for Dynamic Queries.
 * History
 * Version  Author      Date            Detail          Description.
 * 1.0      Abinsha     10-Jul-2024     Created         Initial development.
 */

 public inherited sharing class COM_QueryUtility {
    /**
    * @description Executes a dynamic SOQL query based on the provided object type, fields, conditions, and sharing rules.
    * @param sObjectType The Salesforce object type to query (e.g., 'Account', 'Contact').
    * @param fields The fields to select in the query, as a comma-separated string.
    * @param conditions The conditions to apply to the query (e.g., 'Name = \'Acme\''). If empty, no conditions are applied.
    * @param withUserMode Boolean flag to determine whether to enforce sharing rules by adding the WITH USER_MODE clause.
    * @return List<SObject> The list of Salesforce objects that match the query.
    */
    public static List<SObject> executeQuery(String sObjectType, String fields, String conditions, Boolean withUserMode) {
        // Start building the SOQL query string
        String query = 'SELECT ' + fields + ' FROM ' + sObjectType;
        
        if (!String.isBlank(conditions)) {
            conditions = escapeSingleQuotes(conditions);
            query += ' WHERE ' + conditions;
        }
        
        // Add the WITH SECURITY_ENFORCED clause to enforce sharing rules
        if (withUserMode) {
            query += ' WITH USER_MODE';
        }
        // Execute the query and return the results
        return Database.query(query);
    }
       
       /**
    * @description Escapes single quotes in a string by replacing them with escaped single quotes (\\\').
    * This is useful for constructing SOQL queries where single quotes are needed to encapsulate string literals.
    * @param str The string in which to escape single quotes.
    * @return The string with escaped single quotes.
    */
    private static String escapeSingleQuotes(String str) {
        return str.replaceAll('\'', '\\\'');
    }
       
       /**
    * @description Executes a dynamically constructed SOQL query with an optional `WITH USER_MODE` clause 
    * to enforce sharing rules. This method is particularly useful for complex queries that need to be built
    * and executed at runtime.
    * @param queryString The SOQL query string to execute.
    * @param withUserMode If true, appends the `WITH USER_MODE` clause to the query to enforce sharing rules.
    * @return A list of SObject records returned by the query.
    */
    public static List<SObject> executeComplexQuery(String queryString, Boolean withUserMode) {
        if (withUserMode) {
            queryString += ' WITH USER_MODE';
        }
        // Execute the query and return the results
        return Database.query(queryString);
    }
       
       /**
    * @description Executes a `COUNT()` SOQL query to count the number of records that match the specified criteria.
    * Optionally enforces sharing rules by appending the `WITH USER_MODE` clause to the query.
    * @param query The SOQL query string with the `COUNT()` function to execute.
    * @param withUserMode If true, appends the `WITH USER_MODE` clause to enforce sharing rules.
    * @return The number of records that match the query. Returns 0 if an exception occurs.
    */
    public static Integer getCount(String query,Boolean withUserMode) {
            if (withUserMode) {
            query += ' WITH USER_MODE';
            }
            return Database.countQuery(query);
    }
    /**
    * @description Retrieves the Record Type Id for a given object and record type developer name.
    * @param sObjectType The API name of the SObject type (e.g., 'Contact').
    * @param developerName The Developer Name of the record type (e.g., 'Physician').
    * @return The Record Type Id as an Id.
    */
    public static Id retrieveRecordTypeId(String sObjectType, String developerName) {
        // Retrieve the Record Type Id
        try {
            SObjectType objType = Schema.getGlobalDescribe().get(sObjectType);
            if (objType == null) {
                throw new IllegalArgumentException('Invalid SObject type: ' + sObjectType);
            }
            
            // Retrieve record type info by DeveloperName
            Map<String, Schema.RecordTypeInfo> recordTypeInfos = objType.getDescribe().getRecordTypeInfosByDeveloperName();
            if (!recordTypeInfos.containsKey(developerName)) {
                throw new IllegalArgumentException('Record Type not found: ' + developerName);
            }
            
            Id recordTypeId = recordTypeInfos.get(developerName).getRecordTypeId();
            return recordTypeId;
        } catch (Exception ex) {
            throw ex;
        }
    }
    /**
     * @description Executes a dynamic SOQL query based on the provided object type, fields, conditions, and sharing rules.
     * @param sObjectType The Salesforce object type to query (e.g., 'Account', 'Contact').
     * @param fields The fields to select in the query, as a comma-separated string.
     * @param conditions The conditions to apply to the query (e.g., 'Name = \'Acme\''). If empty, no conditions are applied.
     * @param withUserMode Boolean flag to determine whether to enforce sharing rules by adding the WITH USER_MODE clause.
     * @param orderByText holds the assigned field for order by clause.
     * @return List<SObject> The list of Salesforce objects that match the query.
     */
    public static List<SObject> executeQueryWithOrderBy(String sObjectType, String fields, String conditions, Boolean withUserMode, String orderByText) {
    
        // Start building the SOQL query string
        String query = 'SELECT ' + fields + ' FROM ' + sObjectType;
        if (!String.isBlank(conditions)) {
            conditions = escapeSingleQuotes(conditions);
            query += ' WHERE ' + conditions;
        }
        // Add the WITH USER_MODE clause to enforce sharing rules
        if (withUserMode) {
            query += ' WITH USER_MODE';
        }
        // Add the ORDER BY clause if provided
        if (!String.isBlank(orderByText)) {
            orderByText = escapeSingleQuotes(orderByText);
            query += ' ORDER BY ' + orderByText;
        }
        // Execute the query and return the results
        return Database.query(query);
    }
   
    /**
    * @description Executes a dynamically constructed SOQL query with an optional `WITH USER_MODE` clause 
    * to enforce sharing rules. This method is particularly useful for complex queries that need to be built
    * and executed at runtime.
    * @param queryString The SOQL query string to execute.
    * @param withUserMode If true, appends the `WITH USER_MODE` clause to the query to enforce sharing rules.
    * @param withOrderBy holds the assigned field for order by clause.
    * @return A list of SObject records returned by the query.
    */
    public static List<SObject> executeComplexQueryWithOrderBy(String queryString, Boolean withUserMode,String withOrderBy) {
        if (withUserMode) {
            queryString += ' WITH USER_MODE';
        }
        // Add the ORDER BY clause if provided
        if (!String.isBlank(withOrderBy)) {
            withOrderBy = escapeSingleQuotes(withOrderBy);
            queryString += ' ORDER BY ' + withOrderBy;
        }
        // Execute the query and return the results
        return Database.query(queryString);
    }

    public static String buildWhereClause(set<String> stringList){
        String finalString = '';
        for(String single : stringList){
            finalString += '\''+ single + '\'' + ',';
        }
        finalString = finalString.removeEnd(',');
        return '('+finalString+')';
    }  
}