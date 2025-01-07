/**
 * @description A utility class to manage relationships and document linking for Sent Fax records.
 */
public with sharing class J_SendFaxRelatedHandler {
    /**
         * @description Sets the relationship between a Sent Fax and a Case record based on the Case's RecordType.
         * @param recordId The ID of the Case record.
         * @param sentFax The Sent_Fax__c record to associate with the Case.
         */    
        // Individual relationship helper methods
    public static void setCaseRelationship(Id recordId, Sent_Fax__c sentFax) { 
                String sObjectType = 'Case';
                  String fields = 'Id, Care_Program_Enrollee__c, RecordType.DeveloperName';
                String conditions = 'id = :\'' + recordId + '\'';
            
                List<Case> cases=(List<Case>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
                Case relatedCase = cases[0];
        if (relatedCase.RecordType.DeveloperName == 'AE_and_PQC') {
            sentFax.AE_PQC__c = recordId;
            sentFax.Care_Program_Enrollee__c = relatedCase.Care_Program_Enrollee__c;
        } else if (relatedCase.RecordType.DeveloperName == 'Product_Replacement') {
            sentFax.Product_Replacement__c = recordId;
            sentFax.Care_Program_Enrollee__c = relatedCase.Care_Program_Enrollee__c;
        }
    }
    /**
         * @description Sets the relationship between a Sent Fax and a CoverageBenefit record.
         * @param recordId The ID of the CoverageBenefit record.
         * @param sentFax The Sent_Fax__c record to associate with the CoverageBenefit.
         */
    public static void setCoverageBenefitRelationship(Id recordId, Sent_Fax__c sentFax) {
                String sObjectType = 'CoverageBenefit';
                  String fields = 'Id, Care_Program_Enrollee__c';
                String conditions = 'id = :\'' + recordId + '\'';
            
                List<CoverageBenefit> cob=(List<CoverageBenefit>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
                CoverageBenefit cb = cob[0];
        sentFax.Coverage_Benefit__c = recordId;
        sentFax.Care_Program_Enrollee__c = cb.Care_Program_Enrollee__c;
    }
    /**
     * @description Sets the relationship between a CarePreauth record and a Sent Fax record.
     *              This method retrieves CarePreauth details and updates the Sent Fax record with relevant information.
     * 
     * @param recordId The ID of the CarePreauth record to be linked.
     * @param sentFax The Sent Fax object to be updated with CarePreauth details.
     * @throws QueryException If the CarePreauth record cannot be found or multiple records are returned.
     * @throws NullPointerException If the result of the query is empty or null.
     */
    public static void setCarePreauthRelationship(Id recordId, Sent_Fax__c sentFax) {
                String sObjectType = 'CarePreauth';
                  String fields = 'Id, Care_Program_Enrollee__c';
                String conditions = 'id = :\'' + recordId + '\'';
            
                List<CarePreauth> cps=(List<CarePreauth>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
                CarePreauth cp = cps[0];
        sentFax.Prior_Authorization__c = recordId;
        sentFax.Care_Program_Enrollee__c = cp.Care_Program_Enrollee__c;
    }
    /**
         * @description Sets the relationship between a Sent Fax and a CarePreauth record.
         * @param recordId The ID of the CarePreauth record.
         * @param sentFax The Sent_Fax__c record to associate with the CarePreauth.
         */
    public static void setAppealRelationship(Id recordId, Sent_Fax__c sentFax) {
                String sObjectType = 'Appeal__c';
                  String fields = 'Id, Care_Program_Enrollee__c';
                String conditions = 'id = :\'' + recordId + '\'';
            
                List<Appeal__c> apps=(List<Appeal__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
                Appeal__c app = apps[0];
        sentFax.Appeal__c = recordId;
        sentFax.Care_Program_Enrollee__c = app.Care_Program_Enrollee__c;
    }
    /**
         * @description Sets the relationship between a Sent Fax and an Appeal record.
         * @param recordId The ID of the Appeal record.
         * @param sentFax The Sent_Fax__c record to associate with the Appeal.
         */
    public static void setCopayRelationship(Id recordId, Sent_Fax__c sentFax) {
                String sObjectType = 'J_Copay__c';
                  String fields = 'Id, Care_Program_Enrollee__c';
                String conditions = 'id = :\'' + recordId + '\'';
            
                List<J_Copay__c> cops=(List<J_Copay__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
                J_Copay__c cop = cops[0];
        sentFax.Copay__c = recordId;
        sentFax.Care_Program_Enrollee__c = cop.Care_Program_Enrollee__c;
    }
    /**
         * @description Sets the relationship between a Sent Fax and a J_Copay__c record.
         * @param recordId The ID of the J_Copay__c record.
         * @param sentFax The Sent_Fax__c record to associate with the J_Copay__c record.
         */
    public static void setCharitableRelationship(Id recordId, Sent_Fax__c sentFax) {
                String sObjectType = 'J_Charitable__c';
                  String fields = 'Id, Care_Program_Enrollee__c';
                String conditions = 'id = :\'' + recordId + '\'';
            
                List<J_Charitable__c> paps=(List<J_Charitable__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
                J_Charitable__c pap = paps[0];
        sentFax.PAP_TPAP__c = recordId;
        sentFax.Care_Program_Enrollee__c = pap.Care_Program_Enrollee__c;
    }
    /**
     * @description Links a list of selected content document files to a specific entity (e.g., a sent fax record).
     * 
     * @param selectedFiles A list of IDs representing the content documents to be linked.
     * @param sentFaxId The ID of the Sent Fax record to which the content documents will be linked.
     * @throws DmlException If there is an issue during the insertion of ContentDocumentLink records.
     */
    public static void linkContentDocuments(List<Id> selectedFiles, Id sentFaxId) {
        List<ContentDocumentLink> fileLinks = new List<ContentDocumentLink>();
        for (Id fileId : selectedFiles) {
            fileLinks.add(new ContentDocumentLink(
                ContentDocumentId = fileId,
                LinkedEntityId = sentFaxId,
                ShareType = 'V'
            ));
        }
        Database.SaveResult[] insertResults = COM_DatabaseOperationsUtility.insertOperation(fileLinks, 'J_SendFaxRelatedHandler', true);
        GenericLogger.debugLog('insertResults'+insertResults);
    }
        /**
         * @description Fetches ContentDocument records based on a set of ContentDocument IDs.
         * @param contentDocumentIds A set of ContentDocument IDs.
         * @return A list of ContentDocument records.
         */
    public static List<ContentDocument> fetchContentDocuments(Set<Id> contentDocumentIds) {
        if (contentDocumentIds.isEmpty()) {
            return new List<ContentDocument>();
        }
        // Convert Set<Id> to List<String> for String.join()
        List<String> contentDocumentIdStrings = new List<String>();
        for (Id id : contentDocumentIds) {
            contentDocumentIdStrings.add(id);
        }
        
        // Prepare query parameters
        String sObjectType = 'ContentDocument';
        String fields = 'Id, Title, ContentSize, FileType';
        String conditions = 'Id IN (\'' + String.join(contentDocumentIdStrings, '\', \'') + '\')';
        
        // Use the common query utility to execute the query
        return (List<ContentDocument>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
    }
    }