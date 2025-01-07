/**
* @description Utility class to check caregiver relationships for patients by enrollee.
*/
public without sharing class CheckCaregiverRelationship {
    
    /**
* @description Invocable method to check caregiver relationships for a list of patient requests.
* @param lstRequest List of caregiver data.
* @return List of IDs for mismatched relationships, if any.
*/
    @InvocableMethod(label='Check Caregiver Relationship' description='Check Caregiver Relationship of the Patient by Enrollee' category='Lead')
    public static List<Id> checkExist(List<LcaregiverData> lstRequest) {
        
        if (lstRequest.isEmpty() || lstRequest[0].iAccount == null || lstRequest[0].iFirstName == null || lstRequest[0].iLastName == null || lstRequest[0].iPhone == null || lstRequest[0].iRelationship == null) { 
            return new List<Id>();
        }
        
        String accountId = lstRequest[0].iAccount;
        String firstName = lstRequest[0].iFirstName;
        String lastName = lstRequest[0].iLastName;
        String phone = lstRequest[0].iPhone;
        String relationship = lstRequest[0].iRelationship;
        
        Id careGiverId = fetchCaregiverId(firstName, lastName, phone);
        if (careGiverId == null) {
            return null;
        }
        
        List<CareProgramEnrollee> careProgramEnrollees = fetchCareProgramEnrollees(accountId);
        return findMismatchedRelationships(careProgramEnrollees, careGiverId, relationship);
    }
    
    /**
* @description Fetches the caregiver ID based on provided details.
* @param firstName Caregiver's first name.
* @param lastName Caregiver's last name.
* @param phone Caregiver's phone number.
* @return Caregiver ID or null if not found.
*/
    private static Id fetchCaregiverId(String firstName, String lastName, String phone) {
        
        String sObjectType = 'RecordType';
        String fields = 'Id';
        String conditions = 'SObjectType = \'Account\' AND IsPersonType = true AND Name = \'Journeys Caregiver\'';
        
        List<RecordType> recordTypeResults = COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
        if (!recordTypeResults.isEmpty()) {
            RecordType caregiverRecordType = (RecordType) recordTypeResults[0];
            Id caregiverId = J_PatientLeadCaregiverProcessor.checkCaregiverExist(caregiverRecordType.Id, firstName, lastName, '', phone, '', null);
            
            return caregiverId;
        }
        
        return null;
    }
    
    /**
* @description Fetches care program enrollees for the specified account.
* @param accountId Account ID.
* @return List of care program enrollee records.
*/
    private static List<CareProgramEnrollee> fetchCareProgramEnrollees(String accountId) {
        if (String.isBlank(accountId)) { 
            return new List<CareProgramEnrollee>();
        }
        
        String enrolleeSObjectType = 'CareProgramEnrollee';
        String enrolleeFields = 'Id';
        String enrolleeConditions = 'AccountId = \'' + accountId + '\'';
        
        return (List<CareProgramEnrollee>) COM_QueryUtility.executeQuery(enrolleeSObjectType, enrolleeFields, enrolleeConditions, true);
    }
    
    /**
* @description Finds mismatched relationships between enrollees and caregivers.
* @param careProgramEnrollees List of care program enrollees.
* @param careGiverId Caregiver ID.
* @param relationship Expected relationship.
* @return List of IDs for mismatched relationships.
*/
    private static List<Id> findMismatchedRelationships(
        List<CareProgramEnrollee> careProgramEnrollees, Id careGiverId, String relationship
    ) {
        if (careProgramEnrollees.isEmpty()) {
            return new List<Id>();
        }
        
        List<Id> enrolleeIds = new List<Id>();
        for (CareProgramEnrollee enrollee : careProgramEnrollees) {
            enrolleeIds.add(enrollee.Id);
        }
        
        String enrolleeIdCondition = '(\'' + String.join(enrolleeIds, '\', \'') + '\')';
        String caregiverSObjectType = 'Enrollee_Caregiver__c';
        String caregiverFields = 'Id, Relationship__c, Caregiver__c';
        String caregiverConditions = 'Care_Program_Enrollee__c IN ' + enrolleeIdCondition +
            ' AND Caregiver__c = \'' + careGiverId + '\'';
   
        List<Enrollee_Caregiver__c> caregiverRecords = COM_QueryUtility.executeQuery(caregiverSObjectType, caregiverFields, caregiverConditions, true);
        
        List<Id> mismatchedIds = new List<Id>();
        for (Enrollee_Caregiver__c ec : caregiverRecords) {
            if (ec.Relationship__c != relationship) {
                mismatchedIds.add(ec.Id);
            }
        }
        
        if (mismatchedIds.isEmpty()) {
            return new List<Id>();
        }
        
        return mismatchedIds;
    }
    
    /**
* @description Data class representing caregiver input data.
*/
    public class LcaregiverData {
        @InvocableVariable(label='iAccount')
        public String iAccount;
        
        @InvocableVariable(label='iFirstName')
        public String iFirstName;
        
        @InvocableVariable(label='iLastName')
        public String iLastName;
        
        @InvocableVariable(label='iPhone')
        public String iPhone;
        
        @InvocableVariable(label='iRelationship')
        public String iRelationship;
    }
}