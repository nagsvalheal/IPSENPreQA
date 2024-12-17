public without sharing class J_PatientLeadCaregiverProcessor {

    /*public static void processCaregiversAndConsents(List<Id> careProgramEnrolleeIds, Id careProgramId, String leadRecordType, List<Id> leadIds) {
        if (leadRecordType != 'Patients_Caregivers') {
           
            return;
        }
        
    
        System.debug('Processing Caregivers and Consented Contacts for Leads: ' + leadIds);
    
        // Fetch caregiver record type
        RecordType caregiverRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = TRUE AND Name = 'Journeys Caregiver' LIMIT 1];
    
        // Fetch authorization form text
        Id authFormTextId = ConvertLeadToPatient.getAuthFormText(careProgramId, 'Journeys Authorization Form', 'Journeys Authorization Form Text');
    
        // Fetch consented contacts related to leads
        List<Lead_Consented_Contact__c> consentedContacts = [
            SELECT id,Lead__c,Parent_Legal_Consent__c,First_Name__c,Last_Name__c,Phone__c,Email__c,Relationship_To_Patient__c,Enter_Relationship__c
            FROM Lead_Consented_Contact__c
            WHERE Lead__c IN :leadIds
            WITH SECURITY_ENFORCED
        ];
    
        System.debug('Fetched Consented Contacts: ' + consentedContacts);
    
        if (consentedContacts.isEmpty()) {
            return;
        }
    
        // Prepare lists for bulk DML
        List<Account> caregiversToInsert = new List<Account>();
        List<Enrollee_Caregiver__c> enrolleeCaregiversToInsert = new List<Enrollee_Caregiver__c>();
        Id enrolleeLegalCaregiverId = null;
    
        // Process each consented contact
        for (Lead_Consented_Contact__c contact : consentedContacts) {
            if (contact.Last_Name__c == null || contact.Last_Name__c.trim() == '') {
                continue;
            }
    
            Id caregiverId = checkCaregiverExist(
                caregiverRecordType.Id, contact.First_Name__c, contact.Last_Name__c,
                contact.Email__c, contact.Phone__c, contact.Relationship_To_Patient__c, contact.Parent_Legal_Consent__c
            );
    
            // Create caregiver if not already exists
            if (caregiverId == null) {
                Account newCaregiver = assignCaregiver(
                    contact.First_Name__c, contact.Last_Name__c, contact.Email__c,
                    contact.Phone__c, contact.Relationship_To_Patient__c,
                    contact.Enter_Relationship__c, contact.Parent_Legal_Consent__c, caregiverRecordType.Id
                );
                caregiversToInsert.add(newCaregiver);
                caregiverId = newCaregiver.Id; // Set ID after creation
            }
    
          
    
            for (Id enrolleeId : careProgramEnrolleeIds) {
                // Check if enrollee-caregiver relationship exists
                Id enrolleeCaregiverId = checkEnrolleeCaregiverExist(
                    enrolleeId, caregiverId, contact.Relationship_To_Patient__c,
                    contact.Enter_Relationship__c, contact.Parent_Legal_Consent__c
                );
    
                // Create enrollee-caregiver relationship if not already exists
                if (enrolleeCaregiverId == null) {
                    Enrollee_Caregiver__c newEnrolleeCaregiver = assignEnrolleeCaregiver(
                        enrolleeId, caregiverId, contact.Relationship_To_Patient__c,
                        contact.Enter_Relationship__c, contact.Parent_Legal_Consent__c
                    );
                    enrolleeCaregiversToInsert.add(newEnrolleeCaregiver);
                    // Assign the first legal caregiver to `enrolleeLegalCaregiverId`
                    if (contact.Parent_Legal_Consent__c == true && enrolleeLegalCaregiverId == null) {
                        enrolleeLegalCaregiverId = newEnrolleeCaregiver.Id;
                    }
                }
            }
        }
    
        // Perform bulk inserts
        if (!caregiversToInsert.isEmpty() && Schema.sObjectType.Account.fields.FirstName.isCreateable()) {
            insert caregiversToInsert;
        }
    
        if (!enrolleeCaregiversToInsert.isEmpty()) {
            insert enrolleeCaregiversToInsert;
        }
    
        System.debug('Inserted Caregivers: ' + caregiversToInsert);
        System.debug('Inserted Enrollee-Caregivers: ' + enrolleeCaregiversToInsert);
    }*/
//4parametes passing
    public static void processCaregiversAndConsents(List<Id> careProgramEnrolleeIds, Id careProgramId, String leadRecordType, List<Id> leadIds) {
        System.debug('Processing Caregivers and Consented Contacts for Leads: ' + leadIds);
    
        // Step 1: Fetch necessary data
        RecordType caregiverRecordType = fetchCaregiverRecordType();
        Id authFormTextId = fetchAuthorizationFormText(careProgramId);
        List<Lead_Consented_Contact__c> consentedContacts = fetchConsentedContacts(leadIds);
    
        if (consentedContacts.isEmpty()) {
            return;
        }
    
        // Step 2: Process consented contacts
        processConsentedContacts(consentedContacts, careProgramEnrolleeIds, caregiverRecordType);
    }
    
    private static RecordType fetchCaregiverRecordType() {
        system.debug('recordtypr'); 
        return [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsPersonType = TRUE AND Name = 'Journeys Caregiver' LIMIT 1];
        // String fields = 'Id';
        // String conditions = 'SObjectType = \'Account\' AND IsPersonType = TRUE AND Name = \'Journeys Caregiver\' LIMIT 1';
        // List<SObject> recordTypeList = COM_QueryUtility.executeQuery('RecordType', fields, conditions, true);
        // system.debug('recordtypr');  
        // // Explicitly cast the first record to RecordType
        // return (RecordType) recordTypeList[0];
    }
    
    private static Id fetchAuthorizationFormText(Id careProgramId) {
        system.debug('auth');  
        return ConvertLeadToPatient.getAuthFormText(careProgramId, 'Journeys Authorization Form', 'Journeys Authorization Form Text');
    }
    
    private static List<Lead_Consented_Contact__c> fetchConsentedContacts(List<Id> leadIds) {
        system.debug('fetchConsentedContacts'); 
        return [
            SELECT id, Lead__c, Parent_Legal_Consent__c, First_Name__c, Last_Name__c, Phone__c, Email__c,
                   Relationship_To_Patient__c, Enter_Relationship__c
            FROM Lead_Consented_Contact__c
            WHERE Lead__c IN :leadIds
            WITH SECURITY_ENFORCED
        ];
    }
    
    private static void processConsentedContacts(
        List<Lead_Consented_Contact__c> consentedContacts,
        List<Id> careProgramEnrolleeIds,
        RecordType caregiverRecordType
    ) {
        
        List<Account> caregiversToInsert = new List<Account>();
        List<Enrollee_Caregiver__c> enrolleeCaregiversToInsert = new List<Enrollee_Caregiver__c>();
        Id enrolleeLegalCaregiverId = null;
    system.debug('withcheck'+consentedContacts);
    system.debug('withcheck2'+careProgramEnrolleeIds);
    system.debug('withcheck3'+caregiverRecordType);
        for (Lead_Consented_Contact__c contact : consentedContacts) {
            J_PatientLeadConsentedContactWrapper wrapper = new J_PatientLeadConsentedContactWrapper(contact, careProgramEnrolleeIds, caregiverRecordType, caregiversToInsert, enrolleeCaregiversToInsert, enrolleeLegalCaregiverId);
            processSingleConsentedContact(wrapper);
        }
    
        performBulkInserts(caregiversToInsert, enrolleeCaregiversToInsert);
    }
    
    private static void processSingleConsentedContact(
        J_PatientLeadConsentedContactWrapper wrapper
    ) {
        Id caregiverId = checkCaregiverExist(
            wrapper.caregiverRecordType.Id, wrapper.contact.First_Name__c, wrapper.contact.Last_Name__c,
            wrapper.contact.Email__c, wrapper.contact.Phone__c, wrapper.contact.Relationship_To_Patient__c, wrapper.contact.Parent_Legal_Consent__c
        );
    
        if (caregiverId == null) {
            Account newCaregiver = assignCaregiver(
                wrapper.contact.First_Name__c, wrapper.contact.Last_Name__c, wrapper.contact.Email__c,
                wrapper.contact.Phone__c, wrapper.contact.Relationship_To_Patient__c,
                wrapper.contact.Enter_Relationship__c, wrapper.contact.Parent_Legal_Consent__c, wrapper.caregiverRecordType.Id
            );
            wrapper.caregiversToInsert.add(newCaregiver);
            caregiverId = newCaregiver.Id;
        }
    
        for (Id enrolleeId : wrapper.careProgramEnrolleeIds) {
            processEnrolleeCaregiverRelationship(
                enrolleeId, caregiverId, wrapper.contact, wrapper.enrolleeCaregiversToInsert, wrapper.enrolleeLegalCaregiverId
            );
        }
    }
    //5parametes passing
    private static void processEnrolleeCaregiverRelationship(
        Id enrolleeId,
        Id caregiverId,
        Lead_Consented_Contact__c contact,
        List<Enrollee_Caregiver__c> enrolleeCaregiversToInsert,
        Id enrolleeLegalCaregiverId
    ) {
        Id enrolleeCaregiverId = checkEnrolleeCaregiverExist(
            enrolleeId, caregiverId, contact.Relationship_To_Patient__c,
            contact.Enter_Relationship__c, contact.Parent_Legal_Consent__c
        );
    
        if (enrolleeCaregiverId == null) {
            Enrollee_Caregiver__c newEnrolleeCaregiver = assignEnrolleeCaregiver(
                enrolleeId, caregiverId, contact.Relationship_To_Patient__c,
                contact.Enter_Relationship__c, contact.Parent_Legal_Consent__c
            );
            enrolleeCaregiversToInsert.add(newEnrolleeCaregiver);
    
            if (contact.Parent_Legal_Consent__c == true && enrolleeLegalCaregiverId == null) {
                enrolleeLegalCaregiverId = newEnrolleeCaregiver.Id;
            }
        }
    }
    
    private static void performBulkInserts(List<Account> caregiversToInsert, List<Enrollee_Caregiver__c> enrolleeCaregiversToInsert) {
        if (!caregiversToInsert.isEmpty() && Schema.sObjectType.Account.fields.FirstName.isCreateable()) {
            // insert caregiversToInsert;
            // i need confime this isert need are not if you get a error don't mine it 
        }
    
        if (!enrolleeCaregiversToInsert.isEmpty()) {
            //insert enrolleeCaregiversToInsert;
            List<SObject> sObjectList = new List<SObject>();
            for (Enrollee_Caregiver__c enrolleeCaregiver : enrolleeCaregiversToInsert) {
                sObjectList.add(enrolleeCaregiver);
            }
        
            // Perform the insert operation
            Database.SaveResult[] enrolleeCaregiverResults = COM_DatabaseOperationsUtility.insertOperation(
                sObjectList, 
                'performBulkInserts - EnrolleeCaregivers', 
                true
            );
            System.debug('Enrollee-Caregivers Insert Results: ' + enrolleeCaregiverResults);
        }
    
        System.debug('Inserted Caregivers: ' + caregiversToInsert);
        System.debug('Inserted Enrollee-Caregivers: ' + enrolleeCaregiversToInsert);
    }
    
    
    // Helper method to assign a new caregiver
    private static Account assignCaregiver(String firstName, String lastName, String email, String phone, String relationshipToPatient, String enterRelationship, Boolean parentLegalConsent, Id recordTypeId) {
        
        Account caregiver = new Account();
        caregiver.FirstName = firstName;
        caregiver.LastName = lastName;
        caregiver.PersonEmail = email;
        caregiver.PersonMobilePhone = phone;
        caregiver.J_RelationshipToPatient__c = relationshipToPatient;
        caregiver.J_EnterRelationship__c = enterRelationship;
        caregiver.J_LegalGuardian__c = parentLegalConsent;
        caregiver.RecordTypeId = recordTypeId;
     
       // insert caregiver;
        return caregiver;
    }
    
    // Helper method to assign a new enrollee-caregiver relationship 5parametes passing
    private static Enrollee_Caregiver__c assignEnrolleeCaregiver(Id enrolleeId, Id caregiverId, String relationshipToPatient, String enterRelationship, Boolean parentLegalConsent) {
        Enrollee_Caregiver__c enrolleeCaregiver = new Enrollee_Caregiver__c();
        enrolleeCaregiver.Care_Program_Enrollee__c = enrolleeId;
        enrolleeCaregiver.Caregiver__c = caregiverId;
        enrolleeCaregiver.Relationship__c = relationshipToPatient;
        enrolleeCaregiver.EnterRelationship__c = enterRelationship;
        enrolleeCaregiver.Consented_Caregiver__c = parentLegalConsent;
        enrolleeCaregiver.Status__c = 'Active'; 
        return enrolleeCaregiver;
    }
    
    // Placeholder method for checking if a caregiver exists
    public static Id checkCaregiverExist(
       Id recordTypeId,
       String firstName,
       String lastName,
       String email,
       String phone,
       String relationshipToPatient,
       Boolean parentLegalConsent
    ) {
       List<Account> caregivers = [
           SELECT Id
           FROM Account
           WHERE RecordTypeId = :recordTypeId
           AND FirstName = :firstName
           AND LastName = :lastName
           AND PersonEmail = :email
           AND PersonMobilePhone = :phone
           AND J_RelationshipToPatient__c = :relationshipToPatient
           AND J_LegalGuardian__c = :parentLegalConsent
           LIMIT 1
       ];
       return caregivers.isEmpty() ? null : caregivers[0].Id;
    }
    
    // Placeholder method for checking if enrollee-caregiver relationship exists 5parametes passing
    private static Id checkEnrolleeCaregiverExist(Id enrolleeId, Id caregiverId, String relationshipToPatient, String enterRelationship, Boolean parentLegalConsent) {
        List<Enrollee_Caregiver__c> enrolleeCaregivers = [
            SELECT Id
            FROM Enrollee_Caregiver__c
            WHERE Care_Program_Enrollee__c = :enrolleeId
            AND Caregiver__c = :caregiverId
            AND Relationship__c = :relationshipToPatient
            AND EnterRelationship__c = :enterRelationship
            AND Consented_Caregiver__c = :parentLegalConsent
            LIMIT 1
        ];
        return enrolleeCaregivers.isEmpty() ? null : enrolleeCaregivers[0].Id;
//     String fields = 'Id';
//     String conditions = 'Care_Program_Enrollee__c = \'' + String.escapeSingleQuotes(String.valueOf(enrolleeId)) + '\' ' +
//                         'AND Caregiver__c = \'' + String.escapeSingleQuotes(String.valueOf(caregiverId)) + '\' ' +
//                         'AND Relationship__c = \'' + String.escapeSingleQuotes(relationshipToPatient) + '\' ' +
//                         'AND EnterRelationship__c = \'' + String.escapeSingleQuotes(enterRelationship) + '\' ' +
//                         'AND Consented_Caregiver__c = ' + (parentLegalConsent ? 'TRUE' : 'FALSE') + ' LIMIT 1';

//     // Execute the query using a utility
//     List<SObject> enrolleeCaregivers = COM_QueryUtility.executeQuery('Enrollee_Caregiver__c', fields, conditions, false);
// system.debug('enrolleeCaregivers'+enrolleeCaregivers);
//     // Return the Id of the first matching record or null if no record is found
//     return enrolleeCaregivers.isEmpty() ? null : ((Enrollee_Caregiver__c) enrolleeCaregivers[0]).Id;
    }
    
    

}