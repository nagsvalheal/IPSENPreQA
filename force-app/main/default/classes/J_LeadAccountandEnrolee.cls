public without sharing class J_LeadAccountandEnrolee {


    /**
 * @method fetchLeadRecords
 * @description Fetches Lead records from the database based on the provided list of Lead IDs. The method constructs a dynamic SOQL query to retrieve 
 * the specified fields and converts the result into a Map of Lead records, keyed by their IDs.
 * @param lstLeadID A list of Lead record IDs to fetch from the database.
 * @return A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 * @throws Exception If the query execution fails or if there are issues with the provided Lead IDs.
 */
public static Map<Id, Lead> fetchLeadRecords(List<Id> lstLeadID) {
   
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
 * @method fetchAccountsForConvertedLeads
 * @description Retrieves Account records corresponding to the converted Lead-to-Account mappings. 
 * This method constructs a dynamic SOQL query to fetch specified Account fields and returns the result as a Map.
 * @param leadToAccountMap A map where the key is the Lead ID and the value is the Account ID created during the Lead conversion.
 * @return A map of Account records, where the key is the Account ID and the value is the corresponding Account record.
 * @throws Exception If the query execution fails or the provided Account IDs are invalid.
 */
public static Map<Id, Account> fetchAccountsForConvertedLeads(Map<Id, Id> leadToAccountMap) {
   
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
 * @method convertLeads
 * @description Converts a list of Lead records into corresponding Accounts by leveraging Salesforce's Lead Conversion API.
 * This method ensures that each Lead in the provided list is converted successfully and returns a mapping of Lead IDs to their corresponding Account IDs.
 * @param lstLeadID A list of Lead record IDs to be converted.
 * @return A map of Lead IDs to Account IDs, where each Lead ID is mapped to the Account ID created during the conversion.
 * @throws Database.LeadConvertException If the Lead conversion process encounters errors for any record.
 */
public static Map<Id, Id> convertLeads(List<Id> lstLeadID) {
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


}