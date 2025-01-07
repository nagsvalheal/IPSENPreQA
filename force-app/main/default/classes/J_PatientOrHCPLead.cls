public without sharing class J_PatientOrHCPLead {

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
	Id enrolleeLegalCaregiverId = ConvertLeadToPatient.fetchEnrolleeLegalCaregiverId(careProgramEnrolleeIds[0]); // Assumes one enrollee ID for simplicity
   

	// Step 2: Process Lead Consent based on the created caregivers
  
	Id authFormTextId = ConvertLeadToPatient.getAuthFormText(careProgramId, 'Journeys Authorization Form', 'Journeys Authorization Form Text');
	J_PatientLeadAuthformProcessor.processLeadConsent(leadIds, mapLead, authFormTextId, careProgramEnrolleeIds[0], enrolleeLegalCaregiverId);
   // Process Lead Insurance Informatio
	
	for (Id leadId : leadIds) {
		if (mapLead.containsKey(leadId)) {
			Id accountId = leadToAccountMap.get(leadId);// Assuming ConvertedAccountId is available in Lead object
			J_PatientLeadInsuranceProcessor.processLeadInsurance(mapLead, leadIds, accountId);
		}
	}

}

}