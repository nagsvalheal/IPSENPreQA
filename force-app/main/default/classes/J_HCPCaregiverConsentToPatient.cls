/**
 * @class J_HCPCaregiverConsentToPatient
 * @description This class processes HCP caregiver consent, including caregiver creation, enrollee-caregiver linking, authorization form consent generation, 
 *              and consent document creation. The methods are optimized for security and bulk processing.
 * @author [Nandha]
 * @date [17/12/24]
 */
public without sharing class J_HCPCaregiverConsentToPatient {
	
   /**
 * @method processHCPCaregiverConsent
 * @description Main method to process HCP caregiver consent. Handles caregiver creation, enrollee-caregiver linking,
 *              authorization form consent generation, and consent document creation.
 * @param wrapper An instance of `J_HCPCaregiverConsentWrapper` containing all necessary data for the process.
 */
	public void processHCPCaregiverConsent(J_HCPCaregiverConsentWrapper wrapper) {
		try{
		Lead lead = wrapper.mapLead.get(wrapper.leadId);

		Id hcpCaregiverId = handleCaregiverProcessing(wrapper, lead);
		
		AuthorizationFormConsent afc = createAuthorizationFormConsent(
			lead,
			wrapper.careProgramEnrolleeID,
			wrapper.authFormTextId,
			wrapper.physicianID
		);

		insertAuthorizationFormConsent(afc);

		Consent_Doc__c consentDoc = createConsentDocument(afc);

		if (consentDoc.Id != null) {
			linkConsentDocumentToAttachment(consentDoc.Id, wrapper);
		}

		processPrescription(wrapper);

	} catch (Exception ex) {

		GenericLogger.exceptionLog('J_HCPCaregiverConsentToPatient', 'processHCPCaregiverConsent', ex);
	}
}
/**
 * Handles the processing of caregiver information related to a specific lead and program enrollee.
 *
 * @param wrapper The wrapper object containing caregiver consent and enrollee information.
 * @param lead The lead object containing caregiver details.
 * @return The ID of the processed caregiver.
 */
private Id handleCaregiverProcessing(J_HCPCaregiverConsentWrapper wrapper, Lead lead) {
	Id hcpCaregiverId = null;
	Id enrolleeLegalCaregiverID = null;
	Enrollee_Caregiver__c enrolleeCaregiverRecord;

	if (lead.J_Caregiver_Name_HCP__c != null && lead.J_Caregiver_Last_Name_HCP__c != null) {
		hcpCaregiverId = J_PatientLeadCaregiverProcessor.CheckCaregiverExist(
			wrapper.rectypeId,
			lead.J_Caregiver_Name_HCP__c,
			lead.J_Caregiver_Last_Name_HCP__c,
			lead.J_Caregiver_Email_HCP__c,
			lead.J_Caregiver_Phone_HCP__c,
			lead.J_Relationship_to_Patient_HCP__c,
			true
		);

		enrolleeLegalCaregiverID = checkEnrolleeCGExistHCP(
			wrapper.careProgramEnrolleeID,
			hcpCaregiverId,
			lead.J_Relationship_to_Patient_HCP__c,
			'',
			false
		);

		if (hcpCaregiverId == null) {
			hcpCaregiverId = createNewCaregiver(
				lead.J_Caregiver_Name_HCP__c,
				lead.J_Caregiver_Last_Name_HCP__c,
				lead.J_Caregiver_Email_HCP__c,
				lead.J_Caregiver_Phone_HCP__c,
				lead.J_Relationship_to_Patient_HCP__c,
				lead.J_Enter_Relationship_HCP__c,
				wrapper.rectypeId
			);
		}

		if (enrolleeLegalCaregiverID == null) {
			enrolleeCaregiverRecord = createNewEnrolleeCaregiver(
				wrapper.careProgramEnrolleeID,
				hcpCaregiverId,
				lead.J_Relationship_to_Patient_HCP__c,
				lead.J_Enter_Relationship_HCP__c
			);
			wrapper.lstEnroleeCaregiver.add(enrolleeCaregiverRecord);
		}

		if (!wrapper.lstEnroleeCaregiver.isEmpty()) {
			insert wrapper.lstEnroleeCaregiver;
		}
	}
	return hcpCaregiverId;
}
/**
 * Inserts the given AuthorizationFormConsent record into the database.
 *
 * @param afc The AuthorizationFormConsent object to be inserted.
 */
private void insertAuthorizationFormConsent(AuthorizationFormConsent afc) {
	COM_DatabaseOperationsUtility.insertOperation(
		new List<SObject>{afc},
		'processHCPCaregiverConsent',
		false
	);
}
/**
 * Creates a new Consent_Doc__c record associated with the given AuthorizationFormConsent.
 *
 * @param afc The AuthorizationFormConsent record to associate with the consent document.
 * @return The created Consent_Doc__c record.
 */
private Consent_Doc__c createConsentDocument(AuthorizationFormConsent afc) {
	Consent_Doc__c consentDoc = new Consent_Doc__c();
	consentDoc.Authorization_Form_Consent__c = afc.Id;
	consentDoc.Name = 'HCP Authorization Document';

	COM_DatabaseOperationsUtility.insertOperation(
		new List<SObject>{consentDoc},
		'processHCPCaregiverConsent',
		false
	);

	return consentDoc;
}
/**
 * Links the Consent_Doc__c record to attachments related to the lead(s) in the wrapper.
 *
 * @param consentDocId The ID of the Consent_Doc__c record to link.
 * @param wrapper The wrapper containing lead IDs and lead-attachment mappings.
 */
private void linkConsentDocumentToAttachment(Id consentDocId, J_HCPCaregiverConsentWrapper wrapper) {
	J_LeadConsentDocumentToAttachment.linkConsentDocumentToAttachment(
		consentDocId,
		wrapper.leadIds,
		wrapper.mapLead
	);
}
/**
 * Processes prescriptions associated with the caregiver consent and enrollee information in the wrapper.
 *
 * @param wrapper The wrapper containing enrollee and physician information.
 */
private void processPrescription(J_HCPCaregiverConsentWrapper wrapper) {
	Id accountId = fetchAccountFromCareProgramEnrollee(wrapper.careProgramEnrolleeID);

	if (accountId != null) {
		J_HCPLeadPrescriptionProcessor.processPrescription(
			wrapper,
			new List<Id>{accountId},
			wrapper.physicianID
		);
	}
}


/**
 * @method createNewCaregiver
 * @description Creates a new caregiver record based on the provided information.
 * @param firstName The first name of the caregiver.
 * @param lastName The last name of the caregiver.
 * @param email The email address of the caregiver.
 * @param phone The phone number of the caregiver.
 * @param relationship The relationship of the caregiver to the patient.
 * @param enterRelationship Additional details about the caregiver's relationship to the patient.
 * @param rectypeId The Record Type ID for the caregiver.
 * @return The ID of the newly created caregiver record.
 */
private Id createNewCaregiver(String firstName, String lastName, String email, String phone, String relationship, String enterRelationship, Id rectypeId) {
	Account caregiver = new Account(
		FirstName = firstName,
		LastName = lastName,
		PersonEmail = email,
		PersonMobilePhone = phone,
		J_RelationshipToPatient__c = relationship,
		J_EnterRelationship__c = enterRelationship,
		J_LegalGuardian__c = true,
		RecordTypeId = rectypeId
	);
	//insert caregiver;

	Database.SaveResult[] insertResults = COM_DatabaseOperationsUtility.insertOperation(
        new List<SObject>{caregiver}, 'Account', false
    );
	// return caregiver.Id;
	if (insertResults != null && insertResults[0].isSuccess()) {
        return insertResults[0].getId(); // Return the newly inserted Account ID
    }else {
        // Throw an exception or return null to satisfy return type
        throw new DMLException('Failed to insert Caregiver record.');
    }

   
}

/**
 * @method createNewEnrolleeCaregiver
 * @description Creates a new enrollee-caregiver relationship record.
 * @param careProgramEnrolleeID The ID of the Care Program Enrollee.
 * @param caregiverId The ID of the caregiver.
 * @param relationship The relationship of the caregiver to the patient.
 * @param enterRelationship Additional details about the caregiver's relationship to the patient.
 * @return An instance of `Enrollee_Caregiver__c` representing the new enrollee-caregiver relationship.
 */
private Enrollee_Caregiver__c createNewEnrolleeCaregiver(Id careProgramEnrolleeID, Id caregiverId, String relationship, String enterRelationship) {
	return new Enrollee_Caregiver__c(
		Care_Program_Enrollee__c = careProgramEnrolleeID,
		Caregiver__c = caregiverId,
		Relationship__c = relationship,
		EnterRelationship__c = enterRelationship,
		Consented_Caregiver__c = false,
		Status__c = 'Active'
	);
}

/**
 * @method createAuthorizationFormConsent
 * @description Creates an authorization form consent record for the HCP.
 * @param lead The `Lead` record associated with the consent process.
 * @param careProgramEnrolleeID The ID of the Care Program Enrollee.
 * @param authFormTextId The ID of the Authorization Form Text.
 * @param physicianID The ID of the physician involved in the consent process.
 * @return An instance of `AuthorizationFormConsent` representing the consent record.
 */
private AuthorizationFormConsent createAuthorizationFormConsent(Lead lead, Id careProgramEnrolleeID, Id authFormTextId, Id physicianID) {
	return new AuthorizationFormConsent(
		Name = 'HCP Authorization',
		AuthorizationFormTextId = authFormTextId,
		ConsentGiverId = careProgramEnrolleeID,
		Date_of_Consent_Received__c = lead.J_Consent_Effective_Date__c,
		ConsentCapturedDateTime = J_PatientLeadAuthformProcessor.convertDatetime(lead.J_Consent_Effective_Date__c),
		J_ConsentReceivedThrough__c = J_PatientLeadAuthformProcessor.consentSource(lead.LeadSource),
		Consented_by_Others__c = lead.Consented_by_Others__c,
		J_TypeOfConsent__c = 'HCP Authorization',
		J_ConsentStatus__c = 'In Progress',
		Physician__c = physicianID
	);
}


/**
 * @method checkEnrolleeCGExistHCP
 * @description Checks if an enrollee-caregiver relationship already exists for a given Care Program Enrollee and Caregiver.
 * @param careProgramEnroleeID The ID of the Care Program Enrollee.
 * @param careGiverID The ID of the caregiver.
 * @param relationshipToPatient The relationship of the caregiver to the patient.
 * @param enterRelationship Additional details about the relationship.
 * @param pLGConsent Indicates if the caregiver is a legal guardian.
 * @return The ID of the existing `Enrollee_Caregiver__c` record if found, otherwise `null`.
 */
public static id checkEnrolleeCGExistHCP(id careProgramEnroleeID,id careGiverID,string relationshipToPatient,string enterRelationship, Boolean pLGConsent)
{
	id recordID;
	Enrollee_Caregiver__c[] ecg = [select id,name from Enrollee_Caregiver__c WHERE Care_Program_Enrollee__c =:careProgramEnroleeID
								   AND Caregiver__c =:careGiverID 
								   AND Relationship__c =: relationshipToPatient
								   WITH SECURITY_ENFORCED];

   
	
	recordID = ecg.size() == 0 ? null : ecg[0].Id ;
	
	return recordID;
}

/**
 * @method fetchAccountFromCareProgramEnrollee
 * @description Fetches the `AccountId` associated with a given Care Program Enrollee.
 * @param careProgramEnrolleeID The ID of the Care Program Enrollee.
 * @return The `AccountId` of the enrollee if found, otherwise `null`.
 */

private Id fetchAccountFromCareProgramEnrollee(Id careProgramEnrolleeID) {
	try {
		// Query the CareProgramEnrollee for the associated Account
		
		String sObjectType = 'CareProgramEnrollee';
		String fields = 'AccountId';

		// Construct the condition dynamically, escaping single quotes
		String conditions = 'Id = \'' + escapeSingleQuotes(String.valueOf(careProgramEnrolleeID)) + '\'';

		// Execute the query using the helper method
		List<SObject> results = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);

		// Check if results are returned and fetch the AccountId
		if (!results.isEmpty()) {
			CareProgramEnrollee enrollee = (CareProgramEnrollee)results[0];
			return enrollee.AccountId;
		} else {
			return null;
		}

	} catch (Exception e) {
	   
		return null;
	}
}
private static String escapeSingleQuotes(String str) {
	return str.replaceAll('\'', '\\\'');
}
}