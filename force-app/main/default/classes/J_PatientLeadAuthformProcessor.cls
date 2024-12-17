public without sharing class J_PatientLeadAuthformProcessor {

    public static void processLeadConsent(List<Id> leadIds, Map<Id, Lead> mapLead, Id authFormTextId, Id careProgramEnrolleeID, Id enrolleeLegalCaregiverID) {
        // Fetch consent information
        // List<Lead_Consent_For_Information__c> lstConsentInfo = [
        //     SELECT Id, Lead__c, Signature_of_Patient_or_Parent_LG__c, Signatured_Date__c, Type__c
        //     FROM Lead_Consent_For_Information__c
        //     WHERE Lead__c = :leadIds
        //     WITH SECURITY_ENFORCED
        // ];

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
        System.debug('Lead Convert, lstConsentInfo ---------->: ' + lstConsentInfo);
     
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
            System.debug(
                'Consent Info: Sign_Parent_LG_PHI: ' + signParentLGPHI +
                ', Sign_Date_Parent_LG_PHI: ' + signDateParentLGPHI +
                ', Sign_Parent_LG_GI: ' + signParentLGGI +
                ', Sign_Date_Parent_LG_GI: ' + signDateParentLGGI
            );
        }
     
        System.debug('Lead Convert, ***********Consent Creation Begin*****************');
     
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
        System.debug('Lead Convert, Auth Form Consent After Insert: ' + afc);
     
        // // Create Consent Document record
        // Consent_Doc__c consentDoc = new Consent_Doc__c();
        // consentDoc.Authorization_Form_Consent__c = afc.Id;
        // consentDoc.Name = 'Patient Authorization Document';
     
        // insert consentDoc;
        // System.debug('Consent Document Inserted: ' + consentDoc);
        // if (consentDoc.Id != null) {
        //     ConvertLeadToPatient.linkConsentDocumentToAttachment(consentDoc.Id, leadIds, mapLead);
        // }
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
            System.debug('Consent Document Insert Results: ' + consentDocInsertResults);
        
            if (!consentDocInsertResults.isEmpty() && consentDocInsertResults[0].isSuccess()) {
                consentDoc.Id = consentDocInsertResults[0].getId();
                ConvertLeadToPatient.linkConsentDocumentToAttachment(consentDoc.Id, leadIds, mapLead);
            }
        }
     }
 
 
    //convertstring
    public static string convertData(string data)
    {
        if(data == 'Yes - I Agree')  {
            return 'Opt-in';
        }
        else if(data =='No - I Do Not Agree') {
            return 'Opt-out';
        }
        else if(data == 'SMS' ) {
            return 'Text'; //Preferred Method of Contact to Account
        }
        else if(data == 'Cell') {
            return 'Mobile'; //Preferred Phone to Account
        }
        else if(data == 'Work') {
            return 'Other'; //Preferred Phone to Account
        }
        else if(data != null && (data == 'mg' || data.contains('Milligram'))) {
            return 'Milligram (mg)';
        }
        else if(data != null && (data == 'mcg' || data.contains('Microgram'))) {
            return 'Micrograms (mcg)';
        }
        else if(data != null && (data == 'ml' || data.contains('Milliliter'))) {
            return 'Milliliter (ml)';
        }
        else if(data == 'Units' ) {
            return 'Units (U)';
        }
        else if(data == 'Caps') {
            return 'Caps';
        }
        else if(data != null){
            return data;
        }
        else {
            return null;
        }
        
    }
 
    //convert date time
    public static datetime convertDatetime(date dt)
    {
        integer offset;
        TimeZone tz = UserInfo.getTimeZone();
        Datetime newdt = DateTime.newInstance(dt.year(), dt.month(),dt.day());
        
        //offset = tz.getOffset(newdt) /(1000*60*60);
        //newdt = newdt.addHours(offset);
        return newdt;
    }
 
    //source
 
    public static string consentSource(string data)
    {
 
        if(data == 'Web' || data == 'Website')  {
            return 'Website';
        }
        else if(data =='Email' || data == 'Fax' || data == 'Paper' || data == 'Other' || data =='Purchased List' || data == 'Partner Referral' || data =='Phone Inquiry') {
            return data;
        }
        else {
            return 'Other';
        }
        
    }    

}