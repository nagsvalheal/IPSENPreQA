public class J_HCPCaregiverConsentWrapper {
     public Id leadId;
    public Map<Id, Lead> mapLead;
    public Id careProgramEnrolleeID;
    public Id rectypeId;
    public Id authFormTextId;
    public Id physicianID;
    public List<Enrollee_Caregiver__c> lstEnroleeCaregiver;
    public List<Id> leadIds;

    public  J_HCPCaregiverConsentWrapper(
        Id leadId,
        Map<Id, Lead> mapLead,
        Id careProgramEnrolleeID,
        Id rectypeId,
        Id authFormTextId,
        Id physicianID,
        List<Enrollee_Caregiver__c> lstEnroleeCaregiver,
        List<Id> leadIds
    ) {
        this.leadId = leadId;
        this.mapLead = mapLead;
        this.careProgramEnrolleeID = careProgramEnrolleeID;
        this.rectypeId = rectypeId;
        this.authFormTextId = authFormTextId;
        this.physicianID = physicianID;
        this.lstEnroleeCaregiver = lstEnroleeCaregiver;
        this.leadIds = leadIds;
    }

}