/**
 * @description    Processes the prior authorization for a given lead. It checks if a prior authorization is provided and 
 *                 if the necessary records (MemberPlan, CoverageBenefit, and CarePreauth) are present or need to be created. 
 *                 The method inserts a new CarePreauth record if a valid prior authorization is provided.
 * @category       Lead, Prior Authorization
 * @author         [Nandha]
 * @date           [17/12/2024]
 * 
 * @param lead              The Lead record for which the prior authorization is being processed.
 * @param careProgramEnrolleeId  The ID of the Care Program Enrollee associated with the prior authorization.
 * @param accountId         The ID of the account associated with the lead, used to fetch the MemberPlan.

 */
public with sharing class J_HCPLeadPriorAuthHelper {
 /**
 * @description    Processes the prior authorization for a given lead. It checks if a prior authorization is provided and 
 *                 if the necessary records (MemberPlan, CoverageBenefit, and CarePreauth) are present or need to be created. 
 *                 The method inserts a new CarePreauth record if a valid prior authorization is provided.
 * @param lead              The Lead record for which the prior authorization is being processed.
 * @param careProgramEnrolleeId  The ID of the Care Program Enrollee associated with the prior authorization.
 * @param accountId         The ID of the account associated with the lead, used to fetch the MemberPlan.

 */   
	public static void processPriorAuthorization(Lead lead, Id careProgramEnrolleeId, Id accountId) {
		try{
		String priorAuth = lead.Prior_Authorization_if_known__c;
		
		// If Prior Authorization is not provided, exit the method
		if (String.isEmpty(priorAuth)) {
			return;
		}
		
		// Fetch the MemberPlan related to the account
		String sObjectType = 'MemberPlan';
		String fields = 'Id';
		String conditions = 'MemberId = :accountId AND Status != \'Inactive\' AND J_Role__c = \'Primary\'';
		Boolean withUserMode = true;

		// Get the result directly as List<MemberPlan> without using a loop
		List<MemberPlan> lstMemberPlan = (List<MemberPlan>) COM_QueryUtility.executeQuery(sObjectType, fields, conditions, withUserMode);

		
		// If no MemberPlan is found, exit the method
		if (lstMemberPlan.isEmpty()) {
			return;
		}
		
		Id coverageBenefitId;
		Id memberPlanId;
		
	  // Fetch the CoverageBenefit related to the Care Program Enrollee
		String benefitsObjectType = 'CoverageBenefit';
		String benefitfields = 'Id, MemberPlanId';
		String benefitconditions = 'Care_Program_Enrollee__c = :careProgramEnrolleeId AND J_CoverageBenefitStatus__c IN (\'Active\', \'Pending\')';
		Boolean benefitwithUserMode = true;

		// Call the executeQuery method with the correct parameters
		List<SObject> result = COM_QueryUtility.executeQuery(benefitsObjectType, benefitfields, benefitconditions, benefitwithUserMode);

		// Cast the result to List<CoverageBenefit>
		List<CoverageBenefit> lstCoverageBenefit = (List<CoverageBenefit>) result;

		
		
		// If CoverageBenefit is found, use its details; otherwise, create a new CoverageBenefit
		if (!lstCoverageBenefit.isEmpty()) {
			coverageBenefitId = lstCoverageBenefit[0].Id;
			memberPlanId = lstCoverageBenefit[0].MemberPlanId;
		} else {
			CoverageBenefit cb = new CoverageBenefit(
				Name = 'Coverage Benefit',
				Care_Program_Enrollee__c = careProgramEnrolleeId,
				MemberPlanId = lstMemberPlan[0].Id,
				J_CoverageBenefitStatus__c = 'Pending'
			);
			Database.SaveResult[] insertResults = COM_DatabaseOperationsUtility.insertOperation(
				new List<SObject>{cb}, 'CoverageBenefit', false
			);
			coverageBenefitId = insertResults[0].getId();
			memberPlanId = lstMemberPlan[0].Id;
		}
		
		// Create and insert the CarePreauth record
		CarePreauth carePreauth = new CarePreauth(
			Name = 'Prior Authorization',
			J_CoverageBenefit__c = coverageBenefitId,
			Care_Program_Enrollee__c = careProgramEnrolleeId,
			MemberPlanId = memberPlanId,
			Authorization_Number__c = priorAuth,
			J_AuthorizationStartDate__c = lead.Prior_Authorization_Effective_Dates__c,
			J_AuthorizationObtainedBy__c = lead.Additional_Considerations__c
		);
		Database.SaveResult[] insertResults = COM_DatabaseOperationsUtility.insertOperation(
		new List<SObject>{carePreauth}, 'CarePreauth', false
);
	} catch(Exception ex) {
		GenericLogger.exceptionLog('J_HCPLeadPriorAuthHelper','processPriorAuthorization',ex);
	}
}
}