public class J_HCPLeadPriorAuthHelper {
    public static void processPriorAuthorization(Lead lead, Id careProgramEnrolleeId, Id accountId) {
        String priorAuth = lead.Prior_Authorization_if_known__c;
        if (priorAuth != null && priorAuth != '') {
            List<MemberPlan> lstMemberPlan = [SELECT Id FROM MemberPlan WHERE MemberId = :accountId AND Status != 'Inactive' AND J_Role__c = 'Primary' WITH SECURITY_ENFORCED LIMIT 1];
            if (!lstMemberPlan.isEmpty()) {
                Id coverageBenefitId;
                Id memberPlanId;

                List<CoverageBenefit> lstCoverageBenefit = [SELECT Id, MemberPlanId FROM CoverageBenefit WHERE Care_Program_Enrollee__c = :careProgramEnrolleeId AND J_CoverageBenefitStatus__c IN ('Active', 'Pending') WITH SECURITY_ENFORCED LIMIT 1];
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
                    insert cb;
                    coverageBenefitId = cb.Id;
                    memberPlanId = cb.MemberPlanId;
                }

                CarePreauth carePreauth = new CarePreauth(
                    Name = 'Prior Authorization',
                    J_CoverageBenefit__c = coverageBenefitId,
                    Care_Program_Enrollee__c = careProgramEnrolleeId,
                    MemberPlanId = memberPlanId,
                    Authorization_Number__c = priorAuth,
                    J_AuthorizationStartDate__c = lead.Prior_Authorization_Effective_Dates__c,
                    J_AuthorizationObtainedBy__c = lead.Additional_Considerations__c
                );
                insert carePreauth;
            }
        }
    }

}