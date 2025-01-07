/**
 * @name J_patientLeadInsuranceWrapper
 * @description A wrapper class to encapsulate insurance-related details for a patient, 
 *              including policy information, payer details, and insurance list records. 
 *              This wrapper simplifies the process of handling and transferring insurance data.
 * @author [Nandha]
 * @created [17/12/24]
 */
public class J_patientLeadInsuranceWrapper {
	public Id patientId;
	public Id payerId;
	public String insurancePhone;
	public String policyNo;
	public String policyHolderName;
	public Date policyHolderDOB;
	public String subscriberPolicyID;
	public String relationToPolicyHolder;
	public String insuranceType;
	public List<Lead_Insurance_Information__c> insuranceList;

	 /**
	 * @name J_patientLeadInsuranceWrapper
	 * @description Initializes the wrapper with patient details, payer details, insurance phone, policy information,
	 *              policyholder details, insurance type, and related insurance records.
	 * @param patientId The ID of the patient associated with the insurance.
	 * @param payerId The ID of the payer account.
	 * @param insurancePhone The phone number of the insurance company.
	 * @param policyNo The policy number associated with the insurance.
	 * @param policyHolderName The name of the policyholder.
	 * @param policyHolderDOB The date of birth of the policyholder.
	 * @param subscriberPolicyID The subscriber policy ID.
	 * @param relationToPolicyHolder The relationship of the policyholder to the patient.
	 * @param insuranceType The type of insurance ('Primary' or 'Secondary').
	 * @param insuranceList The list of Lead Insurance Information records associated with the insurance.
	 
	 */
	public J_patientLeadInsuranceWrapper(Id patientId, Id payerId, String insurancePhone, String policyNo,
		String policyHolderName, Date policyHolderDOB, String subscriberPolicyID,
		String relationToPolicyHolder, String insuranceType,
		List<Lead_Insurance_Information__c> insuranceList) {
		this.patientId = patientId;
		this.payerId = payerId;
		this.insurancePhone = insurancePhone;
		this.policyNo = policyNo;
		this.policyHolderName = policyHolderName;
		this.policyHolderDOB = policyHolderDOB;
		this.subscriberPolicyID = subscriberPolicyID;
		this.relationToPolicyHolder = relationToPolicyHolder;
		this.insuranceType = insuranceType;
		this.insuranceList = insuranceList;
	}

}