public without sharing class ConvertLeadToPatient {
/**
 * @method convertLead
 * @description Converts a list of Lead records into corresponding Person Accounts and performs necessary updates and related processing.
 * This includes fetching Leads, converting them to Accounts, updating Accounts, creating Care Program Enrollees, and processing related caregivers or healthcare providers.
 * @param lstLeadID A list of Lead record IDs to be converted.
 * @return A list of Account IDs corresponding to the successfully converted Leads.
 * @throws Exception If an error occurs during the lead conversion process.
 */
@InvocableMethod(label='Convert Lead to Patient' description='Converts the Lead to Person Account (Patient)' category='Lead')
public static List<Id> convertLead(List<Id> lstLeadID) {
	Savepoint sp = Database.setSavepoint();
	try {
	   

		// Step 1: Fetch Lead Records
		Map<Id, Lead> mapLead = fetchLeadRecords(lstLeadID);

		// Step 2: Convert Leads
		Map<Id, Id> leadToAccountMap = convertLeads(lstLeadID);

		// Step 3: Fetch Accounts for Converted Leads
		Map<Id, Account> accountMap = fetchAccountsForConvertedLeads(leadToAccountMap);

		// Step 4: Prepare and Update Accounts
		updateConvertedAccounts(mapLead, leadToAccountMap, accountMap);

		// Step 5: Create and Insert Care Program Enrollees
		List<CareProgramEnrollee> enrolleesToInsert = createCareProgramEnrollees(mapLead, leadToAccountMap);
		insertEnrollees(enrolleesToInsert);

		// Step 6: Process Caregivers or Healthcare Providers
		return processCaregiversOrHealthcareProviders(mapLead, leadToAccountMap, enrolleesToInsert);

	} catch (Exception e) {
		Database.rollback(sp);
		
		throw e;
	}
}

/**
 * @method fetchLeadRecords
 * @description Fetches Lead records from the database based on the provided list of Lead IDs. The method constructs a dynamic SOQL query to retrieve 
 * the specified fields and converts the result into a Map of Lead records, keyed by their IDs.
 * @param lstLeadID A list of Lead record IDs to fetch from the database.
 * @return A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 * @throws Exception If the query execution fails or if there are issues with the provided Lead IDs.
 */
private static Map<Id, Lead> fetchLeadRecords(List<Id> lstLeadID) {
   
	 String fields = 'Id, Name, FirstName, MiddleName, J_Date_of_Birth__c, Street, City, State, PostalCode, Country, ' +
	'J_Prescriber_Preferred_Method_of_Contact__c, Other_diagnosis__c, J_Secondary_ICD_10_Code__c, ' +
	'J_Home_Phone__c, J_Cell_Phone__c, J_Work_Phone__c, Preferred_Phone__c, J_Account_Owner_User_CCTOwner__c, J_Sex__c, ' +
	'J_Consent_Effective_Date__c, Consented_by_Others__c, J_Patient_Is_Patient_Insured__c, ' +
	'J_Consent_text_message__c, J_Consent_voice_call__c, J_Consent_email__c, J_Consent_mail__c, J_Consent_marketing_info__c, ' +
	'RecordType.DeveloperName, Expected_Enrollment_File_Name__c, Preferred_Language__c, ' +
	'J_Caregiver_Name_HCP__c, J_Caregiver_Last_Name_HCP__c, J_Caregiver_Email_HCP__c, J_Caregiver_Phone_HCP__c, ' +
	'J_Relationship_to_Patient_HCP__c, J_Enter_Relationship_HCP__c, ' +
	'Care_Program__c, Care_Program__r.name, LeadSource, ' +
	'Best_Time_to_Contact__c, AnnualHouseholdincome__c, Numberofpeopleinhousehold0__c, ' +
	'PreferredSpecialtyPharmacy0__c, RxSent__c, SpecialtyPharmacyName__c, J_Primary_Diagnosis__c, J_Primary_ICD_10_Code__c, DateofDiagnosisMMDDYY__c, ' +
	'J_Pruritus__c, PFIC_type__c, Kg_weight__c, J_Date_Measured__c, ' +
	'Prior_Authorization_if_known__c, Prior_Authorization_Effective_Dates__c, Additional_Considerations__c';

 // Convert the list of Ids to a list of Strings
 List<String> leadIdsAsString = new List<String>();
 for (Id leadId : lstLeadID) {
	leadIdsAsString.add('\'' + escapeSingleQuotes(leadId.toString()) + '\'');
 }

 // Construct the conditions
 String conditions = 'Id IN (' + String.join(leadIdsAsString, ', ') + ')';

// Execute the query
List<SObject> leadRecords = COM_QueryUtility.executeQuery('Lead', fields, conditions, false);

// Convert the list of SObjects to a Map<Id, Lead>
Map<Id, Lead> mapLead = new Map<Id, Lead>();
for (SObject record : leadRecords) {
mapLead.put(record.Id, (Lead)record);
}

return mapLead;
}
private static String escapeSingleQuotes(String str) {
	return str.replaceAll('\'', '\\\'');
}

/**
 * @method convertLeads
 * @description Converts a list of Lead records into corresponding Accounts by leveraging Salesforce's Lead Conversion API.
 * This method ensures that each Lead in the provided list is converted successfully and returns a mapping of Lead IDs to their corresponding Account IDs.
 * @param lstLeadID A list of Lead record IDs to be converted.
 * @return A map of Lead IDs to Account IDs, where each Lead ID is mapped to the Account ID created during the conversion.
 * @throws Database.LeadConvertException If the Lead conversion process encounters errors for any record.
 */
private static Map<Id, Id> convertLeads(List<Id> lstLeadID) {
	List<Database.LeadConvert> leadConversions = new List<Database.LeadConvert>();
	for (Id leadID : lstLeadID) {
		Database.LeadConvert lc = new Database.LeadConvert();
		lc.setLeadId(leadID);
		lc.setConvertedStatus('Completed');
		lc.bypassAccountDedupeCheck = false;
		lc.bypassContactDedupeCheck = false;
		leadConversions.add(lc);
	}
	List<Database.LeadConvertResult> conversionResults = Database.convertLead(leadConversions);

	Map<Id, Id> leadToAccountMap = new Map<Id, Id>();
	for (Database.LeadConvertResult result : conversionResults) {
		if (result.isSuccess()) {
			leadToAccountMap.put(result.getLeadId(), result.getAccountId());
		}
	}
	return leadToAccountMap;
}

/**
 * @method fetchAccountsForConvertedLeads
 * @description Retrieves Account records corresponding to the converted Lead-to-Account mappings. 
 * This method constructs a dynamic SOQL query to fetch specified Account fields and returns the result as a Map.
 * @param leadToAccountMap A map where the key is the Lead ID and the value is the Account ID created during the Lead conversion.
 * @return A map of Account records, where the key is the Account ID and the value is the corresponding Account record.
 * @throws Exception If the query execution fails or the provided Account IDs are invalid.
 */
private static Map<Id, Account> fetchAccountsForConvertedLeads(Map<Id, Id> leadToAccountMap) {
   
	String fields = 'Id, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, ' +
	'PersonMailingCountry, J_WrittenLanguage__c, J_SpokenLanguage__c, Preferred_Contact_Method__pc, ' +
	'Home_Work_Mobile__pc, PersonHomePhone, PersonMobilePhone, PersonOtherPhone, J_PrimaryAddress__c, ' +
	'Patient_Status__pc, J_Sex_Account__c, J_Best_Time_to_Contact__pc, Approximate_Household_Income__c, ' +
	'J_NumberOfPeopleInHousehold__c, OwnerId';
	List<String> accountIds = new List<String>();
	for (Id accountId : leadToAccountMap.values()) {
		accountIds.add('\'' + escapeSingleQuotes(accountId.toString()) + '\'');
	}
// Construct the conditions
String conditions = 'Id IN (' + String.join(accountIds, ', ') + ')';

// Execute the query
List<SObject> accountRecords = COM_QueryUtility.executeQuery('Account', fields, conditions, true);

// Convert the list of SObjects to a Map<Id, Account>
Map<Id, Account> accountMap = new Map<Id, Account>();
for (SObject record : accountRecords) {
accountMap.put(record.Id, (Account)record);
}

return accountMap;
}

/**
 * @method updateConvertedAccounts
 * @description Updates Account records that were converted from Leads. This method uses the Lead data to update corresponding Account fields and ensures all updates are applied in bulk.
 * @param mapLead A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 * @param leadToAccountMap A map where the key is the Lead ID and the value is the Account ID created during the Lead conversion.
 * @param accountMap A map of Account records, where the key is the Account ID and the value is the corresponding Account record fetched after conversion.
 * @throws DmlException If the update operation fails for any Account record.
 */
private static void updateConvertedAccounts(Map<Id, Lead> mapLead, Map<Id, Id> leadToAccountMap, Map<Id, Account> accountMap) {
	List<Account> accountsToUpdate = new List<Account>();
	String recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
						.get('J_Journeys_Patient').getRecordTypeId();

	for (Id leadId : leadToAccountMap.keySet()) {
		Id accountId = leadToAccountMap.get(leadId);
		Account accountToUpdate = accountMap.get(accountId);
		if (accountToUpdate != null) {
			Lead lead = mapLead.get(leadId);
			updateAccountFromLead(accountToUpdate, lead, recordTypeId);
			accountsToUpdate.add(accountToUpdate);
		}
	}
	if (!accountsToUpdate.isEmpty() && Schema.sObjectType.Account.fields.PersonBirthdate.isUpdateable()) {
		update accountsToUpdate;
	}
}

/**
 * @method createCareProgramEnrollees
 * @description Creates a list of `CareProgramEnrollee` records based on the provided mapping of Leads to Accounts. 
 * Each enrollee is created using data from a Lead and its corresponding Account ID.
 * @param mapLead A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 * @param leadToAccountMap A map where the key is the Lead ID and the value is the Account ID created during the Lead conversion.
 * @return A list of `CareProgramEnrollee` objects ready for insertion.
 */
private static List<CareProgramEnrollee> createCareProgramEnrollees(Map<Id, Lead> mapLead, Map<Id, Id> leadToAccountMap) {
	List<CareProgramEnrollee> enrolleesToInsert = new List<CareProgramEnrollee>();
	for (Id leadId : leadToAccountMap.keySet()) {
		Lead lead = mapLead.get(leadId);
		Id accountId = leadToAccountMap.get(leadId);
		enrolleesToInsert.add(createCareProgramEnrollee(lead, accountId));
	}
	return enrolleesToInsert;
}
/**
 * @method insertEnrollees
 * @description Inserts a list of `CareProgramEnrollee` records into the database. Utilizes a utility method to handle the insertion process, including error handling and logging.
 * @param enrolleesToInsert A list of `CareProgramEnrollee` objects to be inserted into the database.
 * @throws DmlException If the insertion fails for any reason.
 */
private static void insertEnrollees(List<CareProgramEnrollee> enrolleesToInsert) {
	if (!enrolleesToInsert.isEmpty()) {
	  
	   COM_DatabaseOperationsUtility.insertOperation(enrolleesToInsert, 'ConvertLeadToPatient', true);
	}
}

/**
 * @method updateAccountFromLead
 * @description Updates an Account record with data from a corresponding Lead record. Sets specific fields on the Account based on Lead data, including contact details, birthdate, and language preferences. Additionally, updates the Account's record type and owner if applicable.
 * @param account The `Account` object to be updated.
 * @param lead The `Lead` object containing the data to update the Account.
 * @param recordTypeId The Record Type ID to set on the Account.
 * @throws NullPointerException If the `account` or `lead` objects are null.
 */
private static void updateAccountFromLead(Account account, Lead lead, String recordTypeId) {
	account.Preferred_Contact_Method__pc = lead.J_Prescriber_Preferred_Method_of_Contact__c;
	account.Home_Work_Mobile__pc = J_PatientLeadAuthformProcessor.convertData(lead.Preferred_Phone__c);
	account.PersonHomePhone = lead.J_Home_Phone__c;
	account.PersonMobilePhone = lead.J_Cell_Phone__c;
	account.PersonOtherPhone = lead.J_Work_Phone__c;
	account.RecordTypeId = recordTypeId;
	account.OwnerId = lead.J_Account_Owner_User_CCTOwner__c != null ? lead.J_Account_Owner_User_CCTOwner__c : account.OwnerId;
	account.PersonBirthdate = lead.J_Date_of_Birth__c;
	account.J_Sex_Account__c = lead.J_Sex__c;
	account.J_PrimaryAddress__c = 'Mailing';
	account.Patient_Status__pc = 'Active';
	account.J_SpokenLanguage__c = lead.Preferred_Language__c;
	account.J_WrittenLanguage__c = lead.Preferred_Language__c;
	account.MiddleName = lead.MiddleName;
	account.Middle_Name__pc = lead.MiddleName;
	account.J_Best_Time_to_Contact__pc = lead.Best_Time_to_Contact__c;
	account.Approximate_Household_Income__c = lead.AnnualHouseholdincome__c;
	account.J_NumberOfPeopleInHousehold__c = lead.Numberofpeopleinhousehold0__c;
	if (lead.J_Account_Owner_User_CCTOwner__c != null) {
		account.OwnerId = lead.J_Account_Owner_User_CCTOwner__c;
		 account.J_was_owner_changed__c = true ;
	}
}

/**
 * @method createCareProgramEnrollee
 * @description Creates a `CareProgramEnrollee` record based on data from a Lead and its corresponding Account ID. 
 * Sets various fields on the enrollee, including name, status, and source system, based on the Lead's data.
 * @param lead The `Lead` object containing the data to create the `CareProgramEnrollee`.
 * @param accountId The ID of the `Account` associated with the `CareProgramEnrollee`.
 * @return A `CareProgramEnrollee` object populated with data from the Lead and Account.
 */
private static CareProgramEnrollee createCareProgramEnrollee(Lead lead, Id accountId) {
	CareProgramEnrollee cpe = new CareProgramEnrollee();
	cpe.Name = lead.FirstName + '-' + lead.Care_Program__r.Name;
	cpe.CareProgramId = lead.Care_Program__c;
	cpe.AccountId = accountId;
	cpe.Status = 'Pending';
	cpe.Sub_Status__c = 'New Enrollment';
	cpe.SourceSystem = lead.LeadSource;

	if (lead.RecordType.DeveloperName == 'Patients_Caregivers') {
		cpe.LeadId = lead.Id;
	} else {
		cpe.HCP_Lead__c = lead.Id;
	}

	return cpe;
}

/**
 * @method processCaregiversOrHealthcareProviders
 * @description Processes caregivers or healthcare providers based on the provided Lead data, converted Accounts, and Care Program Enrollees. 
 * Handles different logic paths depending on the Lead record type (e.g., `Patients_Caregivers`) and manages consent or healthcare provider-specific processing.
 * @param mapLead A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 * @param leadToAccountMap A map where the key is the Lead ID and the value is the Account ID created during Lead conversion.
 * @param enrolleesToInsert A list of `CareProgramEnrollee` objects created for the Leads.
 * @return A list of Account or Care Program Enrollee IDs processed during the operation.
 */
public static List<Id> processCaregiversOrHealthcareProviders(Map<Id, Lead> mapLead, Map<Id, Id> leadToAccountMap, List<CareProgramEnrollee> enrolleesToInsert) {
	List<Id> careProgramEnrolleeIds = new List<Id>();
	for (CareProgramEnrollee enrollee : enrolleesToInsert) {
		careProgramEnrolleeIds.add(enrollee.Id);
	}

	Id careProgramId = mapLead.values().isEmpty() ? null : mapLead.values()[0].Care_Program__c;
	String leadRecordType = mapLead.values().isEmpty() ? null : mapLead.values()[0].RecordType.DeveloperName;

	if (leadRecordType == 'Patients_Caregivers') {
		handleCaregiversAndConsentProcessing(
			careProgramEnrolleeIds,
			careProgramId,
			leadRecordType,
			new List<Id>(leadToAccountMap.keySet()),
			mapLead,
			leadToAccountMap
		);
		return new List<Id>(leadToAccountMap.values());
	} else {
		Map<Id, Id> leadToEnrolleeMap = mapLeadToEnrolleeMap(leadToAccountMap, careProgramEnrolleeIds);
		for (Id leadId : leadToEnrolleeMap.keySet()) {
			J_HcpLeadConvertTopatient.processHealthcareProviders(leadId, leadToEnrolleeMap.get(leadId), mapLead);
		}
		return new List<Id>(leadToEnrolleeMap.values());
	}
}
/**
 * @method mapLeadToEnrolleeMap
 * @description Creates a mapping between Lead IDs and Care Program Enrollee IDs. 
 * This method aligns each Lead with a corresponding Care Program Enrollee based on their index positions in the provided collections.
 * @param leadToAccountMap A map where the key is the Lead ID and the value is the Account ID created during Lead conversion.
 * @param careProgramEnrolleeIds A list of Care Program Enrollee IDs created for the Leads.
 * @return A map where the key is the Lead ID and the value is the corresponding Care Program Enrollee ID.
 */

private static Map<Id, Id> mapLeadToEnrolleeMap(Map<Id, Id> leadToAccountMap, List<Id> careProgramEnrolleeIds) {
	Map<Id, Id> leadToEnrolleeMap = new Map<Id, Id>();
	List<Id> leadIds = new List<Id>(leadToAccountMap.keySet());
	for (Integer i = 0; i < leadIds.size(); i++) {
		if (i < careProgramEnrolleeIds.size()) {
			leadToEnrolleeMap.put(leadIds[i], careProgramEnrolleeIds[i]);
		}
	}
	return leadToEnrolleeMap;
}
/**
 * @method handleCaregiversAndConsentProcessing
 * @description Handles processing of caregivers and consent for the provided Leads. 
 * This includes processing caregiver data, fetching required caregiver details, handling consent processing, and processing lead insurance information.
 * @param careProgramEnrolleeIds A list of Care Program Enrollee IDs to be processed.
 * @param careProgramId The ID of the Care Program associated with the Leads.
 * @param leadRecordType The record type of the Leads being processed (e.g., 'Patients_Caregivers').
 * @param leadIds A list of Lead IDs for which consent and caregiver processing are performed.
 * @param mapLead A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 * @param leadToAccountMap A map where the key is the Lead ID and the value is the Account ID created during Lead conversion.
 */
public static void handleCaregiversAndConsentProcessing(
	List<Id> careProgramEnrolleeIds, 
	Id careProgramId, 
	String leadRecordType, 
	List<Id> leadIds, 
	Map<Id, Lead> mapLead,
	Map<Id, Id> leadToAccountMap
) {
	// Step 1: Process Caregivers and Consented Contacts
   
	J_PatientLeadCaregiverProcessor.processCaregiversAndConsents(careProgramEnrolleeIds, careProgramId, leadRecordType, leadIds);

	// Fetch the Enrollee Legal Caregiver ID for Consent Processing
	Id enrolleeLegalCaregiverId = fetchEnrolleeLegalCaregiverId(careProgramEnrolleeIds[0]); // Assumes one enrollee ID for simplicity
   

	// Step 2: Process Lead Consent based on the created caregivers
  
	Id authFormTextId = getAuthFormText(careProgramId, 'Journeys Authorization Form', 'Journeys Authorization Form Text');
	J_PatientLeadAuthformProcessor.processLeadConsent(leadIds, mapLead, authFormTextId, careProgramEnrolleeIds[0], enrolleeLegalCaregiverId);
   // Process Lead Insurance Informatio
	
	for (Id leadId : leadIds) {
		if (mapLead.containsKey(leadId)) {
			Id accountId = leadToAccountMap.get(leadId);// Assuming ConvertedAccountId is available in Lead object
			J_PatientLeadInsuranceProcessor.processLeadInsurance(mapLead, leadIds, accountId);
		}
	}

}
/**
 * @method getAuthFormText
 * @description Retrieves or creates an `AuthorizationFormText` record for a given Care Program. If the record does not exist, 
 * a new one is created with default values and associated with the specified `AuthorizationForm`.
 * @param careProgramId The ID of the Care Program to which the Authorization Form is associated.
 * @param authFormName The name of the `AuthorizationForm` to be retrieved or associated with the `AuthorizationFormText`.
 * @param authFormTextName The name of the `AuthorizationFormText` to be retrieved or created.
 * @return The ID of the `AuthorizationFormText` record.
 */

public static id getAuthFormText (id careProgramId, string authFormName, string authFormTextName )
	{

		
		id authFormID = getAuthForm (careProgramId, authFormName);
		
		List<AuthorizationFormText> aftList = [SELECT Id, Name FROM AuthorizationFormText WHERE Name = :authFormTextName 
											   /*AND AuthorizationForm.Name =:authFormName */
											   LIMIT 1];

  
		AuthorizationFormText aft ;
	   
		if(aftList.isEmpty())
		{
			aft = new AuthorizationFormText();
			aft.Name = authFormTextName;
			aft.AuthorizationFormId = authFormID;
			aft.IsActive = true;
			aft.Locale ='en_US';
			aft.SummaryAuthFormText ='Summary Authorization Form Text';
			
			Insert aft;
	   
		 
		}
		else {
			aft = aftList[0];
		  
		}
		return aft.Id ;
	}
	/**
 * @method fetchEnrolleeLegalCaregiverId
 * @description Retrieves the `Caregiver__c` ID associated with a specific `CareProgramEnrollee`. 
 * If no caregiver is found for the provided enrollee, the method returns `null`.
 * @param careProgramEnrolleeId The ID of the `CareProgramEnrollee` for which the caregiver is to be retrieved.
 * @return The ID of the `Caregiver__c` record if found, otherwise `null`.
 */
	private static Id fetchEnrolleeLegalCaregiverId(Id careProgramEnrolleeId) {
		// Query the Enrollee Caregiver based on the Care Program Enrollee ID
		List<Enrollee_Caregiver__c> enrolleeCaregivers = [
			SELECT Id, Caregiver__c
			FROM Enrollee_Caregiver__c
			WHERE Care_Program_Enrollee__c = :careProgramEnrolleeId
			LIMIT 1
		];
	
		// Return the first Caregiver ID if found, otherwise return null
		return !enrolleeCaregivers.isEmpty() ? enrolleeCaregivers[0].Id : null;

   
	}
	/**
 * @method getCareProgramId
 * @description Retrieves the `Care_Program__c` ID from a `Lead` record based on the provided Lead ID. 
 * If the Lead is not found in the map, the method returns `null`.
 * @param leadMap A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 * @param leadIds The ID of the Lead for which the `Care_Program__c` needs to be retrieved.
 * @return The `Care_Program__c` ID associated with the specified Lead, or `null` if the Lead is not found in the map.
 */
	
	private static Id getCareProgramId(Map<Id, Lead> leadMap, Id leadIds) {
		// Fetch the Lead from the map using the Lead ID
		if (leadMap.containsKey(leadIds)) {
			Lead lead = leadMap.get(leadIds);
			return lead.Care_Program__c; // Return Care Program ID
		}
		return null; // Return null if Lead ID is not found
	}
	/**
 * @method getAuthForm
 * @description Retrieves an `AuthorizationForm` record by its name. If the record does not exist, a new `AuthorizationForm` is created with the specified name and inserted into the database.
 * @param careProgramID The ID of the Care Program (currently unused in this implementation but might be relevant for future enhancements).
 * @param authFormName The name of the `AuthorizationForm` to be retrieved or created.
 * @return The ID of the `AuthorizationForm` record.
 */
	public static id getAuthForm (id careProgramID, string authFormName )
	{
		
		 List<AuthorizationForm> afList = [SELECT Id, Name FROM AuthorizationForm WHERE Name = :authFormName LIMIT 1];
	   
	  
		AuthorizationForm af;
		
		if (afList.isEmpty()) {
			af = new AuthorizationForm(); // Create a new instance
			af.Name = authFormName;
			Insert af;
		   
		
	  
		} else {
		  
		   af = afList[0];
		}
		
	   
		
		return af.Id ;
	}
 
 
	 
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