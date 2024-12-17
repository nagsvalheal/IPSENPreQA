/*************************************************************************************************
* description		This is a singleton class which has logic to get record from custom metadata.
**************************************************************************************************/

public with sharing class GenericMetadataProvider{ // NOPMD
    
	//private static variable referencing the class
    private static GenericMetadataProvider instance = null;
    /**********************************************************************************************
	* @Author:        
	* @description Static method that query General_Settings metadata.
    @return Returns the instance of the class.
	***********************************************************************************************/
    public static GenericMetadataProvider getInstance(){
        //only initialize if it doesn't already exist
        if(instance == null){
            instance = new GenericMetadataProvider();
        }
        return instance;
    }
    
    
    /**********************************************************************************************
	* @Author:        
	* @description Static method that query General_Settings metadata.
    @return Returns the instance of the class.
	***********************************************************************************************/
    public static Integer getRecordFromGeneralSetting(){
        return Integer.valueOf([SELECT ExceptionLogsPurgeDays__c FROM General_Settings__mdt LIMIT 1].ExceptionLogsPurgeDays__c);
    }
}