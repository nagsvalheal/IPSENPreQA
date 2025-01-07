/**
 * @description A handler class for processing EmailMessage trigger events. 
 *              It facilitates the creation of `Email_Data__c` records based on EmailMessage data
 *              and its related records in Salesforce.
 *
 * @usage This class should be invoked by an EmailMessage trigger to process EmailMessages
 *        and create associated Email Data records with enriched information from related objects.
 */
public WITH SHARING class EmailMessageTriggerHandler {
    /**
     * @description Creates `Email_Data__c` records from a list of EmailMessage objects. 
     *              Enriches Email Data with information from related objects and inserts the data into the system.
     *
     * @param newEmailMessages A list of EmailMessage objects that need to be processed.
     * @return A list of `Email_Data__c` records created from the input EmailMessage objects.
     * 
     * @throws AuraHandledException if any error occurs during record creation or related data enrichment.
     */
    public static List<Email_Data__c> createEmailData(List<EmailMessage> newEmailMessages) {
        List<Email_Data__c> emailDataList = new List<Email_Data__c>();

        // Collect RelatedToId by object type for batch SOQL queries
        Map<Id, String> relatedToIdsByType = new Map<Id, String>();
        for (EmailMessage message : newEmailMessages) {
            if (message.RelatedToId != null) {
                relatedToIdsByType.put(message.RelatedToId, String.valueOf(message.RelatedToId.getSObjectType()));
            }
        }

        // Query related records in batches based on type
        Map<Id, SObject> relatedRecords = queryRelatedRecords(relatedToIdsByType);

        for (EmailMessage message : newEmailMessages) {
            Email_Data__c emailData = new Email_Data__c();
            emailData.Subject__c = message.Subject;
            emailData.Statuses__c = Decimal.valueOf(message.Status);
            emailData.To_Address__c = message.ToAddress;
            emailData.Send_Date_Time__c = message.MessageDate;
            emailData.Sent_email_ID__c = message.Id;

            try {
                emailData.Messages__c = message.TextBody != null ? message.TextBody.stripHtmlTags() : null;
            } catch (Exception ex) {
                GenericLogger.exceptionLog(ex);
            }

            if (message.RelatedToId != null) {
                String objectType = relatedToIdsByType.get(message.RelatedToId);
                SObject relatedRecord = relatedRecords.get(message.RelatedToId);

                if (relatedRecord != null) {
                    assignRelatedData(emailData, objectType, relatedRecord);
                }
            }

            emailDataList.add(emailData);
        }

        if (!emailDataList.isEmpty()) {

            COM_DatabaseOperationsUtility.insertOperation(emailDataList,'EmailMessageTriggerHandler',true);
        }

        return emailDataList;
    }
/**
     * @description Queries related records for a batch of IDs grouped by object type. 
     *              Uses dedicated query methods for each object type.
     *
     * @param relatedToIdsByType A map where keys are IDs of related records and values are their object types.
     * @return A map of related records with IDs as keys and SObject records as values.
     */
    private static Map<Id, SObject> queryRelatedRecords(Map<Id, String> relatedToIdsByType) {
    Map<Id, SObject> records = new Map<Id, SObject>();

    // Group related IDs by type
    Map<String, Set<Id>> idsByObjectType = groupIdsByObjectType(relatedToIdsByType);

    // Query each type in a dedicated method
    records.putAll(queryCareProgram(idsByObjectType.get('CareProgramEnrollee')));
    records.putAll(queryCharitable(idsByObjectType.get('J_Charitable__c')));
    records.putAll(queryCopay(idsByObjectType.get('J_Copay__c')));
    records.putAll(queryAppeal(idsByObjectType.get('Appeal__c')));
    records.putAll(queryCarePreauth(idsByObjectType.get('CarePreauth')));
    records.putAll(queryCoverageBenefit(idsByObjectType.get('CoverageBenefit')));
    records.putAll(queryCases(idsByObjectType.get('Case')));

    return records;
}

private static Map<String, Set<Id>> groupIdsByObjectType(Map<Id, String> relatedToIdsByType) {
    Map<String, Set<Id>> idsByObjectType = new Map<String, Set<Id>>();

    for (Id id : relatedToIdsByType.keySet()) {
        String objectType = relatedToIdsByType.get(id);
        if (!idsByObjectType.containsKey(objectType)) {
            idsByObjectType.put(objectType, new Set<Id>());
        }
        idsByObjectType.get(objectType).add(id);
    }

    return idsByObjectType;
}

private static Map<Id, SObject> queryCareProgram(Set<Id> careProgramIds) {
    Map<Id, SObject> records = new Map<Id, SObject>();
    if (!careProgramIds.isEmpty()) {
       List <CareProgramEnrollee> cpEnrollee =COM_QueryUtility.executeQuery('CareProgramEnrollee', 'Id, Name', 'Id IN :\''+careProgramIds+'\'',false);

        for (CareProgramEnrollee record : cpEnrollee) { 
            records.put(record.Id, record);
        }
    }
    return records;
}

private static Map<Id, SObject> queryCharitable(Set<Id> charitableIds) {
    Map<Id, SObject> records = new Map<Id, SObject>();
    if (!charitableIds.isEmpty()) {
        List <J_Charitable__c> charitable =COM_QueryUtility.executeQuery('J_Charitable__c', 'Id, Name', 'Id IN :\''+charitableIds+'\'',false);
        for (J_Charitable__c record : charitable) {
            records.put(record.Id, record);
        }
    }
    return records;
}

private static Map<Id, SObject> queryCopay(Set<Id> copayIds) {
    Map<Id, SObject> records = new Map<Id, SObject>();
    if (!copayIds.isEmpty()) {
        List <J_Copay__c> copay =COM_QueryUtility.executeQuery('J_Copay__c', 'Id, Name', 'Id IN :\''+copayIds+'\'',false);
        for (J_Copay__c record : copay) {
            records.put(record.Id, record);
        }
    }
    return records;
}

private static Map<Id, SObject> queryAppeal(Set<Id> appealIds) {
    Map<Id, SObject> records = new Map<Id, SObject>();
    if (!appealIds.isEmpty()) {
        List <Appeal__c> appeal =COM_QueryUtility.executeQuery('Appeal__c', 'Id, Name', 'Id IN :\''+appealIds+'\'',false);
        for (Appeal__c record : appeal) {
            records.put(record.Id, record);
        }
    }
    return records;
}

private static Map<Id, SObject> queryCarePreauth(Set<Id> preauthIds) {
    Map<Id, SObject> records = new Map<Id, SObject>();
    if (!preauthIds.isEmpty()) {
        List <CarePreauth> carePreauth =COM_QueryUtility.executeQuery('CarePreauth', 'Id, Name', 'Id IN :\''+preauthIds+'\'',false);
        for (CarePreauth record : carePreauth) {
            records.put(record.Id, record);
        }
    }
    return records;
}

private static Map<Id, SObject> queryCoverageBenefit(Set<Id> coverageBenefitIds) {
    Map<Id, SObject> records = new Map<Id, SObject>();
    if (!coverageBenefitIds.isEmpty()) {
        List <CoverageBenefit> coverageBenefit =COM_QueryUtility.executeQuery('CoverageBenefit', 'Id, Name', 'Id IN :\''+coverageBenefitIds+'\'',false);
        for (CoverageBenefit record : coverageBenefit) {
            records.put(record.Id, record);
        }
    }
    return records;
}

private static Map<Id, SObject> queryCases(Set<Id> caseIds) {
    Map<Id, SObject> records = new Map<Id, SObject>();
    if (!caseIds.isEmpty()) {
        List <Case> caseRecords =COM_QueryUtility.executeQuery('Case', 'Id, ContactEmail, RecordType.Name', 'Id IN :\''+caseIds+'\'',false);
        for (Case record : caseRecords) {
            records.put(record.Id, record);
        }
    }
    return records;
}


    private static void assignRelatedData(Email_Data__c emailData, String objectType, SObject relatedRecord) {
        switch on objectType {
            when 'CareProgramEnrollee' {
                CareProgramEnrollee record = (CareProgramEnrollee)relatedRecord;
                emailData.Care_Program_Enrollee__c = record.Id;
                emailData.Related_To__c = record.Name;
            }
            when 'J_Charitable__c' {
                J_Charitable__c record = (J_Charitable__c)relatedRecord;
                emailData.PAP_TPAP__c = record.Id;
                emailData.Related_To__c = record.Name;
            }
            when 'J_Copay__c' {
                J_Copay__c record = (J_Copay__c)relatedRecord;
                emailData.Copay__c = record.Id;
                emailData.Related_To__c = record.Name;
            }
            when 'Appeal__c' {
                Appeal__c record = (Appeal__c)relatedRecord;
                emailData.Appeal__c = record.Id;
                emailData.Related_To__c = record.Name;
            }
            when 'CarePreauth' {
                CarePreauth record = (CarePreauth)relatedRecord;
                emailData.Prior_Authorization__c = record.Id;
                emailData.Related_To__c = record.Name;
            }
            when 'CoverageBenefit' {
                CoverageBenefit record = (CoverageBenefit)relatedRecord;
                emailData.Coverage_Benefit__c = record.Id;
                emailData.Related_To__c = record.Name;
            }
            when 'Case' {
                Case record = (Case)relatedRecord;
                emailData.Related_To__c = record.ContactEmail;

                String recordTypeName = record.RecordType.Name;
                if (recordTypeName == 'AE and PQC') {
                    emailData.AEPQC__c = record.Id;
                } else if (recordTypeName == 'Product Replacement') {
                    emailData.Product_Replacement__c = record.Id;
                }
            }
        }
    }
}