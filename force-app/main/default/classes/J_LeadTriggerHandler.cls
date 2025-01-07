/**
 * @description Handler class for Lead trigger operations. 
 *              Handles sharing and unsharing of Lead records based on business requirements.
 */
public without sharing class J_LeadTriggerHandler {

    /**
     * @description Handles actions to be performed after Lead records are inserted.
     *              Prepares sharing details and delegates sharing logic to the helper class.
     * @param leadList List of newly inserted Lead records.
     */
    public void afterInsertMethod(List<Lead> leadList) {
    try {
        Map<String, Map<String, String>> mpLeadDetails = new Map<String, Map<String, String>>();
        Map<String, String> ldDetails = new Map<String, String>();

        for (Lead ld : leadList) {
            ldDetails = new Map<String, String>();

            // Check if the Care Program exists in the map and retrieve the related details
            if (mpLeadDetails.containsKey(ld.Care_Program__c)) {
                ldDetails = mpLeadDetails.get(ld.Care_Program__c);
            }

            // Add Lead details (ID and Owner ID) to the map
            ldDetails.put(ld.Id, ld.OwnerId);

            // Update the main map with Care Program as the key
            mpLeadDetails.put(ld.Care_Program__c, ldDetails);
        }
        // Check if mpLeadDetails is empty before proceeding
        if (!mpLeadDetails.isEmpty()) {
            // Delegate sharing logic to the helper class
            TeamSharing_HelperClass.insertShareRecords('Lead', 'LeadShare', mpLeadDetails);
        }

    } catch (Exception ex) {
        GenericLogger.debugLog('Error in afterInsertMethod: ' + ex.getMessage());
    }
}
    /**
     * @description Handles actions to be performed after Lead records are deleted.
     *              Collects IDs of deleted records and delegates unsharing logic to the helper class.
     * @param leadList List of deleted Lead records.
     */
    public void afterDeleteMethod(List<Lead> leadList) {
        try {
            Set<String> lstDeRecords = new Set<String>();

            // Collect IDs of deleted records
            for (Lead ld : leadList) {
                lstDeRecords.add(ld.Id);
            }

            // If there are records to process, delegate unsharing logic to the helper class
            if (!lstDeRecords.isEmpty()) {
                TeamSharing_HelperClass.DeleteSharingRecords('LeadShare', lstDeRecords);
            }
        } catch (Exception ex) {
            GenericLogger.debugLog('Error in afterDeleteMethod: ' + ex.getMessage());
        }
    }
}