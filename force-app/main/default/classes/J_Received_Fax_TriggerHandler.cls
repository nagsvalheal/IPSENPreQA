/**
 *  @description    This is a trigger handler class for the Received_Fax__c object to manage sharing functionality during after insert and delete events.
 *  @author         Vijay
 *  @date           03-12-2024
 */
public without sharing class J_Received_Fax_TriggerHandler{
    /**
     * @description    Handles the after insert trigger event for the Received_Fax__c object.
     *                 This method groups received fax records by the Care_Program_Id__c field and passes the details to a helper class for sharing record insertion.
     * @param lstRecvdFax  List of Received_Fax__c records that were inserted.
     */
    
	public void afterInsertMethod(List<Received_Fax__c> lstRecvdFax){
        try {
        map<string,map<string,string>> mpRecvdFaxDetails = new map<string,map<string,string>>();
        map<string,string> faxDetails = new map<string,string>();
        for(Received_Fax__c rFax:lstRecvdFax){
            faxDetails = new map<string,string>();
            if(mpRecvdFaxDetails.containskey(rFax.Care_Program_Id__c)){
                faxDetails=mpRecvdFaxDetails.get(rFax.Care_Program_Id__c);
            }            
            faxDetails.put(rFax.Id,rFax.OwnerId);
            mpRecvdFaxDetails.put(rFax.Care_Program_Id__c,faxDetails);
        }        
        ShareRecordInsertion_HelperClass.insertShareRecord('Received_Fax__c','Received_Fax__Share',mpRecvdFaxDetails);
    }catch (Exception ex) {
        GenericLogger.exceptionLog('J_Received_Fax_TriggerHandler', 'afterInsertMethod', ex);
    }
    }
   /**
     * @description    Handles the after delete trigger event for the Received_Fax__c object.
     *                 This method collects the IDs of deleted fax records and passes them to a helper class for sharing record deletion.
     * @param lstRecvdFax  List of Received_Fax__c records that were deleted.
     */ 
    public void afterDeleteMethod(List<Received_Fax__c> lstRecvdFax){ 
        try {
        set<string> lstDelRecords = new set<String>(); 
        for(Received_Fax__c rFax:lstRecvdFax){
            lstDelRecords.add(rFax.Id);
         }
        if(lstDelRecords!=null && lstDelRecords.size()>0){
            TeamSharing_HelperClass.deleteSharingRecords('Received_Fax__Share',lstDelRecords);
         }
        }catch (Exception ex) {
            GenericLogger.exceptionLog('J_Received_Fax_TriggerHandler', 'afterDeleteMethod', ex);
        }
    }
}