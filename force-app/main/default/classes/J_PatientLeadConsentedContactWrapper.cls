public class J_PatientLeadConsentedContactWrapper {
   
        public Lead_Consented_Contact__c contact;
        public List<Id> careProgramEnrolleeIds;
        public RecordType caregiverRecordType;
        public List<Account> caregiversToInsert;
        public List<Enrollee_Caregiver__c> enrolleeCaregiversToInsert;
        public Id enrolleeLegalCaregiverId;
    
        public J_PatientLeadConsentedContactWrapper(
            Lead_Consented_Contact__c contact,
            List<Id> careProgramEnrolleeIds,
            RecordType caregiverRecordType,
            List<Account> caregiversToInsert,
            List<Enrollee_Caregiver__c> enrolleeCaregiversToInsert,
            Id enrolleeLegalCaregiverId
        ) {
            this.contact = contact;
            this.careProgramEnrolleeIds = careProgramEnrolleeIds;
            this.caregiverRecordType = caregiverRecordType;
            this.caregiversToInsert = caregiversToInsert;
            this.enrolleeCaregiversToInsert = enrolleeCaregiversToInsert;
            this.enrolleeLegalCaregiverId = enrolleeLegalCaregiverId;
        }
     
    

}