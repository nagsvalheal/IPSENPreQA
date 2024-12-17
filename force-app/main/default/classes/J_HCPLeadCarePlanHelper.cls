public without sharing class J_HCPLeadCarePlanHelper {
     public static Id processCarePlan(Lead lead, Id careProgramEnrolleeId) {
        RecordType treatmentRecType = [SELECT Id,Name FROM RecordType WHERE SObjectType = 'Case' AND Name = 'CarePlan' LIMIT 1];

        Id caseId = checkCarePlanExist(treatmentRecType, careProgramEnrolleeId);
        if (caseId == null) {
            Case c = new Case(
                Care_Program_Enrollee__c = careProgramEnrolleeId,
                Status = 'Pending',
                RecordTypeId = treatmentRecType.Id,
                J_PreferredSpecialtyPharmacy__c = lead.PreferredSpecialtyPharmacy0__c,
                J_RXSent__c = lead.RxSent__c,
                Other_Diagnosis__c = lead.Other_diagnosis__c,
                J_Other_ICD_10_Code__c = lead.J_Secondary_ICD_10_Code__c,
                J_SpecialtyPharmacyName__c = lead.SpecialtyPharmacyName__c,
                Weight_at_Enrollment_in_Kg__c = lead.Kg_weight__c,
                Date_of_Patient_Weight__c = lead.J_Date_Measured__c,
                Disease__c = lead.J_Primary_Diagnosis__c,
                J_Primary_ICD_10_Code__c = lead.J_Primary_ICD_10_Code__c,
                Diagnosis_Date__c = lead.DateofDiagnosisMMDDYY__c,
                Pruritus__c = lead.J_Pruritus__c ? 'Yes' : 'No',
                J_PFIC_Type__c = lead.PFIC_type__c
            );
            insert c;
            caseId = c.Id;
        }
        return caseId;
    }
    
     public static id checkCarePlanExist(RecordType recTypeId, string patient)
    {
        String recordTypeName = recTypeId.Name;
        id recordID;
        if(recordTypeName =='CarePlan')
        {
            Case[] cs = [select id, CaseNumber from Case where RecordTypeId =:recTypeId.id AND Care_Program_Enrollee__c = :patient Limit 1];
            recordID = cs.size() == 0 ? null : cs[0].Id ;
        }
        System.debug('Lead Convert,checkCarePlanExist ---------:'+ recordID);
        return recordID;
    } 

}