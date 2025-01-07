/**
 * @description Converts Country and State values between their codes and descriptions.
 * This class provides utility methods for handling country and state picklist values.
 */
public class J_ConvertCountry_State_Values {
    /**
     * @description Converts the Country and State values based on input.
     * @param lstRequest A list of Request objects containing input Country and State.
     * @return A list of Response objects containing converted Country and State.
     */
    @InvocableMethod(label='Convert Country/State Code' description='Converts the Country/State to Code or Descr' category='Lead')
    
    public static List<Response> getCountryState(List<Request> lstRequest)
    {
        List<Response> res = new List<Response>();
        Response r = new Response();
        string countryValue = getCountry (lstRequest[0].iCountry);
        
        r.oCountry = countryValue;
        //r.oState = getState (lstRequest[0].iState);
        if(lstRequest[0].iCountry.length() == 2)
        {
           r.oState = getRegonPiklistValuseByCode (lstRequest[0].iCountry,lstRequest[0].iState);
        }
        else 
        {
            r.oState = getRegonPiklistValuseByCode (countryValue,lstRequest[0].iState);
        }
        res.add(r);
        return res;
    }
    
     /**
     * @description Request object to hold input values for conversion.
     */
    public class Request
    {
        @InvocableVariable (label='iCountry')
        public String iCountry;
        @InvocableVariable (label='iState')
        public String iState;       
    }
    
     /**
     * @description Response object to hold output values after conversion.
     */
    public class Response
    {
        @InvocableVariable (label='oCountry')
        public String oCountry;
        @InvocableVariable (label='oState')
        public String oState;       
    }
     
    /**
     * @description Converts a Country code to its description or vice versa.
     * @param strCountry The Country value to convert (code or description).
     * @return The converted Country value (description or code).
     */
    public static String getCountry(String strCountry)
    {
        list<String> returnDate = new list<String>();
        Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        //System.debug('Picklist::'+ple);
        for( Schema.PicklistEntry f : ple)
        {
            //System.debug(f.getLabel() +'::'+ f.getValue()+'::'+ f.isActive()+'::'+ f.isDefaultValue());
            if(strCountry.length() == 2 ) // Country Code
            {
                if(f.getValue() == strCountry)
                {
                    //System.debug('Return Country Descr::'+ f.getLabel());
                    returnDate.add(f.getLabel());
                    return f.getLabel();
                }
                
            }else // Country Descr
            {
                if(f.getLabel() == strCountry)
                {
                    //System.debug('Return Country Code::'+ f.getValue());
                    returnDate.add(f.getValue());
                    return f.getValue();
                }
            }
            
        }
        return null;
    }
    
    /**
     * @description Converts a State code to its description or vice versa.
     * @param strstate The State value to convert (code or description).
     * @return The converted State value (description or code).
     */
    public static String getstate(String strstate)
    {
        list<String> returnDate = new list<String>();
        Schema.DescribeFieldResult fieldResult = User.statecode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        //System.debug('Picklist::'+ple);
        for( Schema.PicklistEntry f : ple)
        {
            if(strstate.length() == 2 ) // State Code
            {
                if(f.getValue() == strstate)
                {
                    //System.debug('Return State Descr::'+ f.getLabel());
                    returnDate.add(f.getLabel());
                    return f.getLabel();
                }
                
            }else // State Descr
            {
                if(f.getLabel() == strstate)
                {
                    //System.debug('Return State Code::'+ f.getValue());
                    returnDate.add(f.getValue());
                    return f.getValue();
                }
            }
        }
        return null;
    }
    
        /**
         * @description Converts a State value based on the Country value (dependent picklist logic).
         * @param country The Country value (code or description).
         * @param state The State value (code or description).
         * @return The converted State value based on the Country (description if input is code, and code if input is description).
         */
        public static String getRegonPiklistValuseByCode(String country, String state) {
            Map<String, List<String>> objResults = initializeCountryResults();
            List<J_DependentClassBitSet.PicklistEntryWrapper> depEntries = getDependentPicklistEntries();
            List<String> controllingValues = getControllingValues(objResults);

            for (J_DependentClassBitSet.PicklistEntryWrapper plew : depEntries) {
                if (isValidStateMatch(plew, state, country, controllingValues)) {
                    return getMatchingValue(plew, state);
                }
            }

            return null;
        }

        /**
         * @description Initializes the map of country results for dependent picklist logic.
         * @return A map with country codes as keys and empty lists as values.
         */
        private static Map<String, List<String>> initializeCountryResults() {
            Map<String, List<String>> objResults = new Map<String, List<String>>();
            Schema.DescribeFieldResult fieldResultCountry = User.Countrycode.getDescribe();
            List<Schema.PicklistEntry> contrEntries = fieldResultCountry.getPicklistValues();

            for (Schema.PicklistEntry ple : contrEntries) {
                objResults.put(ple.getValue(), new List<String>());
            }
            return objResults;
        }

        /**
         * @description Retrieves the dependent picklist entries for states from the metadata.
         * @return A list of wrapped picklist entries for states.
         */
        private static List<J_DependentClassBitSet.PicklistEntryWrapper> getDependentPicklistEntries() {
            Schema.DescribeFieldResult fieldResultState = User.statecode.getDescribe();
            return J_DependentClassBitSet.wrapPicklistEntries(fieldResultState.getPicklistValues());
        }

        /**
         * @description Extracts the controlling values (country codes) from the initialized map.
         * @param objResults The map of country results initialized for dependent picklist logic.
         * @return A list of controlling values (country codes).
         */
        private static List<String> getControllingValues(Map<String, List<String>> objResults) {
            return new List<String>(objResults.keySet());
        }

        /**
         * @description Determines whether the current state and country values match based on the picklist entry.
         * @param plew The wrapper for a picklist entry.
         * @param state The State values (code or description).
         * @param country The Country value (code or description).
         * @param controllingValues A list of controlling values (country codes).
         * @return True if the state and country match; otherwise, false.
         */
        private static Boolean isValidStateMatch(
            J_DependentClassBitSet.PicklistEntryWrapper plew,
            String state,
            String country,
            List<String> controllingValues
        ) {
            String validForBits = J_DependentClassBitSet.base64ToBits(plew.validFor);

            for (Integer i = 0; i < validForBits.length(); i++) {
                if (validForBits.mid(i, 1) == '1' && controllingValues.get(i) == country) {
                    return true;
                }
            }
            return false;
        }

        /**
         * @description Retrieves the appropriate state value (description or code) based on the matching picklist entry.
         * @param plew The wrapper for a picklist entry.
         * @param state The State value (code or description).
         * @return The converted State value: description if input is code, or code if input is description.
         */
        private static String getMatchingValue(
            J_DependentClassBitSet.PicklistEntryWrapper plew,
            String state
        ) {
            if (state.length() == 2 && plew.value == state) {
                return plew.label; // Return state description
            } else if (plew.label == state) {
                return plew.value; // Return state code
            }
            return null;
        }


    

}