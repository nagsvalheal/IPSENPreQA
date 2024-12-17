public class ConvertLeadToPatientMerge {
    @InvocableMethod(label='Convert Lead to Patient Merge' description='Converts the Lead to Person Account which is nothing but patient' category='Lead')
    
    public static list<Id> convertLead(list<FlowRequest> lstRequest)
    {
        Savepoint sp = Database.setSavepoint();
        try{
            system.debug('Lead Convert Merge :-************Lead Convert Merge Start for Lead :'+lstRequest[0].iLeadID + ' And AccountID :'+lstRequest[0].iAccountID);
            string LeadRecordType;
            list<Id> AccoundIds = new list<Id>();
            AccoundIds.add(lstRequest[0].iAccountID);
            List<Id> lstLeadID = new List<Id>();
            lstLeadID.add(lstRequest[0].iLeadID);
            
            // Fields to query from Lead object
            String leadFields = 'Id, Name, FirstName, MiddleName, J_Date_of_Birth__c, Street, City, State, PostalCode, Country, StateCode, CountryCode, ' +
                'J_Prescriber_Preferred_Method_of_Contact__c, J_Home_Phone__c, J_Cell_Phone__c, J_Work_Phone__c, Preferred_Phone__c, J_Account_Owner_User_CCTOwner__c, J_Sex__c, ' +
                'J_Consent_Effective_Date__c, Consented_by_Others__c, J_Patient_Is_Patient_Insured__c, Preferred_Language__c, J_Consent_text_message__c, J_Consent_voice_call__c, ' +
                'J_Consent_email__c, J_Consent_mail__c, J_Consent_marketing_info__c, RecordType.DeveloperName, Expected_Enrollment_File_Name__c, Other_diagnosis__c, ' +
                'J_Secondary_ICD_10_Code__c, J_Caregiver_Name_HCP__c, J_Caregiver_Last_Name_HCP__c, J_Caregiver_Email_HCP__c, J_Caregiver_Phone_HCP__c, ' +
                'J_Relationship_to_Patient_HCP__c, J_Enter_Relationship_HCP__c, Care_Program__c, Care_Program__r.name, LeadSource, Best_Time_to_Contact__c, ' +
                'AnnualHouseholdincome__c, Numberofpeopleinhousehold0__c, PreferredSpecialtyPharmacy0__c, RxSent__c, SpecialtyPharmacyName__c, J_Primary_Diagnosis__c, ' +
                'J_Primary_ICD_10_Code__c, DateofDiagnosisMMDDYY__c, J_Pruritus__c, PFIC_type__c, Kg_weight__c, J_Date_Measured__c, Prior_Authorization_if_known__c, ' +
                'Prior_Authorization_Effective_Dates__c, Additional_Considerations__c';
            
            // Define conditions using lstRequest[0].iLeadID and include + '' for type safety
            String leadConditions = 'Id = \'' + lstRequest[0].iLeadID + '\'';
            
            // Call COM_QueryUtility to fetch Lead data
            Map<Id, Lead> mapLead = new Map<Id, Lead>((List<Lead>) COM_QueryUtility.executeQuery('Lead', leadFields, leadConditions, true));

            system.debug('Lead Convert Merge,mapLead :'+ mapLead);
            Database.LeadConvert lc = new Database.LeadConvert();
            for(ID leadID:lstLeadID)
            {
                lc.setLeadId(leadID);
                lc.setConvertedStatus('Completed');
                lc.setAccountId(AccoundIds[0]);
                lc.setDoNotCreateOpportunity(true);
                lc.bypassaccountdedupecheck = false;
                lc.bypassContactDedupeCheck  = false;
            }
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            LeadRecordType = mapLead.get(lcr.getLeadId()).RecordType.DeveloperName;
            
            system.debug('Lead Convert Merge,Lcr :' + lcr);
            system.debug('Lead Convert Merge,lcr.getAccountId() :' + lcr.getAccountId() + ', LeadRecordType :'+ LeadRecordType);
            
            //call the helper method to update Account fields
			J_LeadMergeAccountUpdateHelper.updateAccountAndEnrollee(lcr.getAccountId(), mapLead, lstRequest[0].iLeadID);
            
            
            return AccoundIds;
        }
        catch(exception ex){
            Database.rollback(sp);
            
            GenericLogger.exceptionLog('Lead to Patient Convert Merge',lstRequest[0].iLeadID,ex);
            System.debug('Lead to Patient Convert Merge Error ---------:'+ ex);
            return null;
        }
        
        
    }
    
    
    
    public class FlowRequest
    {
        @InvocableVariable (label='iLeadID')
        public String iLeadID;
        @InvocableVariable (label='iAccountID')
        public String iAccountID;       
    }
    
    
}