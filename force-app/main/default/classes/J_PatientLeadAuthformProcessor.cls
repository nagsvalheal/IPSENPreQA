/**
 * @name J_PatientLeadAuthformProcessor
 * @description Processes lead consent information, creates associated Authorization Form Consent 
 *              and Consent Document records, and links consent documents to leads.
 * @author [Nandha]
 * @created [17/12/24]
 */
public without sharing class J_PatientLeadAuthformProcessor {

	/**
 * @method processLeadConsent
 * @description Processes consent information for the given Leads and creates associated
 *              Authorization Form Consent and Consent Document records.
 * @param leadIds A list of Lead IDs for which the consent needs to be processed.
 * @param mapLead A map of Lead records, where the key is the Lead ID and the value is the corresponding Lead record.
 * @param authFormTextId The ID of the Authorization Form Text used for the consent process.
 * @param careProgramEnrolleeID The ID of the Care Program Enrollee associated with the consent.
 * @param enrolleeLegalCaregiverID The ID of the legal caregiver for the enrollee.
 */

	public static void processLeadConsent(List<Id> leadIds, Map<Id, Lead> mapLead, Id authFormTextId, Id careProgramEnrolleeID, Id enrolleeLegalCaregiverID) {
		// Fetch consent information
		
try{
		String fields = 'Id, Lead__c, Signature_of_Patient_or_Parent_LG__c, Signatured_Date__c, Type__c';
		List<String> leadIdsAsStrings = new List<String>();
for (Id leadId : leadIds) {
	leadIdsAsStrings.add('\'' + String.escapeSingleQuotes(leadId) + '\'');
}
String conditions = 'Lead__c IN (' + String.join(leadIdsAsStrings, ',') + ')';
		List<SObject> consentInfoList = COM_QueryUtility.executeQuery('Lead_Consent_For_Information__c', fields, conditions, false);
	
		List<Lead_Consent_For_Information__c> lstConsentInfo = new List<Lead_Consent_For_Information__c>();
		for (SObject obj : consentInfoList) {
			lstConsentInfo.add((Lead_Consent_For_Information__c)obj);
		}
	   
	 
		Boolean signParentLGPHI = false; 
		Boolean signParentLGGI = false;
		Date signDateParentLGPHI;
		Date signDateParentLGGI;
	 
		// Process consent information
		if (!lstConsentInfo.isEmpty()) {
			for (Lead_Consent_For_Information__c consentInfo : lstConsentInfo) {
				if (consentInfo.Type__c == 'Use of Person Health Information') {
					signParentLGPHI = consentInfo.Signature_of_Patient_or_Parent_LG__c;
					signDateParentLGPHI = consentInfo.Signatured_Date__c;
				} else if (consentInfo.Type__c == 'Use of Genetic Information') {
					signParentLGGI = consentInfo.Signature_of_Patient_or_Parent_LG__c;
					signDateParentLGGI = consentInfo.Signatured_Date__c;
				}
			}
		   
		}
	 
	  
	 
		// Create AuthorizationFormConsent record
		AuthorizationFormConsent afc = new AuthorizationFormConsent();
		afc.Name = 'Patient Authorization';
		afc.AuthorizationFormTextId = authFormTextId;
		afc.ConsentGiverId = careProgramEnrolleeID;
		afc.Date_of_Consent_Received__c = mapLead.get(leadIds[0]).J_Consent_Effective_Date__c;
		afc.ConsentCapturedDateTime = convertDatetime(mapLead.get(leadIds[0]).J_Consent_Effective_Date__c);
		afc.J_ConsentReceivedThrough__c = consentSource(mapLead.get(leadIds[0]).LeadSource);
		afc.Consented_Caregiver__c = enrolleeLegalCaregiverId;
	 
		afc.Consented_by_Others__c = mapLead.get(leadIds[0]).Consented_by_Others__c;
		afc.J_TypeOfConsent__c = 'Patient Authorization';
		afc.J_ConsentStatus__c = 'In Progress';
		afc.J_Phone__c = convertData(mapLead.get(leadIds[0]).J_Consent_voice_call__c);
		afc.J_SMS__c =convertData( mapLead.get(leadIds[0]).J_Consent_text_message__c);
		afc.J_Mail__c = convertData(mapLead.get(leadIds[0]).J_Consent_mail__c);
		afc.J_Email__c = convertData(mapLead.get(leadIds[0]).J_Consent_email__c);
		afc.J_MarketingMeterial__c = convertData(mapLead.get(leadIds[0]).J_Consent_marketing_info__c);
		afc.J_Meetings__c = 'Opt-in';
	 
		afc.Signature_of_Patient_or_Parent_LG_PHI__c = signParentLGPHI;
		afc.Signature_of_Patient_or_Parent_LG_GI__c = signParentLGGI;
		afc.Signatured_Date_PHI__c = signDateParentLGPHI;
		afc.Signatured_Date_GI__c = signDateParentLGGI;
	 
		//insert afc;
		Database.SaveResult[] afcInsertResults = COM_DatabaseOperationsUtility.insertOperation(
	new List<SObject>{afc}, 
	'AuthorizationFormConsent Insert', 
	true
);
	   
	 
	  
		if (!afcInsertResults.isEmpty() && afcInsertResults[0].isSuccess()) {
			afc.Id = afcInsertResults[0].getId();
		
			// Create Consent Document record
			Consent_Doc__c consentDoc = new Consent_Doc__c();
			consentDoc.Authorization_Form_Consent__c = afc.Id;
			consentDoc.Name = 'Patient Authorization Document';
		
			// Perform the insert operation for Consent Document
			Database.SaveResult[] consentDocInsertResults = COM_DatabaseOperationsUtility.insertOperation(
				new List<SObject>{consentDoc}, 
				'Consent Document Insert', 
				true
			);
		  
			
			if (!consentDocInsertResults.isEmpty() && consentDocInsertResults[0].isSuccess()) {
				
				consentDoc.Id = consentDocInsertResults[0].getId();
				J_LeadConsentDocumentToAttachment.linkConsentDocumentToAttachment(consentDoc.Id, leadIds, mapLead);
			}
		}
	}catch(exception ex){
		
		
		GenericLogger.exceptionLog('J_PatientLeadAuthformProcessor','processLeadConsent',ex);
	  
		
	}
	 }
 
 
/**
	 * @name convertData
	 * @description Converts specific strings into their corresponding standardized values for consent fields.
	 * @param data The input string to be converted.
	 * @return A standardized string value based on the input. Returns `null` if input is null.
	 * @example
	 *      String result = convertData('Yes - I Agree'); // Returns 'Opt-in'
	 *      String result = convertData('SMS');           // Returns 'Text'
	 *      String result = convertData(null);           // Returns null
	 */
public static String convertData(String data) {
	if (data == null) {
		return null;
	}

	Map<String, String> conversionMap = new Map<String, String>{
		'Yes - I Agree' => 'Opt-in',
		'No - I Do Not Agree' => 'Opt-out',
		'SMS' => 'Text',
		'Cell' => 'Mobile',
		'Work' => 'Other',
		'Units' => 'Units (U)',
		'Caps' => 'Caps'
	};

	if (conversionMap.containsKey(data)) {
		return conversionMap.get(data);
	} else if (data.contains('Milligram')) {
		return 'Milligram (mg)';
	} else if (data.contains('Microgram')) {
		return 'Micrograms (mcg)';
	} else if (data.contains('Milliliter')) {
		return 'Milliliter (ml)';
	}

	return data;
}




 
   /**
	 * @name convertDatetime
	 * @description Converts a given Date into a Datetime object with the time set to midnight.
	 * @param dt The Date to be converted.
	 * @return A Datetime object with the same date and a time of midnight.
	 * @example
	 *      Date dt = Date.today();
	 *      Datetime result = convertDatetime(dt); 
	
	 */
	public static datetime convertDatetime(date dt)
	{
		
		Datetime newdt = DateTime.newInstance(dt.year(), dt.month(),dt.day());
	   
		return newdt;
	}
 
	  /**
	 * @name consentSource
	 * @description Maps a given source string to a standardized consent source value.
	 * @param data The input source string.
	 * @return A standardized string value representing the consent source.
	 *         Returns 'Other' for unrecognized sources.
	 * @example
	 *      String result1 = consentSource('Web');       // Returns 'Website'
	 *      String result2 = consentSource('Phone Inquiry'); // Returns 'Phone Inquiry'
	 *      String result3 = consentSource('Unknown');   // Returns 'Other'
	 */
public static String consentSource(String data) {
	Set<String> validSources = new Set<String>{
		'Email', 'Fax', 'Paper', 'Other', 'Purchased List', 'Partner Referral', 'Phone Inquiry'
	};

	if (data == 'Web' || data == 'Website') {
		return 'Website';
	} else if (validSources.contains(data)) {
		return data;
	}
	return 'Other';
}


   

}