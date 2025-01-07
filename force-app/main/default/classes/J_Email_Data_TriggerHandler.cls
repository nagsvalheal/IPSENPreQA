/**
 *  @description    This is a trigger handler class for the Email_Data__c object to handle after insert and delete operations.
 *  @author         Vijay
 *  @date           03-12-2024
 */
public without sharing class J_Email_Data_TriggerHandler {
    /**
     * @description    Handles the after insert trigger event for the Email_Data__c object.
     *                 This method groups email records by the Care_Program__c field and passes the details to a helper class for sharing record insertion.
     * @param emailDataList  List of Email_Data__c records that were inserted.
     */
	public void afterInsertMethod(List<Email_Data__c> emailDataList){
        try {
        map<string,map<string,string>> mpEmailDataDetails = new map<string,map<string,string>>();
        map<string,string> emailDetails = new map<string,string>();
        for(Email_Data__c emailData:emailDataList){
            emailDetails = new map<string,string>();
            if(mpEmailDataDetails.containskey(emailData.Care_Program__c)){
                emailDetails=mpEmailDataDetails.get(emailData.Care_Program__c);
            }            
            emailDetails.put(emailData.Id,emailData.OwnerId);
            mpEmailDataDetails.put(emailData.Care_Program__c,emailDetails);
        }
        ShareRecordInsertion_HelperClass.insertShareRecord('Email_Data__c','Email_Data__Share',mpEmailDataDetails);
    }catch (Exception ex) {
            GenericLogger.exceptionLog('J_Email_Data_TriggerHandler', 'afterInsertMethod', ex);
        }
}
    /**
     * @description    Handles the after delete trigger event for the Email_Data__c object.
     *                 This method collects the IDs of deleted email records and passes them to a helper class for sharing record deletion.
     * @param emailDataList  List of Email_Data__c records that were deleted.
     */
    public void afterDeleteMethod(List<Email_Data__c> emailDataList){ 
       try {
        set<string> lstDeRecords = new set<String>(); 
        for(Email_Data__c emailData:emailDataList){
            lstDeRecords.add(emailData.Id);
        }
        if(lstDeRecords!=null && lstDeRecords.size()>0){
            TeamSharing_HelperClass.deleteSharingRecords('Email_Data__Share',lstDeRecords);
        }
       }catch (Exception ex) {
            GenericLogger.exceptionLog('J_Email_Data_TriggerHandler', 'afterDeleteMethod', ex);
        }
  }
}