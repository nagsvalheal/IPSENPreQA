/**
 * @description This class is to map Lead data to formatted as needed.
 * @author Nandhakumar
 * @date 18-12-2024
 */
public without sharing class J_LeadMergeAccountHelper {
    /**
     * @description This helper method is used to convert specific Lead data to the format needed for Account fields.
     * @param data The data to be converted.
     * @return The converted data.
     */
    public static String convertData(String data) {
        // Map to store simple mappings
        Map<String, String> dataMap = new Map<String, String>{
            'Yes - I Agree' => 'Opt-in',
            'No - I Do Not Agree' => 'Opt-out',
            'SMS' => 'Text',
            'Cell' => 'Mobile',
            'Work' => 'Other',
            'Units' => 'Units (U)',
            'Caps' => 'Caps'
        };

        // Check for simple mappings
        if (dataMap.containsKey(data)) {
            return dataMap.get(data);
        }

        // Handle cases with partial matches or null data
        if (data != null) {
            if (data == 'mg' || data.contains('Milligram')) {
                return 'Milligram (mg)';
            } else if (data == 'mcg' || data.contains('Microgram')) {
                return 'Micrograms (mcg)';
            } else if (data == 'ml' || data.contains('Milliliter')) {
                return 'Milliliter (ml)';
            } else {
                return data; // Return input if no match
            }
        }

        return null; // Return null if data is null
    }
        /**
        * @description Updates Account fields with Lead data if they are null.
        * @param account The Account record to be updated.
        * @param lead The Lead record containing the values that will be used to update the Account fields.
        */
        public static void updateAccountFields(Account account, Lead lead) {
            // Update individual fields using helper method
            updateFieldIfNull(account, 'Preferred_Contact_Method__pc', 
                J_LeadMergeAccountHelper.convertData(lead.J_Prescriber_Preferred_Method_of_Contact__c));
            updateFieldIfNull(account, 'Home_Work_Mobile__pc', 
                J_LeadMergeAccountHelper.convertData(lead.Preferred_Phone__c));
            updateFieldIfNull(account, 'PersonHomePhone', lead.J_Home_Phone__c);
            updateFieldIfNull(account, 'PersonMobilePhone', lead.J_Cell_Phone__c);
            updateFieldIfNull(account, 'PersonOtherPhone', lead.J_Work_Phone__c);
            updateFieldIfNull(account, 'J_Best_Time_to_Contact__pc', lead.Best_Time_to_Contact__c);
            updateFieldIfNull(account, 'Approximate_Household_Income__c', lead.AnnualHouseholdincome__c);
            updateFieldIfNull(account, 'J_NumberOfPeopleInHousehold__c', lead.Numberofpeopleinhousehold0__c);
            updateFieldIfNull(account, 'J_SpokenLanguage__c', lead.Preferred_Language__c);
            updateFieldIfNull(account, 'J_WrittenLanguage__c', lead.Preferred_Language__c);
        
            // Update address if needed
            updateAddressIfNeeded(account, lead);
        }
        
        /**
         * @description Helper method to update an Account field if the value is null.
         * @param account The Account to update.
         * @param fieldName The name of the field to update.
         * @param newValue The value to set if the field is null.
         */
        private static void updateFieldIfNull(Account account, String fieldName, Object newValue) {
            // Use reflection to dynamically update the field if it's null
            if (account.get(fieldName) == null) {
                account.put(fieldName, newValue);
            }
        }       
        
        /**
         * @description Updates Address fields of the Account if they are null.
         * @param account The Account record whose address fields are being checked and potentially updated.
         * @param lead The Lead record from which address values are copied if the Account address fields are null.
         */
        private static void updateAddressIfNeeded(Account account, Lead lead) {
            if (account.PersonMailingStreet == null && account.PersonMailingCity == null &&
                account.PersonMailingState == null && account.PersonMailingPostalCode == null) {
                account.PersonMailingStreet = lead.Street;
                account.PersonMailingCity = lead.City;
                account.PersonMailingState = lead.State;
                account.PersonMailingStateCode = lead.StateCode;
                account.PersonMailingPostalCode = lead.PostalCode;
                account.PersonMailingCountry = lead.Country;
                account.PersonMailingCountryCode = lead.CountryCode;
            }
            if (account.PersonMailingState == null) {
                account.PersonMailingStateCode = lead.StateCode;
                account.PersonMailingPostalCode = lead.PostalCode;
                account.PersonMailingCountry = lead.Country;
                account.PersonMailingCountryCode = lead.CountryCode;
            }
        }
}