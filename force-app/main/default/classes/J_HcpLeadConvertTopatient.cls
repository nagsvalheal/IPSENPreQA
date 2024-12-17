public without sharing class J_HcpLeadConvertTopatient {
	/**
 * @method processHealthcareProviders
 * @description Processes healthcare providers associated with a Lead, including physician data extraction, HCP enrollment, and consent handling.
 * @param leadIds The ID of the Lead whose healthcare providers are being processed.
 * @param careProgramEnrolleeId The ID of the Care Program Enrollee associated with the healthcare providers.
 * @param mapLead A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 */
 public static void processHealthcareProviders(Id leadIds, Id careProgramEnrolleeId, Map<Id, Lead> mapLead) {
		// Fetch physicians associated with the lead
		List<Lead_Associated_Physician__c> lstPhysician = fetchPhysicians(leadIds);
	
		if (!lstPhysician.isEmpty()) {
			// Fetch required record types outside the loop
			Map<String, RecordType> recordTypes = fetchRecordTypes();
	
			// Prepare collections for bulk operations
			List<Contact> contactsToInsert = new List<Contact>();
			Map<Id, Id> physicianToCareProgramEnrolleeMap = new Map<Id, Id>();
			List<Id> insertedPhysicianIds = new List<Id>();
	
			// Process each physician
			processPhysicianData(lstPhysician, recordTypes, careProgramEnrolleeId, contactsToInsert, physicianToCareProgramEnrolleeMap);
	
			// Perform bulk DML operations
			handleContactInsertions(contactsToInsert, careProgramEnrolleeId, insertedPhysicianIds, physicianToCareProgramEnrolleeMap);
	
			// Handle enrollee HCP and caregiver consent
			handleEnrolleeHCPAndConsent(leadIds, careProgramEnrolleeId, mapLead, recordTypes, physicianToCareProgramEnrolleeMap, insertedPhysicianIds);
		}
	}

	/**
 * @method fetchPhysicians
 * @description Retrieves the list of `Lead_Associated_Physician__c` records associated with the given Lead ID.
 * @param leadIds The ID of the Lead for which the associated physicians are being retrieved.
 * @return A list of `Lead_Associated_Physician__c` records linked to the Lead.
 */
	
	private static List<Lead_Associated_Physician__c> fetchPhysicians(Id leadIds) {
		
		String sObjectType = 'Lead_Associated_Physician__c';
		String fields = 'Id, Lead__c, Name, Last_Name__c, Preferred_Method_of_Contact__c, Email__c, Phone__c, Fax__c, ' +
						'Tax_ID__c, DEA__c, State_License__c, Medicaid_Provider__c, Medicare_PTAN__c, NPI__c, Best_Time_to_Contact__c, ' +
						'Office_Institution__c, Role__c, Specialty__c, Office_Contact_Title__c, Primary_ICD_10_Code__c, Secondary_ICD_10_Code__c, ' +
						'Physician_Address__CountryCode__s, Physician_Address__Street__s, Physician_Address__City__s, ' +
						'Physician_Address__StateCode__s, Physician_Address__PostalCode__s';
		
		// Construct the condition for the query, escaping single quotes
		String conditions = 'Lead__c = \'' + escapeSingleQuotes(String.valueOf(leadIds)) + '\'';
		
		// Execute the query using the helper method
		List<SObject> results = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
		
		// Return the results as a list of Lead_Associated_Physician__c objects
		return (List<Lead_Associated_Physician__c>)results;
	
	}

	/**
 * @method fetchRecordTypes
 * @description Fetches and returns specific Record Types required for processing physicians, HCOs, and caregivers.
 * @return A map of Record Type names to their corresponding `RecordType` objects.
 */
	
	private static Map<String, RecordType> fetchRecordTypes() {
		Map<String, RecordType> recordTypes = new Map<String, RecordType>();
		recordTypes.put('Physician', [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Contact' AND Name = 'Journey Contact' LIMIT 1]);
		recordTypes.put('HCO', [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Journeys HCO' LIMIT 1]);
		recordTypes.put('Caregiver', [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = true AND Name = 'Journeys Caregiver' LIMIT 1]);
		return recordTypes;
	}
	/**
 * @method processPhysicianData
 * @description Processes a list of physician data, ensuring duplicate detection and mapping physicians to Care Program Enrollees.
 * @param lstPhysician The list of `Lead_Associated_Physician__c` records to process.
 * @param recordTypes A map of Record Types used for creating physicians and HCOs.
 * @param careProgramEnrolleeId The ID of the Care Program Enrollee linked to the physicians.
 * @param contactsToInsert A list to collect `Contact` objects for bulk insertion.
 * @param physicianToCareProgramEnrolleeMap A map linking physician IDs to Care Program Enrollee IDs.
 */

	private static void processPhysicianData(
		List<Lead_Associated_Physician__c> lstPhysician,
		Map<String, RecordType> recordTypes,
		Id careProgramEnrolleeId,
		List<Contact> contactsToInsert,
		Map<Id, Id> physicianToCareProgramEnrolleeMap
	) {
		Set<String> existingPhysicians = new Set<String>();
		for (Lead_Associated_Physician__c physicianData : lstPhysician) {
			String physicianKey = generatePhysicianKey(physicianData.Name, physicianData.Last_Name__c, physicianData.Phone__c, physicianData.Email__c);
			if (!existingPhysicians.contains(physicianKey)) {
				existingPhysicians.add(physicianKey);
				Id physicianId = checkPhysicianExist(
					recordTypes.get('Physician'),
					physicianData.Name,
					physicianData.Last_Name__c,
					physicianData.Phone__c,
					physicianData.Email__c,
					physicianData.Physician_Address__PostalCode__s
				);
				if (physicianId == null) {
					contactsToInsert.add(createPhysicianContact(physicianData, recordTypes.get('Physician'), recordTypes.get('HCO')));
				} else {
					physicianToCareProgramEnrolleeMap.put(physicianId, careProgramEnrolleeId);
				}
			}
		}
	}
	/**
 * @method handleContactInsertions
 * @description Handles the bulk insertion of `Contact` records and maps successfully inserted physician IDs to Care Program Enrollees.
 * @param contactsToInsert A list of `Contact` objects to insert.
 * @param careProgramEnrolleeId The ID of the Care Program Enrollee associated with the contacts.
 * @param insertedPhysicianIds A list to collect the IDs of successfully inserted physicians.
 * @param physicianToCareProgramEnrolleeMap A map linking physician IDs to Care Program Enrollee IDs.
 */

	
	private static void handleContactInsertions(
		List<Contact> contactsToInsert,
		Id careProgramEnrolleeId,
		List<Id> insertedPhysicianIds,
		Map<Id, Id> physicianToCareProgramEnrolleeMap
	) {
		if (!contactsToInsert.isEmpty()) {
			List<SObject> recordsToInsert = new List<SObject>();
			recordsToInsert.addAll(contactsToInsert);
			
			Database.SaveResult[] insertResults = COM_DatabaseOperationsUtility.insertOperation(recordsToInsert, 'handleContactInsertions', true);
			
			for (Integer i = 0; i < insertResults.size(); i++) {
				if (insertResults[i].isSuccess()) {
					// Add successful record IDs to the collections
					Contact contact = (Contact)contactsToInsert[i];
					insertedPhysicianIds.add(contact.Id);
					physicianToCareProgramEnrolleeMap.put(contact.Id, careProgramEnrolleeId);
				} 
		}
	}
	}

	/**
 * @method handleEnrolleeHCPAndConsent
 * @description Handles the creation of Enrollee-HCP relationships and processes caregiver consent for a given Lead.
 * @param leadIds The ID of the Lead being processed.
 * @param careProgramEnrolleeId The ID of the Care Program Enrollee associated with the Lead.
 * @param mapLead A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 * @param recordTypes A map of Record Types for caregivers and physicians.
 * @param physicianToCareProgramEnrolleeMap A map linking physician IDs to Care Program Enrollee IDs.
 * @param insertedPhysicianIds A list of IDs of physicians inserted during the process.
 */

	
	private static void handleEnrolleeHCPAndConsent(
		Id leadIds,
		Id careProgramEnrolleeId,
		Map<Id, Lead> mapLead,
		Map<String, RecordType> recordTypes,
		Map<Id, Id> physicianToCareProgramEnrolleeMap,
		List<Id> insertedPhysicianIds
	) {
		List<Enrollee_HCP__c> enrolleeHCPsToInsert = new List<Enrollee_HCP__c>();
		for (Id physicianId : physicianToCareProgramEnrolleeMap.keySet()) {
			enrolleeHCPsToInsert.add(createEnrolleeHCP(physicianToCareProgramEnrolleeMap.get(physicianId), physicianId));
		}
	
		if (!enrolleeHCPsToInsert.isEmpty()) {
		  
		   List<SObject> recordsToInsert = new List<SObject>();
		   recordsToInsert.addAll(enrolleeHCPsToInsert);
		   Database.SaveResult[] insertResults = COM_DatabaseOperationsUtility.insertOperation(recordsToInsert, 'handleEnrolleeHCPAndConsent', true);
	
			if (!insertedPhysicianIds.isEmpty()) {
				Id careProgramId = [SELECT Care_Program__c FROM Lead WHERE Id = :leadIds LIMIT 1].Care_Program__c;
				Id authFormTextId = ConvertLeadToPatient.GetAuthFormText(careProgramId, 'Journeys Authorization Form', 'Journeys Authorization Form Text');
				J_HCPCaregiverConsentToPatient processor = new J_HCPCaregiverConsentToPatient();
				J_HCPCaregiverConsentWrapper wrapper = new J_HCPCaregiverConsentWrapper(
					leadIds,
					mapLead,
					careProgramEnrolleeId,
					recordTypes.get('Caregiver').Id,
					authFormTextId,
					insertedPhysicianIds[0],
					new List<Enrollee_Caregiver__c>(),
					new List<Id>{leadIds}
				);
				processor.processHCPCaregiverConsent(wrapper);
			}
		}
	}
	
	/**
 * @method createPhysicianContact
 * @description Creates a `Contact` record for a physician based on the provided `Lead_Associated_Physician__c` data.
 * @param physicianData The `Lead_Associated_Physician__c` record containing physician data.
 * @param physicianRecType The `RecordType` for creating physician contacts.
 * @param journeyHCORecType The `RecordType` for associating the physician with an HCO.
 * @return A `Contact` object populated with physician details.
 */

	private static Contact createPhysicianContact(Lead_Associated_Physician__c physicianData, RecordType physicianRecType, RecordType journeyHCORecType) {
		return new Contact(
			RecordTypeId = physicianRecType.Id,
			FirstName = physicianData.Name,
			LastName = physicianData.Last_Name__c,
			MailingStreet = physicianData.Physician_Address__Street__s,
			MailingCity = physicianData.Physician_Address__City__s,
			MailingStateCode = physicianData.Physician_Address__StateCode__s,
			MailingPostalCode = physicianData.Physician_Address__PostalCode__s,
			MailingCountryCode = physicianData.Physician_Address__CountryCode__s,
			J_Preferred_Contact_Method__c = physicianData.Preferred_Method_of_Contact__c == 'Phone' ? 'Mobile Phone' : physicianData.Preferred_Method_of_Contact__c,
			Phone = physicianData.Phone__c,
			MobilePhone = physicianData.Phone__c,
			Fax = physicianData.Fax__c,
			Email = physicianData.Email__c,
			J_TaxID__c = physicianData.Tax_ID__c != null ? physicianData.Tax_ID__c.substring(0, 3) + '-' + physicianData.Tax_ID__c.substring(3, 5) + '-' + physicianData.Tax_ID__c.substring(5, 9) : null,
			J_DEA_Number__c = physicianData.DEA__c,
			J_State_License_Number__c = physicianData.State_License__c,
			J_NPI__c = physicianData.NPI__c,
			J_Medicaid_Provide_Number__c = physicianData.Medicaid_Provider__c,
			J_Medicare_PTAN__c = physicianData.Medicare_PTAN__c,
			J_Best_Time_to_Contact__c = physicianData.Best_Time_to_Contact__c,
			Role__c = physicianData.Role__c,
			J_PhysicianSpecialty__c = physicianData.Specialty__c,
			Office_Contact_Title__c = physicianData.Office_Contact_Title__c,
			Office_Institution__c = physicianData.Office_Institution__c,
			J_Primary_ICD_10_Code__c = physicianData.Primary_ICD_10_Code__c,
			J_Secondary_ICD_10_Code__c = physicianData.Secondary_ICD_10_Code__c,
			AccountId = checkHCOAccExist(journeyHCORecType, 'Lead HCO')
		);
	}
	/**
 * @method createEnrolleeHCP
 * @description Creates an `Enrollee_HCP__c` record linking a Care Program Enrollee to a physician.
 * @param careProgramEnrolleeId The ID of the Care Program Enrollee.
 * @param physicianId The ID of the physician to associate with the enrollee.
 * @return An `Enrollee_HCP__c` object linking the enrollee and physician.
 */

	private static Enrollee_HCP__c createEnrolleeHCP(Id careProgramEnrolleeId, Id physicianId) {
		return new Enrollee_HCP__c(
			Care_Program_Enrollee__c = careProgramEnrolleeId,
			HCP__c = physicianId,
			Status__c = 'Active',
			Name = 'Enrollee HCP'
		);
	}
	/**
 * @method generatePhysicianKey
 * @description Generates a unique key for identifying a physician based on their first name, last name, phone number, and email.
 * @param firstName The first name of the physician.
 * @param lastName The last name of the physician.
 * @param phone The phone number of the physician.
 * @param email The email address of the physician.
 * @return A unique key string for the physician.
 */

	private static String generatePhysicianKey(String firstName, String lastName, String phone, String email) {
		return firstName + ':' + lastName + ':' + phone + ':' + email;
	}
	/**
 * @method checkPhysicianExist
 * @description Checks if a physician already exists in the system based on their details.
 * @param recTypeId The `RecordType` of the physician contact.
 * @param name The first name of the physician.
 * @param lastName The last name of the physician.
 * @param phone The phone number of the physician.
 * @param email The email address of the physician.
 * @param postalCode The postal code of the physician.
 * @return The ID of the existing physician `Contact` record, or `null` if not found.
 */

	public static Id checkPhysicianExist(RecordType recTypeId, String  name, String lastName, String phone, String email, String postalCode) {
		String recordTypeName = recTypeId.Name;
		Id recordID;
	
		if (recordTypeName == 'Journey Contact') {
			Contact[] con = [SELECT Id, Name FROM Contact 
							 WHERE RecordTypeId = :recTypeId.Id 
							 AND FirstName = :name 
							 AND LastName = :lastName
							 AND (Phone = :phone OR Email = :email OR MailingPostalCode = :postalCode OR OtherPostalCode = :postalCode)
							 LIMIT 1];
			RecordID = con.isEmpty() ? null : con[0].Id;

			
		}
	
	   
		return RecordID;
	}
	/**
 * @method checkEnrolleeHCPExist
 * @description Checks if an Enrollee-HCP relationship already exists and updates its status to 'Inactive' if currently 'Active'.
 * @param cpeId The ID of the Care Program Enrollee.
 * @param hcpId The ID of the HCP (physician).
 * @return The ID of the existing `Enrollee_HCP__c` record, or `null` if not found.
 */


	public static Id checkEnrolleeHCPExist(Id cpeId, Id hcpId) {
		Id recordId;
			//List<Enrollee_HCP__c> enrolleeHCPRecords = [SELECT Id, Status__c FROM Enrollee_HCP__c WHERE Care_Program_Enrollee__c = :cpeId AND HCP__c = :hcpId LIMIT 1];
			String sObjectType = 'Enrollee_HCP__c';
			String fields = 'Id, Status__c';
		
			// Construct the condition dynamically, escaping single quotes
			String conditions = 'Care_Program_Enrollee__c = \'' + escapeSingleQuotes(String.valueOf(cpeId)) + '\'' +
								' AND HCP__c = \'' + escapeSingleQuotes(String.valueOf(hcpId)) + '\'';
		
			// Execute the query using the helper method
			List<SObject> results = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
		
			if (!results.isEmpty()) {
		   // Enrollee_HCP__c existingEnrolleeHCP = enrolleeHCPRecords[0];
		   Enrollee_HCP__c existingEnrolleeHCP = (Enrollee_HCP__c)results[0];
			
			// If the existing Enrollee HCP record is active, update its status to inactive
			if (existingEnrolleeHCP.Status__c == 'Active') {
				existingEnrolleeHCP.Status__c = 'Inactive';
				List<SObject> recordsToUpdate = new List<SObject>{existingEnrolleeHCP};
				Database.SaveResult[] updateResults = COM_DatabaseOperationsUtility.updateOperation(recordsToUpdate, 'checkEnrolleeHCPExist', true);
			   // update existingEnrolleeHCP;
			}
			
			recordId = existingEnrolleeHCP.Id;
		} else {
			recordId = null;
		}
		
	   
		return recordId;
		}

		/**
 * @method checkHCOAccExist
 * @description Checks if an HCO (Health Care Organization) Account exists. If not, creates a new one with the specified record type and name.
 * @param recordType The `RecordType` for the HCO Account.
 * @param accountName The name of the HCO Account to check or create.
 * @return The ID of the existing or newly created HCO Account.
 */

		public static Id checkHCOAccExist(RecordType recordType, String accountName) {
			Id accountId;
		
		   
			String sObjectType = 'Account';
			String fields = 'Id';
		
			// Construct the condition dynamically, escaping single quotes
			String conditions = 'RecordTypeId = \'' + escapeSingleQuotes(String.valueOf(recordType.Id)) + '\'' +
								' AND Name = \'' + escapeSingleQuotes(accountName) + '\'';
		
			// Execute the query using the helper method
			List<SObject> results = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
		
			if (!results.isEmpty()) {
				//accountId = existingAccounts[0].Id;
				accountId = ((Account)results[0]).Id;
			} else {
				// If no account exists, optionally create one (if required)
				Account newAccount = new Account(
					RecordTypeId = recordType.Id,
					Name = accountName
				);
		
				if (Schema.sObjectType.Account.isCreateable()) {
					insert newAccount;
					accountId = newAccount.Id;
				}
			}
		
		   
			return accountId;
		}
		private static String escapeSingleQuotes(String str) {
			return str.replaceAll('\'', '\\\'');
		}
		
}