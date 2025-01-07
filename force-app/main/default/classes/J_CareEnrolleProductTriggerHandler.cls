/**
 * Trigger handler for the CareProgramEnrolleeProduct object.
 * 
 * This class contains the logic for handling the before delete, after insert, and after delete operations
 * for CareProgramEnrolleeProduct records. It includes permission checks and sharing rule updates.
 * @description This class handles operations related to CareProgramEnrolleeProduct, including permission checks
 * before deletion, sharing rule updates after insertion, and the removal of sharing records after deletion.
 * @author Mickram
 * @version 1.0
 * @since 27/11/2024
 */
public without sharing class J_CareEnrolleProductTriggerHandler {
    
    /**
     * This method is triggered before the deletion of CareProgramEnrolleeProduct records.
     * It checks the profile of the current user and adds an error if the user is not a System Administrator.
     * 
     * @param enrolleproductList List of CareProgramEnrolleeProduct records to be deleted.
     * @description This method ensures that only users with the "System Administrator" profile can delete
     * CareProgramEnrolleeProduct records. Other users are restricted from deletion.
     */
     public void beforeDeleteMethod(List<CareProgramEnrolleeProduct> enrolleproductList) { 
         
         try {
    // Define the fields to be selected
    String fields = 'Id, Name';
    
    // Define the conditions for the WHERE clause (Profile of the current user)
    String conditions = 'Id = \'' + UserInfo.getProfileId() + '\'';
    
    // Call COM_QueryUtility to execute the query
    List<SObject> profileResults = COM_QueryUtility.executeQuery('Profile', fields, conditions, true);
    
    // Check if the profile results are returned and process them
    if (profileResults != null && !profileResults.isEmpty()) {
        String profileName = (String)profileResults[0].get('Name');  // Get the Profile Name

        // Iterate over the CareProgramEnrolleeProduct records and add error if needed
        for (CareProgramEnrolleeProduct cs : enrolleproductList) {  
            if (profileName != 'System Administrator') {
                cs.addError('You do not have permission to delete this record');
            }
        }   
    }
         }
         catch (DMLException e) {
            GenericLogger.exceptionLog('J_CareEnrolleProductTriggerHandler', 'beforeDeleteMethod', e);
        }
}

    
    /**
     * This method is triggered after the insertion of CareProgramEnrolleeProduct records.
     * It retrieves the relevant records and inserts the share records for the CareProgramEnrolleeProduct.
     * 
     * @param enrolleproductList List of newly inserted CareProgramEnrolleeProduct records.
     * @description After new records are inserted, this method handles inserting share records for the
     * CareProgramEnrolleeProduct records, linking them to the correct CareProgram.
     */
    public void afterInsertMethod(List<CareProgramEnrolleeProduct> enrolleproductList){
        set<string> lstcpEnrProdIds = new set<string>();        
        for(CareProgramEnrolleeProduct cpEnrProd:enrolleproductList){
            lstcpEnrProdIds.add(cpEnrProd.Id);
        }        
        List<CareProgramEnrolleeProduct> newEnrolleproductList = [select Id,OwnerId,CareProgramEnrollee.CareProgramId from CareProgramEnrolleeProduct where id in:lstcpEnrProdIds WITH SECURITY_ENFORCED];
        if(newEnrolleproductList!=null && newEnrolleproductList.size()>0){
            map<string,map<string,string>> mpEnrolleProductDetails = new map<string,map<string,string>>();
       		map<string,string> enrDetails = new map<string,string>();
            for(CareProgramEnrolleeProduct cpEnrProd1:newEnrolleproductList){               
                enrDetails = new map<string,string>();
                if(mpEnrolleProductDetails.containskey(cpEnrProd1.CareProgramEnrollee.CareProgramId)){
                    enrDetails=mpEnrolleProductDetails.get(cpEnrProd1.CareProgramEnrollee.CareProgramId);
                }            
                enrDetails.put(cpEnrProd1.Id,cpEnrProd1.OwnerId);
                mpEnrolleProductDetails.put(cpEnrProd1.CareProgramEnrollee.CareProgramId,enrDetails);
            }
            ShareRecordInsertion_HelperClass.insertShareRecord('CareProgramEnrolleeProduct','CareProgramEnrolleeProductShare',mpEnrolleProductDetails);        
        }        
    }
    
    /**
     * This method is triggered after the deletion of CareProgramEnrolleeProduct records.
     * It deletes the share records associated with the deleted CareProgramEnrolleeProduct records.
     * 
     * @param enrolleproductList List of CareProgramEnrolleeProduct records to be deleted.
     * @description After records are deleted, this method removes the associated sharing records to ensure
     * that no orphan sharing records remain.
     */
    public void afterDeleteMethod(List<CareProgramEnrolleeProduct> enrolleproductList){ 
        set<string> lstDeRecords = new set<String>(); 
        for(CareProgramEnrolleeProduct cpEnroll:enrolleproductList){
            lstDeRecords.add(cpEnroll.Id);
        }
        if(lstDeRecords!=null && lstDeRecords.size()>0){
            TeamSharing_HelperClass.deleteSharingRecords('CareProgramEnrolleeProductShare',lstDeRecords);
        }
    }

}