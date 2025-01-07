/**
 * @description This class provides utility methods for handling base64 encoding, 
 * conversion between binary and decimal representations, and wrapping picklist entries 
 * for easier processing within Salesforce.
 */
public class J_DependentClassBitSet {

    /**
     * @description This constant holds the base64 characters, including uppercase letters, 
     * lowercase letters, digits, and the '+' and '/' characters, as defined in base64 encoding.
     */
    public static final String BASE64_CHARS = '' +
            'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
            'abcdefghijklmnopqrstuvwxyz' +
            '0123456789+/';

    /**
     * @description Wrapper class for picklist entries, used to represent the structure of a picklist entry.
     * This class includes fields for active status, default value, label, value, and validFor.
     */
    public class PicklistEntryWrapper {
        /**
         * @description The active status of the picklist entry.
         */
        public String active {get; set;}      

        /**
         * @description The default value for the picklist entry.
         */
        public String defaultValue {get; set;} 

        /**
         * @description The label for the picklist entry.
         */
        public String label {get; set;}        

        /**
         * @description The value of the picklist entry.
         */
        public String value {get; set;}        

        /**
         * @description The validFor value for the picklist entry.
         */
        public String validFor {get; set;}     
    }

    /**
     * @description Converts a list of PicklistEntry objects into a list of PicklistEntryWrapper objects. 
     * This method serializes the PicklistEntry objects into JSON and then deserializes them 
     * back into a list of wrapper objects.
     * 
     * @param plEs The list of PicklistEntry objects to be wrapped.
     * @return A list of PicklistEntryWrapper objects.
     */
    public static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> plEs) {
        return (List<PicklistEntryWrapper>)
            JSON.deserialize(JSON.serialize(plEs), List<PicklistEntryWrapper>.class);
    }

    /**
     * @description Converts a decimal integer to its binary string representation. The method repeatedly 
     * divides the number by 2, noting the remainders, and assembles the binary string in reverse order.
     * 
     * @param val The decimal integer to convert to binary.
     * @return A binary string representation of the integer.
     */
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }

    /**
     * @description Converts a base64-encoded string into a binary string representation. 
     * Each base64 character is mapped to a 6-bit binary representation, 
     * which are concatenated to form the full binary string.
     * 
     * @param validFor The base64-encoded string to convert to binary.
     * @return A binary string representation of the base64-encoded input.
     */
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) {
            return '';
        }

        String validForBits = '';

        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = BASE64_CHARS.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }

        return validForBits;
    }
}