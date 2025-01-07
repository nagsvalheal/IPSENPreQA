/**********************************************************************************************
 * @Author:
 * @description Used for Database and custom metadata interaction for Generic Log and Exception.
 * User Story:       CCM-576
 ***********************************************************************************************/
public without sharing class GenericLogProvider {
    /**********************************************************************************************
    * @Author:        
    * @description Generic method to check debug log enablement. DEFAULT = [TRUE]
    @return Boolean
    ***********************************************************************************************/
    public static List<General_Settings__mdt> getCurrentEnvironmentSettings() {
        List<General_Settings__mdt> lstValues = new List<General_Settings__mdt>();
        map<string,General_Settings__mdt> mapGeneralSetting = General_Settings__mdt.getAll();
        for(string settingName:mapGeneralSetting.keySet()){
            lstValues.add(mapGeneralSetting.get(settingName));
        }
        return lstValues;
    }
    /**********************************************************************************************
    * @Author:        
    * @description Add the exception details at designated exception log object 
     @param className The name of the class where the exception occurred.
    @param methodName The name of the method where the exception occurred.
    @param exceptionMessage The exception message.
    @param exceptionStackTrace The exception stack trace.
    @param exceptionLineNumber The exception line number.
    **********************************************************************************************/
    @future
    public static void insertExceptionAtLogObject(
        String className,
        String methodName,
        String exceptionMessage,
        String exceptionStackTrace,
        Integer exceptionLineNumber
    ) {
        try {
            Exception_Log__c exceptionLogObj = new Exception_Log__c();
            exceptionLogObj.Source__c = className;
            exceptionLogObj.SourceFunction__c = methodName;
            exceptionLogObj.StackTrace__c = exceptionStackTrace;
            exceptionLogObj.LineNumber__c = exceptionLineNumber;
            exceptionLogObj.Message__c = exceptionMessage != null &&
                exceptionMessage.length() > 254
                ? exceptionMessage.substring(0, 254)
                : exceptionMessage;

            // Add the record to a list and insert it
            List<Exception_Log__c> exceptionLogList = new List<Exception_Log__c>();
            exceptionLogList.add(exceptionLogObj);
            COM_DatabaseOperationsUtility.insertOperation(exceptionLogList, GenericLogger.class.toString(), false);
        } catch (Exception ex) {
            GenericLogger.exceptionLog('GenericLogProvider','insertExceptionAtLogObject',  ex);
        }
    }

        /**
     * @description Logs a success message for a batch class execution.
     * 
     * @param sourceClass The name of the source class where the log is generated.
     * @param sourceFunction The function or method name where the log is generated.
     * @param message The log message to insert.
     */
    public static void logBatchExecutionSuccess(String sourceClass, String sourceFunction, String message) {
        try{
            // Create an Exception_Log__c object
            Exception_Log__c exceptionLogObj = new Exception_Log__c(
                Source__c = sourceClass,
                SourceFunction__c = sourceFunction,
                Message__c = message
            );

            // Add the record to a list and insert it
            List<Exception_Log__c> exceptionLogList = new List<Exception_Log__c>();
            exceptionLogList.add(exceptionLogObj);
            
            // Use the utility class to perform the insert operation
            COM_DatabaseOperationsUtility.insertOperation(exceptionLogList, sourceClass, false);
        }
        catch(Exception e){
            // Log any errors to the debug log
            GenericLogger.exceptionLog('GenericLogProvider','logBatchExecutionSuccess',  e);
        }
    }
}