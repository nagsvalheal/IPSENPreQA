/**********************************************************************************************
* @Author:         
* @description This is a Generic class to be used for enabling debug logs and Exception Logs
* User Story:       
***********************************************************************************************/
public without sharing class GenericLogger {    
/**
 * @description Method to write passed in message into debug log if debug logs are enabled.
   @param message The message that need to be logged into debug log.
 */
    public static void debugLog(String message){
        if(isLogEnabled()){
          System.debug( J_ObjectUtils.GENERIC_LOG_MESSAGE + message);  // NOPMD
        } 
    }
    
    /**********************************************************************************************
    * @Author:         
    * @description Method to write passed in exception and call writeDebug with formed string.
        DO NOT Check the logEnabled as exception had to be written at Debug Log.
    @param ex The exception that need to be logged into debug log.
    ***********************************************************************************************/
    public static void exceptionLog(Exception ex){
        string errorMessage =  J_ObjectUtils.GENERIC_LOG_MESSAGE 
                            +  J_ObjectUtils.MESSAGE_AT 
                            + ex.getLineNumber() 
                            +  J_ObjectUtils.MESSAGE_DOUBLE_COLON 
                            + ex.getMessage();
        debugLog (errorMessage);	
    }
    
    /**********************************************************************************************
    * @Author:          
    * @description Method to write passed in exception and call writeDebug with formed string.
    @param className The name of the class where the exception occurred.
    @param methodName The name of the method where the exception occurred.
    @param ex The exception that need to be logged into debug log.
    ***********************************************************************************************/
   public static void exceptionLog(string className, string methodName, Exception ex){ // NOPMD
	    if(isExceptionEnabled()){
	     	try{
                // Extract relevant information from the exception
                String exceptionMessage = ex.getMessage();
                String exceptionStackTrace = ex.getStackTraceString();
                Integer exceptionLineNumber = ex.getLineNumber();
                
                // Call the future method for logging the exception asynchronously
                GenericLogProvider.insertExceptionAtLogObject(
                    className, 
                    methodName, 
                    exceptionMessage, 
                    exceptionStackTrace, 
                    exceptionLineNumber
                );
                if(Test.isRunningTest())
                    {
                        throw new DMLException();
                    }
                }
		    catch(Exception exObj){
		          exceptionLog(ex);
                  exceptionLog(exObj);
		    } 	
	    }else{
             exceptionLog(ex);
        }                              
   }
    
    /**********************************************************************************************
    * @Author:        
    * @description Generic method to check debug log enablement. DEFAULT = [TRUE]
    @return Boolean
    ***********************************************************************************************/
    public static boolean isLogEnabled(){
    	List<General_Settings__mdt> currentEnvironmentSettings = 
                                            GenericLogProvider.getCurrentEnvironmentSettings();
        if(!currentEnvironmentSettings.isEmpty()){
            return currentEnvironmentSettings[0].DebugLogsRequired__c;
        }
        else{
            return true;
        }
    }

    /**********************************************************************************************
    * @Author:        
    * @description Generic method to check debug log enablement. DEFAULT = [TRUE]
    @return Boolean
    ***********************************************************************************************/
    public static boolean isExceptionEnabled(){
    	List<General_Settings__mdt> currentEnvironmentSettings = 
                                            GenericLogProvider.getCurrentEnvironmentSettings();
        if(!currentEnvironmentSettings.isEmpty()){
            return currentEnvironmentSettings[0].ExceptionLogsRequired__c;
        }
        else{
            return false;
        }    
    }
}