/**
 * @description Handles operations related to sending and saving faxes for LWC components.
 * class mentioned as With sharing because it's related to SendFaxLwc
 */
public with sharing class J_SendFaxLwcHandler {
	/**
	 * @description Retrieves fax files associated with a specific record.
	 * @param recordId The ID of the record for which to fetch associated fax files.
	 * @return A list of ContentDocument records associated with the given record.
	 * @throws AuraHandledException if an error occurs during execution.
	 */

	@AuraEnabled(cacheable=true)
	public static List<ContentDocument> getRecFaxFiles(Id recordId) {
		try {
			// Retrieve query string based on the record type
			String query = getReceivedFaxQuery(recordId);
			if (String.isBlank(query)) {
				return new List<ContentDocument>();
			}

			// Query Received_Fax__c records
			List<Received_Fax__c> receivedFaxes = Database.query(query);

			// Extract ContentDocumentIds from Received_Fax__c records
			Set<Id> contentDocumentIds = getContentDocumentIds(receivedFaxes);

			// Query ContentDocuments based on the ContentDocumentIds
			return J_SendFaxRelatedHandler.fetchContentDocuments(
				contentDocumentIds
			);
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
	/**
	 * @description Constructs a dynamic SOQL query based on the type of the record.
	 * @param recordId The ID of the record to determine its type.
	 * @return A dynamic SOQL query string or null if no query is found.
	 */
	private static String getReceivedFaxQuery(Id recordId) {
		Map<Schema.SObjectType, String> queryMap = new Map<Schema.SObjectType, String>{
			Schema.CareProgramEnrollee.SObjectType => 'SELECT Id FROM Received_Fax__c WHERE Care_Program_Enrollee__c = :recordId',
			Schema.Case.SObjectType => 'SELECT Id FROM Received_Fax__c WHERE AE_PQC__c = :recordId',
			Schema.CoverageBenefit.SObjectType => 'SELECT Id FROM Received_Fax__c WHERE Coverage_Benefit__c = :recordId',
			Schema.CarePreauth.SObjectType => 'SELECT Id FROM Received_Fax__c WHERE Prior_Authorization__c = :recordId',
			Schema.Appeal__c.SObjectType => 'SELECT Id FROM Received_Fax__c WHERE Appeal__c = :recordId',
			Schema.J_Copay__c.SObjectType => 'SELECT Id FROM Received_Fax__c WHERE Copay__c = :recordId',
			Schema.J_Charitable__c.SObjectType => 'SELECT Id FROM Received_Fax__c WHERE PAP_TPAP__c = :recordId'
		};

		Schema.SObjectType objectType = recordId.getSObjectType();
		return queryMap.get(objectType);
	}
	/**
	 * @description Extracts ContentDocument IDs from Received_Fax__c records.
	 * @param receivedFaxes A list of Received_Fax__c records.
	 * @return A set of ContentDocument IDs associated with the fax records.
	 */
	private static Set<Id> getContentDocumentIds(
		List<Received_Fax__c> receivedFaxes
	) {
		Set<Id> contentDocumentIds = new Set<Id>();
		for (Received_Fax__c recFax : receivedFaxes) {
			String sObjectType = 'ContentDocumentLink';
			String fields = 'ContentDocumentId';
			String conditions = 'LinkedEntityId = \'' + recFax.Id + '\'';

			List<ContentDocumentLink> documentLinks = (List<ContentDocumentLink>) COM_QueryUtility.executeQuery(
				sObjectType,
				fields,
				conditions,
				true
			);
			for (ContentDocumentLink link : documentLinks) {
				contentDocumentIds.add(link.ContentDocumentId);
			}
		}
		return contentDocumentIds;
	}
	/**
	 * @description Retrieves a list of ContentDocument files associated with CoverageBenefit records linked to the specified record ID.
	 *              This method is cacheable and can be used in Lightning Aura or LWC components.
	 *
	 * @param recordId The ID of the record (e.g., CareProgramEnrollee) for which associated CoverageBenefit files need to be fetched.
	 *
	 * @return A list of ContentDocument records containing file details such as ID, Title, ContentSize, and FileType.
	 */

	@AuraEnabled(cacheable=true)
	public static List<ContentDocument> getCBenefitFiles(Id recordId) {
		Set<Id> contentDocumentIds = new Set<Id>();

		Schema.SObjectType objectType = recordId.getSobjectType();
		String query;
		// Query CoverageBenefit records related to the enrollee
		if (objectType == Schema.CareProgramEnrollee.SObjectType) {
			query = 'SELECT Id FROM CoverageBenefit WHERE Care_Program_Enrollee__c = :recordId';
		}

		List<CoverageBenefit> coverageBenefitlist = Database.query(query);

		// Loop through the CoverageBenefit records
		for (CoverageBenefit cb : coverageBenefitlist) {
			// Query ContentDocumentLinks related to each CoverageBenefit record
			String sObjectType = 'ContentDocumentLink';
			String fields = 'ContentDocumentId';
			String conditions = 'LinkedEntityId = \'' + cb.Id + '\'';

			List<ContentDocumentLink> documentLinks = (List<ContentDocumentLink>) COM_QueryUtility.executeQuery(
				sObjectType,
				fields,
				conditions,
				true
			);

			// Add the ContentDocumentIds to the set
			for (ContentDocumentLink link : documentLinks) {
				contentDocumentIds.add(link.ContentDocumentId);
			}
		}

		// Query ContentDocuments based on the ContentDocumentIds
		String conditionIds =
			'(\'' +
			String.join(contentDocumentIds, '\', \'') +
			'\')';
		// Define the fields to be selected
		String fields = 'Id, Title, ContentSize, FileType';

		// Define the conditions for the WHERE clause
		String conditions = 'Id IN' + conditionIds;

		// Call the executeQuery method to fetch the data
		List<SObject> cbFiles = COM_QueryUtility.executeQuery(
			'ContentDocument',
			fields,
			conditions,
			true
		);
		return cbFiles;
	}
	/**
	 * @description Retrieves a list of ContentDocument records associated with AuthorizationFormConsent records
	 *              linked to a specified CareProgramEnrollee record. The method navigates relationships from
	 *              AuthorizationFormConsent to Consent_Doc__c and then to ContentDocument records.
	 *
	 * @param recordId The ID of the CareProgramEnrollee record for which associated ContentDocuments are to be retrieved.
	 *                 Must be of type CareProgramEnrollee.
	 * @return A list of ContentDocument records associated with the provided CareProgramEnrollee.
	 *         Returns an empty list if no related ContentDocument records are found.
	 * @throws AuraHandledException If any error occurs during the query or processing.
	 */

	@AuraEnabled(cacheable=true)
	public static List<ContentDocument> getConsentFiles(Id recordId) {
		Set<Id> contentDocumentIds = new Set<Id>();

		Schema.SObjectType objectType = recordId.getSobjectType();
		String query;
		// Query Consent records related to the enrollee
		if (objectType == Schema.CareProgramEnrollee.SObjectType) {
			query = 'SELECT Id FROM AuthorizationFormConsent WHERE Care_Program_Enrollee__c = :recordId';
		}

		List<AuthorizationFormConsent> consentlist = Database.query(query);

		// Loop through the AuthorizationFormConsent records
		for (AuthorizationFormConsent consent : consentlist) {
			String sObjectTypeCon = 'Consent_Doc__c';
			String fieldsCon = 'id';
			String conditionsCon =
				'Authorization_Form_Consent__c = \'' +
				consent.Id +
				'\'';

			List<Consent_Doc__c> consentDoc = (List<Consent_Doc__c>) COM_QueryUtility.executeQuery(
				sObjectTypeCon,
				fieldsCon,
				conditionsCon,
				true
			);

			//List<Consent_Doc__c> consentDoc = [select id from Consent_Doc__c where Authorization_Form_Consent__c = :consent.id];

			for (Consent_Doc__c doc : consentDoc) {
				// Query ContentDocumentLinks related to each AuthorizationFormConsent record
				String sObjectType = 'ContentDocumentLink';
				String fields = 'ContentDocumentId';
				String conditions = 'LinkedEntityId = \'' + doc.Id + '\'';

				List<ContentDocumentLink> documentLinks = (List<ContentDocumentLink>) COM_QueryUtility.executeQuery(
					sObjectType,
					fields,
					conditions,
					true
				);

				// Add the ContentDocumentIds to the set
				for (ContentDocumentLink link : documentLinks) {
					contentDocumentIds.add(link.ContentDocumentId);
				}
			}
		}

		// Query ContentDocuments based on the ContentDocumentIds
		String conditionIds =
			'(\'' +
			String.join(contentDocumentIds, '\', \'') +
			'\')';
		// Define the fields to be selected
		String fields = 'Id, Title, ContentSize, FileType';

		// Define the conditions for the WHERE clause
		String conditions = 'Id IN' + conditionIds;

		// Call the executeQuery method to fetch the data
		List<SObject> consentFiles = COM_QueryUtility.executeQuery(
			'ContentDocument',
			fields,
			conditions,
			true
		);
		return consentFiles;
	}

	/**
	 * @description Sends a fax to the specified fax number with the provided documents.
	 * @param orgNumber The organization's fax number.
	 * @param faxNumber The destination fax number.
	 * @param contentDocumentIds A list of ContentDocument IDs to be faxed.
	 * @return The fax ID returned by the eFax service.
	 * @throws Exception if an error occurs during the fax sending process.
	 */

	@AuraEnabled
	public static String sendFax(
		String orgNumber,
		String faxNumber,
		List<Id> contentDocumentIds
	) {
		List<EFaxCalloutService.Destination> destinations = new List<EFaxCalloutService.Destination>();
		List<EFaxCalloutService.Document> documents = new List<EFaxCalloutService.Document>();
		EFaxCalloutService.Destination destination = new EFaxCalloutService.Destination();
		String userId = null;

		destination.to_name = '';
		destination.to_company = '';
		destination.fax_number = faxNumber; //'15189667118';
		destinations.add(destination);

		EFaxCalloutService.FaxOptions faxOptions = new EFaxCalloutService.FaxOptions();
		faxOptions.image_resolution = 'FINE';
		faxOptions.include_cover_page = false;
		faxOptions.custom_CSID = orgNumber;

		// Get the files user selects and query the content version
		List<String> contentDocumentIdsAsStringList = new List<String>();
		for (Id idValue : contentDocumentIds) {
			contentDocumentIdsAsStringList.add(String.valueOf(idValue));
		}

		// Convert List<String> to a single comma-separated string
		String contentDocumentIdsAsString = String.join(
			contentDocumentIdsAsStringList,
			','
		);
		String sObjectType = 'ContentVersion';
		String fields = 'Id,VersionData,FileType';
		String conditions =
			'ContentDocumentId = \'' +
			contentDocumentIdsAsString +
			'\'';
		List<ContentVersion> documentLinks = (List<ContentVersion>) COM_QueryUtility.executeQuery(
			sObjectType,
			fields,
			conditions,
			true
		);
		for (ContentVersion cv : documentLinks) {
			EFaxCalloutService.Document document = new EFaxCalloutService.Document();
			document.document_type = cv.FileType;
			document.document_content = EncodingUtil.base64Encode(
				cv.VersionData
			);
			documents.add(document);
		}
		String sObjectTypeEFax = 'EFax_Setting__mdt';
		String fieldsEFax = 'User_Id__c';
		String conditionsEFax = 'MasterLabel = \'' + orgNumber + '\'';
		List<EFax_Setting__mdt> eFaxSet = (List<EFax_Setting__mdt>) COM_QueryUtility.executeQuery(
			sObjectTypeEFax,
			fieldsEFax,
			conditionsEFax,
			true
		);

		for (EFax_Setting__mdt efaxSetting : eFaxSet) {
			userId = efaxSetting.User_Id__c;
		}

		return EFaxCalloutService.sendFax(
			destinations,
			documents,
			faxOptions,
			userId
		);
	}
	/**
	 * @description Saves a fax record to the Sent_Fax__c object, associates related content documents,
	 *              and handles fax sending and permissions validations.
	 *
	 * @param faxDetails An instance of the FaxDetails class containing fax metadata,
	 *                   including the record ID and selected file IDs to be linked to the fax record.
	 * @param faxNumber The recipient's fax number.
	 * @param orgFaxNum The organization's fax number used to send the fax.
	 * @return A string message indicating the result of the operation:
	 *         - 'Fax saved successfully.' if the operation succeeds.
	 *         - An error message if an exception occurs or the user lacks the required permissions.
	 * @throws AuraHandledException If any error occurs during the save or link process.
	 */

	@AuraEnabled
	public static String saveFax(
		FaxDetails faxDetails,
		String faxNumber,
		String orgFaxNum
	) {
		try {
			// Check if the user has create access on Sent_Fax__c
			if (!Schema.sObjectType.Sent_Fax__c.isCreateable()) {
				return 'Error: You do not have permission to create a fax record.';
			}

			// Call sendFax to generate a fax ID
			String faxId = sendFax(
				orgFaxNum,
				faxNumber,
				faxDetails.selectedFiles
			);

			// Initialize the Sent_Fax__c record
			Sent_Fax__c sentFax = initializeSentFax(
				faxDetails,
				faxId,
				faxNumber,
				orgFaxNum
			);

			// Set relationships for the sentFax record
			setRelationships(faxDetails.recordId, sentFax);

			// Perform the DML operation only after CRUD validation
			insert sentFax;

			// Ensure the user has appropriate permissions to link content documents
			if (
				faxDetails.selectedFiles != null &&
				!faxDetails.selectedFiles.isEmpty()
			) {
				J_SendFaxRelatedHandler.linkContentDocuments(
					faxDetails.selectedFiles,
					sentFax.Id
				);
			}

			return 'Fax saved successfully.';
		} catch (Exception e) {
			return 'Error saving fax: ' + e.getMessage();
		}
	}

	/**
	 * @description Initializes and returns a new Sent_Fax__c record with the provided details, including fax metadata.
	 *
	 * @param faxDetails An instance of the FaxDetails class containing metadata about the fax,
	 *                   including the send date/time, delivery date/time, and recipient information.
	 * @param faxId The unique identifier of the fax generated by the sendFax method.
	 * @param faxNumber The recipient's fax number.
	 * @param orgFaxNum The organization's fax number used to send the fax.
	 * @return A Sent_Fax__c instance populated with the provided fax details.
	 */

	private static Sent_Fax__c initializeSentFax(
		FaxDetails faxDetails,
		String faxId,
		String faxNumber,
		String orgFaxNum
	) {
		return new Sent_Fax__c(
			Fax_Number__c = faxNumber,
			Fax_Id__c = faxId,
			Send_Date_Time__c = faxDetails.sendDateTime,
			Delivery_Date_Time__c = faxDetails.deliveryDateTime,
			Organisation_Fax_number__c = orgFaxNum,
			To__c = faxDetails.to
		);
	}

	/**
	 * @description Sets relationships for a Sent_Fax__c record based on the record type.
	 * @param recordId The ID of the related record.
	 * @param sentFax The Sent_Fax__c record to associate with the related record.
	 */
	// Helper method to set relationships based on record type
	private static void setRelationships(Id recordId, Sent_Fax__c sentFax) {
		Schema.SObjectType objectType = recordId.getSobjectType();

		if (objectType == Schema.CareProgramEnrollee.SObjectType) {
			sentFax.Care_Program_Enrollee__c = recordId;
		} else if (objectType == Schema.Case.SObjectType) {
			J_SendFaxRelatedHandler.setCaseRelationship(recordId, sentFax);
		} else if (objectType == Schema.CoverageBenefit.SObjectType) {
			J_SendFaxRelatedHandler.setCoverageBenefitRelationship(
				recordId,
				sentFax
			);
		} else if (objectType == Schema.CarePreauth.SObjectType) {
			J_SendFaxRelatedHandler.setCarePreauthRelationship(
				recordId,
				sentFax
			);
		} else if (objectType == Schema.Appeal__c.SObjectType) {
			J_SendFaxRelatedHandler.setAppealRelationship(recordId, sentFax);
		} else if (objectType == Schema.J_Copay__c.SObjectType) {
			J_SendFaxRelatedHandler.setCopayRelationship(recordId, sentFax);
		} else if (objectType == Schema.J_Charitable__c.SObjectType) {
			J_SendFaxRelatedHandler.setCharitableRelationship(
				recordId,
				sentFax
			);
		}
	}
	/**
	 * @description       : Retrieves a list of files associated with the given record ID by querying related ContentDocumentLink
	 *                      and ContentDocument records.
	 * @param recordId    : The ID of the record for which the associated files are to be retrieved.
	 * @return            : A list of ContentDocument objects representing the related files.
	 */
	@AuraEnabled(cacheable=true)
	public static List<ContentDocument> getRelatedFiles(Id recordId) {
		// Query related ContentDocumentLink records
		String sObjectType = 'ContentDocumentLink';
		String fields = 'ContentDocumentId';
		String conditions = 'LinkedEntityId = \'' + recordId + '\'';

		List<ContentDocumentLink> links = (List<ContentDocumentLink>) COM_QueryUtility.executeQuery(
			sObjectType,
			fields,
			conditions,
			true
		);

		Set<Id> contentDocumentIds = new Set<Id>();
		for (ContentDocumentLink link : links) {
			contentDocumentIds.add(link.ContentDocumentId);
		}

		// Query ContentDocument records based on the ContentDocumentIds
		String conditionIds =
			'(\'' +
			String.join(contentDocumentIds, '\', \'') +
			'\')';
		// Define the fields to be selected
		String fieldsDoc = 'Id, Title, ContentSize, FileType';

		// Define the conditions for the WHERE clause
		String conditionsDoc = 'Id IN' + conditionIds;

		// Call the executeQuery method to fetch the data
		List<SObject> files = COM_QueryUtility.executeQuery(
			'ContentDocument',
			fieldsDoc,
			conditionsDoc,
			true
		);

		return files;
	}
	/**
	 * @description Represents the details of a fax to be sent, including metadata such as file attachments,
	 *              recipient information, and timestamps for sending and delivery.
	 *
	 * @property selectedFiles A list of IDs representing the files to be sent as part of the fax.
	 * @property recordId The ID of the associated record (e.g., Case, Contact, etc.) linked to the fax.
	 * @property sendDateTime The date and time when the fax is scheduled to be sent.
	 * @property deliveryDateTime The date and time when the fax is expected to be delivered.
	 * @property to The recipient's name or additional recipient details.
	 *
	 * @constructor Initializes a new instance of the FaxDetails class with the provided metadata.
	 *
	 * @param selectedFiles A list of file IDs to attach to the fax.
	 * @param recordId The associated record ID linked to the fax.
	 * @param sendDateTime The scheduled send date and time.
	 * @param deliveryDateTime The expected delivery date and time.
	 * @param to The recipient's name or details.
	 */ 	
	public class FaxDetails {
	@AuraEnabled public List<Id> selectedFiles;
    @AuraEnabled public Id recordId;
    @AuraEnabled public Datetime sendDateTime;
    @AuraEnabled public Datetime deliveryDateTime;
    @AuraEnabled public String to;

    /**
 	* @description Default constructor for the FaxDetails class. Initializes an instance with default values.
 	*
 	*/
    public FaxDetails() {
        // Initialize default values (optional, depending on your needs)
        this.selectedFiles = new List<Id>();
        this.recordId = null;
        this.sendDateTime = null;
        this.deliveryDateTime = null;
        this.to = '';
    }
		/**
		 * @description Constructor for the FaxDetails class. Initializes an instance with the provided parameters.
		 *
		 * @param selectedFiles A list of IDs representing the files selected for faxing.
		 * @param recordId The ID of the related record (e.g., Account, Opportunity, etc.).
		 * @param sendDateTime The date and time when the fax is scheduled to be sent.
		 * @param deliveryDateTime The date and time when the fax is expected to be delivered.
		 * @param to The recipient of the fax.
		 */
		public FaxDetails(
			List<Id> selectedFiles,
			Id recordId,
			DateTime sendDateTime,
			DateTime deliveryDateTime,
			String to
		) {
			this.selectedFiles = selectedFiles;
			this.recordId = recordId;
			this.sendDateTime = sendDateTime;
			this.deliveryDateTime = deliveryDateTime;
			this.to = to;
		}
	}
}