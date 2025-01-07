/**
 * @description Helper class for J_PatientLeadInsuranceProcessor.
 * @author [Nandha]
 * @created [18/12/24]
 */
public without sharing class J_PatientLeadInsuranceHelper {
/**
	 * @description Retrieves insurance information for a list of leads.
	 * @param leadIds A list of Lead IDs for which insurance information is fetched.
	 * @return List<Lead_Insurance_Information__c> The list of insurance information records.
	 */
	public static List<Lead_Insurance_Information__c> fetchLeadInsurance(List<Id> leadIds) {
		
		return [SELECT id,Lead__c,Is_Primary_Insurance__c,Insurance_Co__c,Insurance_Co_Phone__c,Subscriber_Policy_ID__c,Policy_Employer_Group__c,Policyholder_same_as_patient__c,Policyholder_First_Name__c,Policyholder_Last_Name__c,Policyholder_Date_of_Birth__c,
		IsPhysicianaParticipatingProvider__c,Pharmacy_Benefit_Manager__c,RxBIN__c,RxPCN__c,RxGroup__c,RxID__c
				FROM Lead_Insurance_Information__c 
				WHERE Lead__c = :leadIds WITH SECURITY_ENFORCED];
	}
	 /**
	 * @description Fetches the Record Type for the 'Journeys Payer' account.
	 * @return RecordType The Record Type for Journeys Payer.
	 */
	public static RecordType fetchPayerRecordType() {
		
        // String objectType = 'RecordType';
        // String fields = 'Id';
        // String conditions = 'SObjectType = \'Account\' AND Name = \'Journeys Payer\'';
        // List<RecordType> result = COM_QueryUtility.executeQuery(objectType, fields, conditions, false);
		// return result[0];
		return [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Journeys Payer' LIMIT 1];
	
	}
	/**
	 * @description Separates insurance records into primary and secondary lists based on type.
	 * @param lstInsurance The list of insurance records to be separated.
	 * @param primaryInsList The list where primary insurance records are stored.
	 * @param secondaryInsList The list where secondary insurance records are stored.
	 */
	public static void separateInsuranceRecords(List<Lead_Insurance_Information__c> lstInsurance,
										  List<Lead_Insurance_Information__c> primaryInsList,
										  List<Lead_Insurance_Information__c> secondaryInsList) {
		for (Lead_Insurance_Information__c ins : lstInsurance) {
			if (ins.Is_Primary_Insurance__c) {
				primaryInsList.add(ins);
			} else if (ins.Insurance_Co__c != null) {
				secondaryInsList.add(ins);
			}
		}
	}
}