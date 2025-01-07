@IsTest
/** 
* @description       : This is a J_ObjectUtilsTest test class designed to test the functionality of the J_ObjectUtilsTest class,
* History:
* Version  Author      Date            Detail          Description
* 1.0      Harish     25-Nov-2024     Created         Initial development.
 */
private class J_ObjectUtilsTest {

    @IsTest
    static void testInvalidRecordType() {
        // Test handling of invalid Record Type
        try {
            J_ObjectUtils.getRecordTypeId('Account', 'InvalidRecordType');
            Assert.areEqual(false, 'Expected an exception for invalid Record Type',null);
        } catch (IllegalArgumentException e) {
            Assert.areEqual('Record Type not found: InvalidRecordType', e.getMessage(), 'Expected exception message for invalid Record Type');
        }
    }
    @IsTest
    static void testInvalidSObjectType() {
        // Test handling of invalid SObject type
        try {
            J_ObjectUtils.getRecordTypeId('InvalidObject', 'recordTypeId');
           Assert.areEqual(false, 'Expected an exception for invalid SObject type',null);
        } catch (IllegalArgumentException e) {
            Assert.areEqual('Invalid SObject type: InvalidObject', e.getMessage(), 'Expected exception message for invalid SObject type');
        }
    }
    @IsTest
    static void testRetrieveRecordTypeId() {
        // Test retrieval of Record Type Id
        String sObjectType = 'Account';
        String developerName = 'Patient';
        
        Id recordTypeId = J_ObjectUtils.getRecordTypeId(sObjectType, developerName);
        
        Assert.areNotEqual(null, recordTypeId, 'Record Type Id should not be null');
    }

    @IsTest
    static void testAccountRecordType() {
        // Test handling of invalid Record Type
        try {
            Id recordTypeId = J_ObjectUtils.getAccountRecordTypeId('TestRecordType', true);
            Assert.areEqual(null, recordTypeId, 'Expected a valid Record Type Id');
        } catch (IllegalArgumentException e) {
            Assert.areEqual('Record Type not found: InvalidRecordType', e.getMessage(), 'Expected exception message for invalid Record Type');
        }
    }

    @IsTest
    static void testgetProfileId() {
        // Test handling of invalid Record Type
        try {
            String recordName = J_ObjectUtils.getProfileIdByName('System Administrator');
            System.assertNotEquals(null, recordName, 'Expected a valid profile Id for "System Administrator".');
        } catch (IllegalArgumentException e) {
            Assert.areEqual('Record Type not found: InvalidRecordType', e.getMessage(), 'Expected exception message for invalid Record Type');
        }
    }

}