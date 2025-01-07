/**
 * @description Processes lead insurance information, including primary and secondary insurance data, 
 *              creates related payer accounts, and inserts member plans for patients. 
 *              This class encapsulates the complete logic to manage insurance workflows.
 * @author [Nandha]
 * @created [17/12/24]
 */
public without sharing class J_PatientLeadInsuranceProcessor {
/**
	 * @description Processes insurance details for leads, separates primary and secondary insurance, 
	 *              handles payer accounts, and creates member plans for patients.
	 * @param mapLead A map of Lead IDs and corresponding Lead records.
	 * @param leadIds A list of Lead IDs for which the insurance details need to be processed.
	 * @param accountId The Account ID of the patient to associate with insurance details.
	 */
	public static void processLeadInsurance(Map<Id, Lead> mapLead, List<Id> leadIds, Id accountId) {
		try{
		if (mapLead.get(leadIds[0]).J_Patient_Is_Patient_Insured__c == 'Yes') {
			// Fetch Insurance Information
			List<Lead_Insurance_Information__c> lstInsurance = J_PatientLeadInsuranceHelper.fetchLeadInsurance(leadIds);
		   // Fetch Record Type for Payer
			RecordType payerRecType = J_PatientLeadInsuranceHelper.fetchPayerRecordType();	
			// Separate Primary and Secondary Insurance
			List<Lead_Insurance_Information__c> primaryInsList = new List<Lead_Insurance_Information__c>();
			List<Lead_Insurance_Information__c> secondaryInsList = new List<Lead_Insurance_Information__c>();
			J_PatientLeadInsuranceHelper.separateInsuranceRecords(lstInsurance, primaryInsList, secondaryInsList);
			// Process Primary and Secondary Insurance
			InsuranceData primaryInsurance = processPrimaryInsurance(primaryInsList, mapLead.get(leadIds[0]));
			InsuranceData secondaryInsurance = processSecondaryInsurance(secondaryInsList, mapLead.get(leadIds[0]));
	
			// Handle Payer Accounts
			List<Account> lstPayer = new List<Account>();
			Id payer1 = handlePayerAccount(primaryInsurance, payerRecType, lstPayer);
			Id payer2 = handlePayerAccount(secondaryInsurance, payerRecType, lstPayer);
		// Process Member Plans
			List<MemberPlan> planList = new List<MemberPlan>();

			if (primaryInsurance != null && payer1 != null) {
				processMemberPlan(planList, primaryInsurance, payer1, 'Primary', accountId, primaryInsList);
			}
			if (secondaryInsurance != null && payer2 != null) {
				processMemberPlan(planList, secondaryInsurance, payer2, 'Secondary', accountId, secondaryInsList);
			}
		  // Insert Member Plans
			if (!planList.isEmpty() && Schema.sObjectType.MemberPlan.fields.Name.isCreateable()) {
				insert planList;
			}
		}
	}catch(exception ex){
		GenericLogger.exceptionLog('J_PatientLeadInsuranceProcessor','processLeadInsurance',ex);
	}
	}
	 /**
	 * @description Processes primary insurance data and prepares InsuranceData.
	 * @param primaryInsList The list of primary insurance records.
	 * @param lead The Lead record to associate with the insurance data.
	 * @return InsuranceData The processed primary insurance data.
	 */
	private static InsuranceData processPrimaryInsurance(List<Lead_Insurance_Information__c> primaryInsList, Lead lead) {
		if (primaryInsList.isEmpty()) {
			return null;
		}
		return createInsuranceData(primaryInsList[0], lead);
	}
	/**
	 * @description Processes secondary insurance data and prepares InsuranceData.
	 * @param secondaryInsList The list of secondary insurance records.
	 * @param lead The Lead record to associate with the insurance data.
	 * @return InsuranceData The processed secondary insurance data.
	 */
	private static InsuranceData processSecondaryInsurance(List<Lead_Insurance_Information__c> secondaryInsList, Lead lead) {
		if (secondaryInsList.isEmpty()) {
			
			return null;
		}
		return createInsuranceData(secondaryInsList[0], lead);
	
	   
	}
	private static InsuranceData createInsuranceData(Lead_Insurance_Information__c insurance, Lead lead) {
		InsuranceData data = new InsuranceData();
		data.company = insurance.Insurance_Co__c;
		data.phone = insurance.Insurance_Co_Phone__c;
		data.policyId = insurance.Subscriber_Policy_ID__c;
		data.policyGroup = insurance.Policy_Employer_Group__c;
		data.policyHolderName = (insurance.Policyholder_same_as_patient__c == 'Yes') ? lead.Name :
								(insurance.Policyholder_First_Name__c + ' ' + insurance.Policyholder_Last_Name__c).trim();
		data.policyHolderDOB = (insurance.Policyholder_same_as_patient__c == 'Yes') ? lead.J_Date_of_Birth__c : insurance.Policyholder_Date_of_Birth__c;
		return data;
	}
	/**
	 * @description Handles the creation or retrieval of a payer account based on insurance data.
	 * @param insurance The insurance data to process.
	 * @param payerRecType The Record Type for the payer account.
	 * @param lstPayer A list to store newly created payer accounts.
	 * @return Id The ID of the payer account.
	 */
	private static Id handlePayerAccount(InsuranceData insurance, RecordType payerRecType, List<Account> lstPayer) {
		if (insurance == null || insurance.company == null) {
			return null;
		}
	
		Id payerId = checkPayerRecExist(payerRecType, insurance.company);
		if (payerId == null) {
			Account payer = assignPayer(insurance.company, null, payerRecType.Id);
			lstPayer.add(payer);
			
			if (!lstPayer.isEmpty() && Schema.sObjectType.Account.fields.Name.isCreateable()) {
				insert lstPayer;
				payerId = lstPayer[0].Id; // Get the ID of the newly created payer
			}
		  
		}
		return payerId;
	}
	/**
	 * @description Processes and prepares a Member Plan for the given insurance data.
	 * @param planList A list to store Member Plan records.
	 * @param insurance The insurance data to process.
	 * @param payerId The ID of the payer account.
	 * @param insuranceType The type of insurance ('Primary' or 'Secondary').
	 * @param patientId The Account ID of the patient.
	 * @param insuranceList The list of insurance records.
	 */
	private static void processMemberPlan(List<MemberPlan> planList, InsuranceData insurance, Id payerId, String insuranceType, Id patientId, List<Lead_Insurance_Information__c> insuranceList) {
		
		if (insurance == null || payerId == null || insuranceList.isEmpty()) {
			return;
		}	
		J_patientLeadInsuranceWrapper wrapper = new J_patientLeadInsuranceWrapper(
			patientId,
			payerId,
			insurance.phone,
			insurance.policyGroup,
			insurance.policyHolderName,
			insurance.policyHolderDOB,
			insurance.policyId,
			(insuranceType == 'Primary' ? 'Yes' : 'No'),
			insuranceType,
			insuranceList
		);
		MemberPlan plan = assignMemberPlan(wrapper);
	
		planList.add(plan);
	   
	}
	/** @description A helper class that stores insurance-related data for an individual. */
	public class InsuranceData {
		/** @description The name of the insurance company.*/
		public String company;
		/** @description The phone number associated with the insurance company or policy.*/
		public String phone;
		/** @description The unique identifier for the insurance policy.*/
		public String policyId;
		 /** @description The group number or identifier for the insurance policy.*/
		public String policyGroup;
		/** @description The name of the individual holding the insurance policy.*/
		public String policyHolderName;
		/** @description The date of birth of the policy holder.*/
		public Date policyHolderDOB;
	}
	 /**
	 * @description Checks if a payer account already exists with the specified name and Record Type.
	 * @param recTypeId The Record Type of the payer account.
	 * @param name The name of the payer.
	 * @return Id The ID of the existing payer account or null if not found.
	 */
	public static id checkPayerRecExist(RecordType recTypeId, string name)
	{   
		String recordTypeName = recTypeId.Name;
		id recordID;
		if(recordTypeName =='Journeys Payer')
		{
			Account[] acc = [select id, Name from Account where RecordTypeId =:recTypeId.id AND AccountName_Lower__C = :name.toLowerCase() Limit 1];
			recordID = acc.size() == 0 ? null : acc[0].Id ;
		}	   
		return recordID;
	}
	/**
	 * @description Creates and returns a new Account record for the payer.
	 * @param name The name of the payer account.
	 * @param status The status of the payer account.
	 * @param recTypeId The Record Type ID for the payer account.
	 * @return Account The newly created payer account record.
	 */
	public static Account assignPayer(string name,string status,string recTypeId)
	{
		Account acc = new Account();
		acc.RecordTypeId=recTypeId;
		acc.Name = name;
		acc.J_PayerStatus__c = 'Active';    
	
		return acc;
	}
	 /**
	 * @description Creates and returns a new MemberPlan record for the insurance wrapper.
	 * @param wrapper The J_patientLeadInsuranceWrapper containing insurance details.
	 * @return MemberPlan The newly created MemberPlan record.
	 */
	public static MemberPlan assignMemberPlan(J_patientLeadInsuranceWrapper wrapper) {
	MemberPlan memberPlan = new MemberPlan();
	memberPlan.MemberId = wrapper.patientId;
	memberPlan.Status = 'Pending';
	memberPlan.J_Role__c = wrapper.insuranceType;
	memberPlan.Name = 'N/A';
	memberPlan.PayerId = wrapper.payerId;
	memberPlan.J_MemberServicesPhoneNumber__c = wrapper.insurancePhone;
	memberPlan.J_PolicyNumber__c = wrapper.policyNo;
	if (wrapper.policyHolderName != null) {
	memberPlan.J_PolicyHolderName__c = wrapper.policyHolderName;
	}
	memberPlan.J_Policy_Holder_DOB__c = wrapper.policyHolderDOB;
	memberPlan.J_Subscriber_Policy_ID__c = wrapper.subscriberPolicyID;
	if (wrapper.relationToPolicyHolder == 'Yes') {
	memberPlan.J_Relation_to_Policy_Holder__c = 'Self';
	}	
	// Populate additional details from the insurance list (if available)
	if (!wrapper.insuranceList.isEmpty()) {
	Lead_Insurance_Information__c insuranceDetails = wrapper.insuranceList[0];
	memberPlan.J_IsPhysicianaParticipatingProvider__c = insuranceDetails.IsPhysicianaParticipatingProvider__c;
	memberPlan.J_PBM_Name__c = insuranceDetails.Pharmacy_Benefit_Manager__c;
	memberPlan.PBM_Bin__c = insuranceDetails.RxBIN__c;
	memberPlan.PBM_PCN__c = insuranceDetails.RxPCN__c;
	memberPlan.PBM_Group__c = insuranceDetails.RxGroup__c;
	memberPlan.PBM_ID__c = insuranceDetails.RxID__c;
	}   
	return memberPlan;
	}
	

}