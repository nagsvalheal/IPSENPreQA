/**
 * @description This class is responsible for updating Account fields based on Lead data and handling the creation or update of Care Program Enrollees.
 * It includes methods for updating Account fields, checking for existing Care Program Enrollees, and creating new ones if necessary.
 */
public without sharing class J_LeadMergeAccountUpdateHelper {

    /**
     * @description This method updates the Account fields based on the provided Lead data. It also creates or updates the Care Program Enrollee record 
     * if necessary, based on the Care Program ID and Account ID.
     * @param accountId The ID of the Account to be updated.
     * @param mapLead A map of Lead records, keyed by Lead Id, containing data for the update.
     * @param leadId The ID of the Lead to be used for updating the Account.
     */
    public static void updateAccountAndEnrollee(Id accountId, Map<Id, Lead> mapLead, Id leadId) {
        // Fetch Account
        Account account = fetchAccount(accountId);
        if (account != null) {
            J_LeadMergeAccountHelper.updateAccountFields(account, mapLead.get(leadId));
            if (Schema.sObjectType.Account.fields.PersonBirthdate.isUpdateable()) {
                update account;
            }
        }
        // Handle CareProgramEnrollee
        handleCareProgramEnrollee(accountId, mapLead, leadId);
    }
        /**
         * @description Fetches the Account record based on the provided Account Id.
         * @param accountId The Id of the Account to fetch.
         * @return Account The Account record matching the provided Id, or null if no match is found.
         */
        private static Account fetchAccount(Id accountId) {
            String fieldsAcc = 'Id, PersonMailingStreet, PersonMailingCity, PersonMailingState, PersonMailingPostalCode, ' +
                            'PersonMailingCountry, PersonMailingStateCode, PersonMailingCountryCode, Preferred_Contact_Method__pc, ' +
                            'Home_Work_Mobile__pc, PersonHomePhone, PersonMobilePhone, PersonOtherPhone, J_PrimaryAddress__c, ' +
                            'J_SpokenLanguage__c, J_WrittenLanguage__c, Patient_Status__pc, J_Sex_Account__c, J_was_owner_changed__c, ' +
                            'J_Best_Time_to_Contact__pc, Approximate_Household_Income__c, J_NumberOfPeopleInHousehold__c';

            String conditionsAcc = 'Id = \'' + accountId + '\'';
            List<SObject> result = COM_QueryUtility.executeQuery('Account', fieldsAcc, conditionsAcc, true);
            return (result != null && !result.isEmpty()) ? (Account) result[0] : null;
        }


        /**
         * @description Handles the CareProgramEnrollee creation or update.
         * @param accountId The Id of the Account associated with the enrollee.
         * @param mapLead A map of Lead Ids to Lead objects, used to retrieve lead-related information.
         * @param leadId The Id of the Lead being processed.
         */
        private static void handleCareProgramEnrollee(Id accountId, Map<Id, Lead> mapLead, Id leadId) {
            Id careProgramId = mapLead.get(leadId).Care_Program__c;
            Id existingEnrolleeId = checkCPEnrolleeExist(careProgramId, accountId);

            if (existingEnrolleeId == null) {
                createCareProgramEnrollee(accountId, careProgramId, mapLead.get(leadId), leadId);
            } else {
                updateCareProgramEnrollee(existingEnrolleeId, mapLead.get(leadId), leadId);
            }

            processCaregiversOrHealthcareProviders(existingEnrolleeId, mapLead, accountId, leadId);
        }

        /**
         * @description Creates a new CareProgramEnrollee.
         * @param accountId The Id of the Account associated with the enrollee.
         * @param careProgramId The Id of the Care Program being associated with the enrollee.
         * @param lead The Lead record containing the information necessary to create the Care Program Enrollee.
         * @param leadId The Id of the Lead being processed.
         */
        private static void createCareProgramEnrollee(Id accountId, Id careProgramId, Lead lead, Id leadId) {
            CareProgramEnrollee cpe = new CareProgramEnrollee();
            cpe.Name = lead.FirstName + '-' + lead.Care_Program__r.Name;
            cpe.CareProgramId = careProgramId;
            cpe.AccountId = accountId;
            cpe.Status = 'Pending';
            cpe.Sub_Status__c = 'New Enrollment';

            Id patientsCaregiversRecordTypeId = COM_QueryUtility.retrieveRecordTypeId('Lead', 'Patients_Caregivers');
            if (lead.RecordTypeId == patientsCaregiversRecordTypeId) {
                cpe.LeadId = leadId;
            } else {
                cpe.HCP_Lead__c = leadId;
            }
            cpe.SourceSystem = lead.LeadSource;
            List<CareProgramEnrollee> enrolleeToUpdate = new List<CareProgramEnrollee>();
            enrolleeToUpdate.add(cpe);
            Database.SaveResult[] updateResults = COM_DatabaseOperationsUtility.insertOperation(
                enrolleeToUpdate,
                'J_LeadMergeAccountUpdateHelper',
                true
            );
            for (Database.SaveResult result : updateResults) {
                if (!result.isSuccess()) {
                    GenericLogger.debugLog('Failed to create Enrollee' + result.getErrors());
                }
            }
        }

        /**
         * @description Updates an existing CareProgramEnrollee.
         * @param enrolleeId The Id of the existing Care Program Enrollee to be updated.
         * @param lead The Lead record containing updated information for the enrollee.
         * @param leadId The Id of the Lead being processed.
         */
        private static void updateCareProgramEnrollee(Id enrolleeId, Lead lead, Id leadId) {
            String fields = 'Id, CareProgramId, AccountId, LeadId, HCP_Lead__c, SourceSystem';
            String conditions = 'Id = \'' + enrolleeId + '\'';
            List<SObject> results = COM_QueryUtility.executeQuery('CareProgramEnrollee', fields, conditions, true);

            if (!results.isEmpty()) {
                CareProgramEnrollee enrollee = (CareProgramEnrollee) results[0];

                Id patientsCaregiversRecordTypeId = COM_QueryUtility.retrieveRecordTypeId('Lead', 'Patients_Caregivers');
                if (lead.RecordTypeId == patientsCaregiversRecordTypeId) {
                    enrollee.LeadId = leadId;
                } else {
                    enrollee.HCP_Lead__c = leadId;
                }
                List<CareProgramEnrollee> enrolleeToUpdate = new List<CareProgramEnrollee>();
                enrolleeToUpdate.add(enrollee);
                Database.SaveResult[] updateResults = COM_DatabaseOperationsUtility.updateOperation(
                    enrolleeToUpdate,
                    'J_InteractionDetailsTriggerHandler',
                    true
                );
                for (Database.SaveResult result : updateResults) {
                    if (!result.isSuccess()) {
                        GenericLogger.debugLog('Failed to update enrollee: ' + result.getErrors());
                    }
                }
            }
        }

        /**
         * @description Processes caregivers or healthcare providers.
         * @param enrolleeId The Id of the Care Program Enrollee to process. If null, no enrollee is processed.
         * @param mapLead A map containing the Lead records, keyed by Lead Id.
         * @param accountId The Id of the Account associated with the Lead.
         * @param leadId The Id of the Lead being processed.
         */
        private static void processCaregiversOrHealthcareProviders(Id enrolleeId, Map<Id, Lead> mapLead, Id accountId, Id leadId) {
            List<CareProgramEnrollee> enrolleeList = new List<CareProgramEnrollee>();
            if (enrolleeId != null) {
                String objectType = 'CareProgramEnrollee';
		        String fields = 'Id';
                String conditions = 'Id =\''+ enrolleeId + '\'';
			    List<SObject> enrollees = COM_QueryUtility.executeQuery(objectType, fields, conditions, true);
                if (!enrollees.isEmpty()) {
                    CareProgramEnrollee enrollee = (CareProgramEnrollee) enrollees[0];
                    enrolleeList.add(enrollee);
                }
            }
            ConvertLeadToPatient.processCaregiversOrHealthcareProviders(
                new Map<Id, Lead>{leadId => mapLead.get(leadId)},
                new Map<Id, Id>{leadId => accountId},
                enrolleeList
            );
        }

        /**
        * @description This method checks if a Care Program Enrollee already exists for the given Care Program and Account ID.
        * @param careProgramId The ID of the Care Program.
        * @param accountID The ID of the Account.
        * @return The ID of the existing Care Program Enrollee or null if none exists.
        */
        public static Id checkCPEnrolleeExist(Id careProgramId, Id accountID) {
            // Define the fields to select
            String fields = 'Id, Name';
            
            // Define the conditions for the query
            String conditions =  'CareProgramId = \'' + careProgramId + '\' AND AccountId = \'' + accountID + '\'';
            
            // Call the utility method to get the CareProgramEnrollee records
            List<SObject> results = COM_QueryUtility.executeQuery('CareProgramEnrollee', fields, conditions, true);
            
            // Initialize the recordID variable
            Id recordID = null;
            
            // If records are found, retrieve the first result
            if (results.size() > 0) {
                CareProgramEnrollee existingEnrollee = (CareProgramEnrollee)results[0];
                recordID = existingEnrollee.Id;
            }
            
            // Return the record ID (or null if no record is found)
            return recordID;
        }
        
}