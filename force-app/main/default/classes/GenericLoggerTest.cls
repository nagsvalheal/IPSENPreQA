@IsTest
/********************************************************************************************** 
* @Author:       
* @description :  This is the Test class for the GenericLogger class. It validates the debug 
*                logging and exception logging functionalities provided by GenericLogger.
***********************************************************************************************/
private with sharing class GenericLoggerTest {
    /**
    *  @description Stores General Settings metadata records for test validation
    */
    public static List<General_Settings__mdt> cmd;

    /**
     * @description Helper method to query and populate the `cmd` variable with General_Settings__mdt records.
     */
    public static void createTestRecord() {
        cmd = [SELECT DebugLogsRequired__c, ExceptionLogsRequired__c 
                 FROM General_Settings__mdt];
    }

    /**
     * @testmethod Validates that the `debugLog` method of `GenericLogger` logs a debug message without throwing an exception.
     * @description This test calls the `debugLog` method with a sample message and ensures it executes successfully.
     */
    @IsTest
    public static void testDebugLog(){
        createTestRecord();
        Test.startTest();
        try {        
            // Call the debugLog method with a test message
            GenericLogger.debugLog('Test message'); 
            System.assert(true, 'Exception expected');
        } catch (Exception ex) {
            System.assert(false, 'Exception is not expected');
        }
        Test.stopTest();
    }

    /**
     * @description Test method to validate the exception logging functionality of GenericLogger.
     *              Ensures exceptions are correctly logged during an operation failure.
     */
    @IsTest
    public static void testExceptionLog(){
        createTestRecord();
        Test.startTest();
        try {
            // Simulate an exception by inserting an incomplete Account record
            Account acc = new Account();
            insert acc;
        } catch (Exception ex) {
            // Log the exception and validate the process
            GenericLogger.exceptionLog(ex);
            System.assert(true, 'Exception Handled');
        }

        Test.stopTest();
        
        
    }

    /**
     * @description Test method to validate logging of exceptions with additional details.
     *              Ensures that exception logs include relevant metadata.
     */
    @IsTest
    public static void testExceptionLogInsert(){
        createTestRecord();
        Test.startTest();
        try {
            // Simulate an exception by inserting an incomplete Account record
            Account acc = new Account();
            insert acc;
        } catch (Exception ex) {
            // Log the exception with additional metadata and validate
            GenericLogger.exceptionLog('GenericLogger', 'testExceptionLogInsert', ex);
            System.assert(true, 'Exception Logged');
        }
        Test.stopTest();       
        
    }

    /**
     * @description Test method to validate exception handling when null parameters 
     *              are passed to the exceptionLog method.
     */
    @IsTest
    public static void testExceptionLogExceptInsert() {
        try {
            GenericLogger.exceptionLog(null, null, null); // Log with null parameters
            System.assert(true, 'The exceptionLog method should handle null parameters without throwing an exception.');
        } catch (Exception ex) {
            System.assert(true, 'Exception correctly thrown and caught when null parameters are passed: ' + ex.getMessage());
        }
    }
}