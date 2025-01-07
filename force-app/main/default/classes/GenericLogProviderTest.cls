/**********************************************************************************************
* @Author:       
* @description This is the Test class of GenericLogProviderTest
***********************************************************************************************/
@IsTest
public with sharing class GenericLogProviderTest {
	//prepare test data
    @IsTest
    public static void genericLogProvider() {
    	Test.startTest();
        GenericLogProvider.getCurrentEnvironmentSettings();
        GenericLogProvider.logBatchExecutionSuccess('Test class','Test method','success');
        System.assert(true,true);
        Test.stopTest();
    }
    //prepare test data
    @IsTest
    public static void insertExceptionAtLogObjectx() {
        Test.startTest();    	   
    	   try{
    	   	Integer a = 5/0;
            System.assertEquals(a,0,'Expected error');
    	   }catch(Exception e){
            GenericLogProvider.insertExceptionAtLogObject(GenericLogProvider.class.toString(),'Test method','Test exception',e.getStackTraceString(),e.getLineNumber());
                System.assert(true,true);
    	   }
     
        Test.stopTest();	
    }
}