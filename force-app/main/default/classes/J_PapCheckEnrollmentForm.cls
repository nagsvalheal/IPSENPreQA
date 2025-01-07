/**
 * @class J_PapCheckEnrollmentForm
 * @description This class handles the logic for checking if a PAP enrollment form is uploaded for active PAP records in the J_Charitable__c object.
 * The class ensures that the enrollment form is attached when a PAP becomes active and performs validation.
 */
public with sharing class J_PapCheckEnrollmentForm {
    
    /**
     * @method checkEnrollmentForm
     * @description This method checks if an enrollment form is attached when a PAP becomes active. It validates the form and ensures the required file is uploaded.
     * @param newList The new list of J_Charitable__c records that are being inserted or updated.
     * @param oldMap A map of existing J_Charitable__c records before the update (only used for comparison to detect status changes).
     */
       public void checkEnrollmentForm(List<J_Charitable__c> newList, Map<Id, J_Charitable__c> oldMap) {
            Map<Id, J_Charitable__c> newMap = createCharitableMap(newList);
            List<Id> papIds = collectActivePAPIds(newList, oldMap, newMap);
        
            if (!papIds.isEmpty()) {
                Map<Id, List<String>> filenamesByPapId = fetchFileNamesByPAPId(papIds);
                validateEnrollmentForms(newMap, filenamesByPapId);
            }
        }

    /**
     * @method createCharitableMap
     * @description Creates a map of J_Charitable__c records from a list, keyed by the record ID.
     * @param newList The list of new J_Charitable__c records to process.
     * @return Map<Id, J_Charitable__c> A map where the key is the J_Charitable__c record ID and the value is the record itself.
     */
        private Map<Id, J_Charitable__c> createCharitableMap(List<J_Charitable__c> newList) {
            Map<Id, J_Charitable__c> newMap = new Map<Id, J_Charitable__c>();
            for (J_Charitable__c pap : newList) {
                newMap.put(pap.Id, pap);
            }
            return newMap;
        }

    /**
     * @method collectActivePAPIds
     * @description Collects a list of PAP IDs that are newly marked as active or that have changed status to active.
     * @param newList The new list of J_Charitable__c records.
     * @param oldMap A map of old J_Charitable__c records before the update.
     * @param newMap A map of new J_Charitable__c records.
     * @return List<Id> A list of PAP record IDs that are active or newly active.
     */
        private List<Id> collectActivePAPIds(
            List<J_Charitable__c> newList, 
            Map<Id, J_Charitable__c> oldMap, 
            Map<Id, J_Charitable__c> newMap
        ) {
            List<Id> papIds = new List<Id>();
            for (J_Charitable__c pap : newMap.values()) {
                if (isNewActivePAP(pap, oldMap)) {
                    papIds.add(pap.Id);
                }
            }
            return papIds;
        }
        
    	/**
     * @method isNewActivePAP
     * @description Checks if a PAP has just become active or is newly marked as active.
     * @param pap The J_Charitable__c record being evaluated.
     * @param oldMap A map of old J_Charitable__c records for comparison.
     * @return Boolean Returns true if the PAP has become active, false otherwise.
     */
        private Boolean isNewActivePAP(J_Charitable__c pap, Map<Id, J_Charitable__c> oldMap) {
            if (oldMap == null && pap.J_CharitableStatus__c == 'Active' && pap.J_CharitableProgramType__c != 'TPAP') {
                pap.addError('PAP enrollment form is not attached. It is required when the PAP is active.');
                return false;
            } else if (
                oldMap != null && 
                pap.J_CharitableStatus__c != oldMap.get(pap.Id).J_CharitableStatus__c && 
                pap.J_CharitableStatus__c == 'Active' && 
                pap.J_CharitableProgramType__c != 'TPAP'
            ) {
                return true;
            }
            return false;
        }
        
    	/**
     * @method fetchFileNamesByPAPId
     * @description Fetches the file names of all documents linked to the specified PAP records.
     * @param papIds A list of PAP record IDs.
     * @return Map<Id, List<String>> A map where the key is the PAP ID and the value is a list of associated file names.
     */
        private Map<Id, List<String>> fetchFileNamesByPAPId(List<Id> papIds) {
            Map<Id, List<String>> filenamesByPapId = new Map<Id, List<String>>();
        String conditionIds = '(\'' + String.join(papIds, '\', \'') + '\')';
        // Define the fields to be selected
        String fields = 'Id, ContentDocument.Title, LinkedEntityId';
        
        // Define the conditions for the WHERE clause
        String conditions = 'LinkedEntityId IN ' + conditionIds;
        
        // Call the executeQuery method to fetch the data
        List<SObject> leadResults = COM_QueryUtility.executeQuery('ContentDocumentLink', fields, conditions, true);
        
        for (SObject sObj : leadResults) {
            // Cast SObject to ContentDocumentLink
            ContentDocumentLink cdl = (ContentDocumentLink) sObj;
            
            // Retrieve or initialize the list of file names for this LinkedEntityId
            List<String> fileNames = filenamesByPapId.containsKey(cdl.LinkedEntityId)
                ? filenamesByPapId.get(cdl.LinkedEntityId)
                : new List<String>();
            
            // Add the file name to the list
            fileNames.add(cdl.ContentDocument.Title);
            
            // Update the map
            filenamesByPapId.put(cdl.LinkedEntityId, fileNames);
        }
        return filenamesByPapId;
        
        }
        
    	/**
         * @method validateEnrollmentForms
         * @description Validates if the enrollment form is uploaded for each PAP record. If not, it adds an error to the record.
         * @param newMap A map of J_Charitable__c records to be validated.
         * @param filenamesByPapId A map of PAP IDs to the list of associated file names.
         */
        private void validateEnrollmentForms(Map<Id, J_Charitable__c> newMap, Map<Id, List<String>> filenamesByPapId) {
            // Convert the Set<Id> to a List<String> with explicit type conversion
            List<String> idList = new List<String>();
            for (Id id : newMap.keySet()) {
                idList.add(id.toString());
            }
            
            // Build the condition string
            String conditionIds = '(\'' + String.join(idList, '\', \'') + '\')';
            
            // Define the fields to be selected
            String fields = 'Id, Care_Program_Enrollee__c, Care_Program_Enrollee__r.Account.FirstName, Care_Program_Enrollee__r.Account.LastName';
            
            // Define the conditions for the WHERE clause
            String conditions = 'Id IN ' + conditionIds;
            
            // Call the executeQuery method to fetch the data
            List<SObject> charitableResults = COM_QueryUtility.executeQuery('J_Charitable__c', fields, conditions, true);
            
            for (SObject sObj : charitableResults) {
                // Cast SObject to J_Charitable__c
                J_Charitable__c papRecord = (J_Charitable__c) sObj;
                
                // Build the valid file name
                String validEnrollmentFileName = buildValidFileName(papRecord);
                
                // Check if the enrollment form is uploaded
                Boolean enrollmentFormUploaded = isEnrollmentFormUploaded(filenamesByPapId, papRecord.Id, validEnrollmentFileName);
                
                // Update the enrollment form field and add an error if needed
                J_Charitable__c updatedRecord = newMap.get(papRecord.Id);
                updatedRecord.Enrollment_Form_Uploaded__c = enrollmentFormUploaded;
                if (!enrollmentFormUploaded) {
                    updatedRecord.addError('PAP enrollment form is not attached. It is required when the PAP is active.');
                }
            }
        }
        
        
        /**
     * @method buildValidFileName
     * @description Builds the valid file name format for the enrollment form based on the PAP record.
     * @param papRecord The J_Charitable__c record being processed.
     * @return String The valid file name for the PAP enrollment form.
     */
        private String buildValidFileName(J_Charitable__c papRecord) {
            return papRecord.Care_Program_Enrollee__r.Account.FirstName + ' ' +
                   papRecord.Care_Program_Enrollee__r.Account.LastName + ' - PAP Enrollment Form';
        }
        
    /**
     * @method isEnrollmentFormUploaded
     * @description Checks if the enrollment form file has been uploaded for the specified PAP record.
     * @param filenamesByPapId A map of PAP IDs to lists of associated file names.
     * @param papId The ID of the PAP record to check.
     * @param validFileName The expected file name format for the enrollment form.
     * @return Boolean True if the valid enrollment form file is uploaded, false otherwise.
     */
        private Boolean isEnrollmentFormUploaded(Map<Id, List<String>> filenamesByPapId, Id papId, String validFileName) {
            if (filenamesByPapId.containsKey(papId)) {
                for (String fileName : filenamesByPapId.get(papId)) {
                    if (fileName == validFileName) {
                        return true;
                    }
                }
            }
            return false;
        }
}