/**
 * @description This class handles the logic for processing Appeal__c records before they are inserted.
 * It manages the population of the Care_Program_Enrollee__c field on the Appeal__c records
 * by associating it with the relevant CarePreauth records.
 * 
 * The logic works as follows:
 * - Collects the Authorization__c IDs from the provided Appeal__c records.
 * - Retrieves the corresponding CarePreauth records based on these IDs.
 * - Updates the Care_Program_Enrollee__c field of the Appeal__c records if a valid association is found.
 */
public without sharing class J_AppealTriggerHandler {  
    
    /**
     * Before insert trigger handler for Appeal__c records.
     * 
     * @description This method processes the provided list of Appeal__c records, collecting Authorization IDs, 
     * retrieving the associated CarePreauth records, and then populating the Care_Program_Enrollee__c 
     * field on the Appeal__c records if applicable.
     * 
     * @param appealList The list of Appeal__c records being inserted.
     */
    public void beforeInsertMethod(List<Appeal__c> appealList) {
        try {
        List<Id> authorizationIds = collectAuthorizationIds(appealList);
        
        if (!authorizationIds.isEmpty()) {
            Map<Id, CarePreauth> authMap = getAuthorizationMap(authorizationIds);
            updateCareProgramEnrollee(appealList, authMap);
        	}
        }catch (DMLException e) {
            GenericLogger.exceptionLog('J_AppealTriggerHandler', 'beforeInsertMethod', e);
        }
    }
    
    /**
     * Collect Authorization IDs from the provided list of Appeal__c records.
     * 
     * @description This helper method iterates over the Appeal__c records and collects the IDs of any 
     * related Authorization__c records.
     * 
     * @param appealList The list of Appeal__c records to process.
     * @return A list of Authorization IDs associated with the Appeal__c records.
     */
    private List<Id> collectAuthorizationIds(List<Appeal__c> appealList) {
        List<Id> authorizationIds = new List<Id>();
        for (Appeal__c appeal : appealList) {
            if (appeal.Authorization__c != null) {
                authorizationIds.add(appeal.Authorization__c);
            }
        }
        return authorizationIds;
    }

    /**
     * Retrieve CarePreauth records based on the provided list of Authorization IDs.
     * 
     * @description This method queries the CarePreauth records that are associated with the given 
     * Authorization IDs, and maps them by their ID for later processing.
     * 
     * @param authorizationIds The list of Authorization IDs.
     * @return A map of CarePreauth records, keyed by their ID.
     */
    public Map<Id, CarePreauth> getAuthorizationMap(List<Id> authorizationIds) {
            // Define the fields to select and the conditions for the query
            String fields = 'Id, J_CoverageBenefit__r.Care_Program_Enrollee__c';
            
            // Convert the list of Ids to a string format suitable for dynamic SOQL
            String conditions = 'Id IN (\'' + String.join(authorizationIds, '\',\'') + '\')';  
        
            Boolean withUserMode = true; // Whether to enforce sharing rules
            
            // Execute the dynamic SOQL query using the COM_QueryUtility class
            List<SObject> results = COM_QueryUtility.executeQuery('CarePreauth', fields, conditions, withUserMode);
            
            // Convert the result into a Map<Id, CarePreauth>
            Map<Id, CarePreauth> authMap = new Map<Id, CarePreauth>();
            for (SObject obj : results) {
                CarePreauth carePreauth = (CarePreauth) obj; 
                authMap.put(carePreauth.Id, carePreauth);
            }
        
            return authMap;
        }
    
    /**
     * Update the Care_Program_Enrollee__c field on the provided list of Appeal__c records.
     * 
     * @description This method checks whether each Appeal__c record has a valid Authorization__c ID 
     * and a corresponding CarePreauth record. If both are found, it updates the 
     * Care_Program_Enrollee__c field on the Appeal__c record with the value from the 
     * CarePreauth record's J_CoverageBenefit__r.Care_Program_Enrollee__c field.
     * 
     * @param appealList The list of Appeal__c records to update.
     * @param authMap A map of CarePreauth records, keyed by their Authorization ID.
     */
    private void updateCareProgramEnrollee(List<Appeal__c> appealList, Map<Id, CarePreauth> authMap) {
            for (Appeal__c appeal : appealList) {
                if (appeal.Authorization__c != null && authMap.containsKey(appeal.Authorization__c)) {
                    CarePreauth carePreauth = authMap.get(appeal.Authorization__c);
                    
                    // Add null check for carePreauth and the nested fields
                    if (carePreauth != null && carePreauth.J_CoverageBenefit__c != null 
                        && carePreauth.J_CoverageBenefit__r != null 
                        && carePreauth.J_CoverageBenefit__r.Care_Program_Enrollee__c != null) {
                        
                        // Update Care_Program_Enrollee__c on the Appeal__c record
                        appeal.Care_Program_Enrollee__c = carePreauth.J_CoverageBenefit__r.Care_Program_Enrollee__c;
                    }
                }
                
            }
        }
}