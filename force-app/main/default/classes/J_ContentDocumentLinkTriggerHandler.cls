/**
 * @description       : 
 * @author            : 
 * @group             : 
 * @last modified on  : 08-03-2022
 * @last modified by  : 
**/
public with sharing class J_ContentDocumentLinkTriggerHandler {
    // Prevents attachment upload for User with PEL Role
    public void checkCreateAccess(List<ContentDocumentLink> contentDocumentLinks) {
        Id userRoleId = UserInfo.getUserRoleId();
        List<String> interactionDetailsIds = new List<String>();
        for (ContentDocumentLink cdl : contentDocumentLinks) {
            String objectName = cdl.LinkedEntityId.getSobjectType().getDescribe().getName();
            if (objectName == J_ObjectUtils.ACTIVITY_INTERACTION_DETAILS_API_NAME) {
                interactionDetailsIds.add(cdl.LinkedEntityId);
            }
        }
        Map<Id, J_InteractionDetails__c> interactionDetailsByIds = new Map<Id, J_InteractionDetails__c>([
                SELECT RecordType.DeveloperName
                FROM J_InteractionDetails__c
                WHERE Id IN :interactionDetailsIds
        ]);

        if (String.isNotEmpty(userRoleId)) {
            UserRole currentUserRole = [SELECT DeveloperName FROM UserRole WHERE Id = :userRoleId WITH SECURITY_ENFORCED];
            if (currentUserRole != null && currentUserRole.DeveloperName == J_ObjectUtils.ROLE_NAME_PEL_USER) {
                for (ContentDocumentLink cdl : contentDocumentLinks) {                    
                    if (cdl.LinkedEntityId.getSobjectType().getDescribe().getName() == J_ObjectUtils.ACTIVITY_INTERACTION_DETAILS_API_NAME &&
                            interactionDetailsByIds.containsKey(cdl.LinkedEntityId)) {
                        if (interactionDetailsByIds.get(cdl.LinkedEntityId).RecordType.DeveloperName != J_ObjectUtils.INTERACTION_DETAILS_RECORD_TYPE_NAME_J_PATIENT_MEETING_EVENT_DETAILS && 
                           interactionDetailsByIds.get(cdl.LinkedEntityId).RecordType.DeveloperName != J_ObjectUtils.INTERACTION_DETAILS_RECORD_TYPE_NAME_PATIENT_AMBASSADOR_EVENT) {
                            cdl.addError(Label.J_PELUserIsNotAllowedToAttachFiles);
                        }
                   // } else if (cdl.LinkedEntityId.getSobjectType().getDescribe().getName() != J_ObjectUtils.USER_API_NAME) {
                      } else if(!J_ObjectUtils.pelObjectExcludes.contains(cdl.LinkedEntityId.getSobjectType().getDescribe().getName())){
                        cdl.addError(Label.J_PELUserIsNotAllowedToAttachFiles);
                    }
                }
            }
        } else {
            for (ContentDocumentLink cdl : contentDocumentLinks) {
                cdl.addError(Label.J_CurrentUserHasNoRole);
            }
        }
    }   
   
    //For Consent Enrolment form.
    public void checkEnrollmentForm2ActivateConsent(List<ContentDocumentLink> lstContentDocumentLinks){
        list<AuthorizationFormConsent> lstConsent = new list<AuthorizationFormConsent>();
        //Id hcpLeadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Healthcare Providers').getRecordTypeId();
        //Id patientLeadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Patients/Caregivers').getRecordTypeId();
        map<id,id> mapConsentPatient = new map<id,id>();
        map<id,id> mapAccountConset = new map<id,id>();
        //set<id> setAccountID = new set<id>();
        set<id> parentRecordID = new set<id>();
        map<id,id> mapContentDocumentEntity = new map<id,id>();
        map<id,id> mapConsentDocEntity = new map<id,id>();
        map<string,string> mpConsentEnrollName = new map<string,string>();   
        map<string,string> mpExistDocumentCont = new map<string,string>(); 
        List <AuthorizationFormConsent> afc = new List <AuthorizationFormConsent>();
        id ConsentDocID;
        for (ContentDocumentLink cv : lstContentDocumentLinks) {
            if(cv.LinkedEntityId.getSObjectType().getDescribe().getName()=='Consent_Doc__c'){
                for(Consent_Doc__c c:[select Authorization_Form_Consent__c from Consent_Doc__c WHERE id =: cv.LinkedEntityId]){
                   parentRecordID.add(c.Authorization_Form_Consent__c);
                   mapConsentDocEntity.put(cv.LinkedEntityId, c.Authorization_Form_Consent__c);
                    ConsentDocID = cv.LinkedEntityId;
                }
                mapContentDocumentEntity.put(cv.LinkedEntityId, cv.ContentDocumentId);
            }        
        }
        if(parentRecordID.size()>0)
        {
            map<id,AuthorizationFormConsent> mapConsent =new map<id,AuthorizationFormConsent>([select id, Care_Program_Enrollee__c,J_TypeOfConsent__c,J_ConsentStatus__c, Expected_Enrollment_File_Name__c 
                                                                       from AuthorizationFormConsent where id =: parentRecordID 
                                                                       and J_TypeOfConsent__c IN ('Patient Authorization','HCP Authorization')]);
            system.debug('mapConsent :'+mapConsent);
            
            for(ID consentID:mapConsent.keyset()){
                mpConsentEnrollName.put(ConsentDocID,mapConsent.get(consentID).Expected_Enrollment_File_Name__c);
                //mapAccountConset.put(consentID,mapConsent.get(consentID).J_Patient__c);
                //setAccountID.add(mapConsent.get(consentID).J_Patient__c);
                afc = [select id,name,J_TypeOfConsent__c,J_ConsentStatus__c FROM AuthorizationFormConsent 
                                                       WHERE Care_Program_Enrollee__c =:mapConsent.get(consentID).Care_Program_Enrollee__c
                                                      AND J_TypeOfConsent__c =: mapConsent.get(consentID).J_TypeOfConsent__c 
                                                      AND J_ConsentStatus__c ='Active'
                                                      AND id!=:mapConsent.get(consentID).id];
                if(!afc.isEmpty()){
                    for (ContentDocumentLink cdl : lstContentDocumentLinks) {
                        cdl.addError('Enrollee already has an "Active" consent of the same type. Cannot upload the file.');
                    }
                }
            }                
            map<id,ContentDocument> mapContentDocument = new map<id,ContentDocument>([SELECT id, Title, FileExtension 
                                                                                     FROM ContentDocument WHERE ID =:mapContentDocumentEntity.values()]);
            
            list<ContentDocumentLink> lstExistDocumentLink = [SELECT id,LinkedEntityId, ContentDocument.Title, ContentDocument.FileExtension 
                                                                                     FROM ContentDocumentLink WHERE LinkedEntityId =:parentRecordID WITH SECURITY_ENFORCED]; 
           
            if(lstExistDocumentLink!=null && lstExistDocumentLink.size()>0){
                for(ContentDocumentLink docLink :lstExistDocumentLink ){
                    if(mpConsentEnrollName!=null && mpConsentEnrollName.containskey(docLink.LinkedEntityId) 
                       && mpConsentEnrollName.get(docLink.LinkedEntityId)==docLink.ContentDocument.Title)
                    {
                        mpExistDocumentCont.put(docLink.LinkedEntityId,docLink.ContentDocument.Title);
                    }
                }
            }            
            for (ContentDocumentLink cv : lstContentDocumentLinks) {                
                if(mpExistDocumentCont!=null && mpExistDocumentCont.containskey(cv.LinkedEntityId) 
                   && mpExistDocumentCont.get(cv.LinkedEntityId)== (mapContentDocument.get(cv.ContentDocumentId)).Title 
                   && (mapContentDocument.get(cv.ContentDocumentId)).FileExtension == 'PDF')
                {                   
                    cv.addError('Enrollment form already exists. Cannot upload a new one.');                   
                }
            }
            /*
            set<id> convertedHCPAccountIDs = new set<id>();
            map<id,Lead> mapObjLead =new map<id,lead> ([SELECT id,ConvertedAccountId,Expected_Enrollment_File_Name__c,recordtypeID 
                                     from Lead where ConvertedAccountId =:mapAccountConset.values()
                                     and (recordtypeID=:hcpLeadRecordTypeId or recordtypeID=:patientLeadRecordTypeId)]);
            if(mapObjLead!=null && mapObjLead.size()>0){
                for(ID leadID:mapObjLead.keyset()){
                    convertedHCPAccountIDs.add(mapObjLead.get(leadID).ConvertedAccountId);
                }
            }else{
                for(string accountid: mapAccountConset.values()){
                    convertedHCPAccountIDs.add(accountid);
                }
            }*/
            
           for(ContentDocumentLink cv : lstContentDocumentLinks){
                if(cv.LinkedEntityId.getSObjectType().getDescribe().getName()=='Consent_Doc__c')
                {
                    if(mapContentDocument.containskey(cv.ContentDocumentId) 
                       && mapConsentDocEntity.containskey(cv.LinkedEntityId) 
                       && (mapContentDocument.get(cv.ContentDocumentId)).Title ==(mapConsent.get(mapConsentDocEntity.get(cv.LinkedEntityId)).Expected_Enrollment_File_Name__c)                                
                       && (mapContentDocument.get(cv.ContentDocumentId)).FileExtension == 'PDF'                          
                       //&& convertedHCPAccountIDs.contains(mapAccountConset.get(cv.LinkedEntityId))
                      )
                    {
                        AuthorizationFormConsent consent = mapConsent.get(mapConsentDocEntity.get(cv.LinkedEntityId));
                        consent.J_ConsentStatus__c = 'Active';
                        consent.J_EnrollmentFormAttached__c = true;
                        lstConsent.add(consent);
                    }
                }
                
            }
            system.debug('lstConsent :'+lstConsent);
            if(lstConsent.size()>0){
                try{
                    if (Schema.sObjectType.AuthorizationFormConsent.fields.J_ConsentStatus__c.isUpdateable()){
                
                         COM_DatabaseOperationsUtility.updateOperation(lstConsent,J_ContentDocumentLinkTriggerHandler.class.toString(),false);
                    }
                } catch(exception ex){
                   
                }
            }
            
            
        }
        
    }
    // for PAP Enrollment Form
    public void checkFileNameForEnrollmentForm(List<ContentDocumentLink> contentDocumentLinks){
        List<String> papIds = new List<String>();
        List<String> contentDocumentIds = new List<String>();
        Map<String,String> fileNameByContentIds = new Map<String,String>();
        for (ContentDocumentLink cdl : contentDocumentLinks) {
            if (cdl.LinkedEntityId.getSobjectType().getDescribe().getName() == 'J_Charitable__c') {
                papIds.add(cdl.LinkedEntityId);
                contentDocumentIds.add(cdl.ContentDocumentId);
            }
        }
        
        if(contentDocumentIds.size()>0)
        {
            Map<Id, ContentDocument> contentDocumentsByIds = new Map<Id, ContentDocument>([SELECT Id, Title from ContentDocument where Id IN: contentDocumentIds]);
            
            //check if Enrollment form has been uploaded previously
            Map<Id, J_Charitable__c> papsByIds  = new Map<Id, J_Charitable__c>([SELECT Id, J_CharitableStatus__c, Enrollment_Form_Uploaded__c, Care_Program_Enrollee__r.Account.FirstName, Care_Program_Enrollee__r.Account.LastName from J_Charitable__c where Id IN: papIds]);
            List<J_Charitable__c> papsToUpdate = new List<J_Charitable__c>();
            Boolean enrollmentFormUploaded = false;
            
            for (ContentDocumentLink cdl : contentDocumentLinks) {
                if (cdl.LinkedEntityId.getSobjectType().getDescribe().getName() == 'J_Charitable__c') {
                    J_Charitable__c papRecord = papsByIds.get(cdl.LinkedEntityId);
                    String validEnrollmentFileName = papRecord.Care_Program_Enrollee__r.Account.FirstName+' '+papRecord.Care_Program_Enrollee__r.Account.LastName+' - '+'PAP Enrollment Form';
                    GenericLogger.debugLog(validEnrollmentFileName);
                    String fileName = contentDocumentsByIds.get(cdl.ContentDocumentId)?.Title;
                    GenericLogger.debugLog(fileName);
                    
                    if(!papRecord.Enrollment_Form_Uploaded__c){
                        if(fileName == validEnrollmentFileName){
                            papRecord.Enrollment_Form_Uploaded__c = true;
                            papsToUpdate.add(papRecord);
                        }
                      
                    }
                }
            }
            
            if(papsToUpdate.size()>0){
               
                 COM_DatabaseOperationsUtility.updateOperation(papsToUpdate,J_ContentDocumentLinkTriggerHandler.class.toString(),false);
            }
        }
    }
 
     
    
}