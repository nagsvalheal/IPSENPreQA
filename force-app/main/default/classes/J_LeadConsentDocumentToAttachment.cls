/**
 * @class ContentDocumentLinkManager
 * @description Manages operations related to linking Content Documents to various entities, such as consent documents.
 * Includes methods to clone and associate ContentDocumentLinks with specified entities.
 * @author [Nandha]
 */
public without sharing class J_LeadConsentDocumentToAttachment {

    /**
 * @method linkConsentDocumentToAttachment
 * @description Links an existing `ContentDocument` associated with a Lead to a new entity (e.g., Consent Document). 
 * This method clones the `ContentDocumentLink` and associates it with the provided `consentDocId`.
 * @param consentDocId The ID of the entity (e.g., Consent Document) to which the content document should be linked.
 * @param leadIds A list of Lead IDs whose `ContentDocumentLink` records are to be processed.
 * @param mapLead A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 * @throws DmlException If the insertion of the cloned `ContentDocumentLink` fails.
 */
public static void linkConsentDocumentToAttachment(Id consentDocId, List<Id> leadIds, Map<Id, Lead> mapLead) {
	List<ContentDocumentLink> lstContDocLink = new List<ContentDocumentLink>();
	ContentDocumentLink newContDocLink;
 
	if (ContentDocumentLink.SObjectType.getDescribe().isAccessible() &&
		Schema.SObjectType.ContentDocumentLink.fields.ContentDocumentId.isAccessible() &&
		Schema.SObjectType.ContentDocumentLink.fields.LinkedEntityId.isAccessible()) {
 
		lstContDocLink = [
			SELECT Id, ContentDocument.LastModifiedDate, LinkedEntityId
			FROM ContentDocumentLink
			WHERE LinkedEntityId IN :leadIds
			AND ContentDocument.Title = :mapLead.get(leadIds[0]).Expected_Enrollment_File_Name__c
			AND ContentDocument.FileExtension = 'PDF'
			AND LinkedEntity.Type = 'Lead'
			ORDER BY Id DESC
			LIMIT 1
		];
	}
 
	for (ContentDocumentLink link : lstContDocLink) {
		newContDocLink = link.clone(false, true, false, false);
		newContDocLink.LinkedEntityId = consentDocId;
		newContDocLink.ShareType = 'V';
	}
 
	if (newContDocLink != null && Schema.sObjectType.ContentDocumentLink.fields.LinkedEntityId.isCreateable()) {
		insert newContDocLink;
	  
	}
 }


}