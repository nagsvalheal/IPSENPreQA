/**
 * This class contains methods to handle triggers for the CareProgramProduct object.
 * It includes logic to enforce security checks during deletion, manage sharing after insert, 
 * and clean up sharing records after deletion.
 * @description The class handles the deletion security checks for CareProgramProduct objects, 
 * creates and deletes sharing records based on the lifecycle events (insert and delete) of CareProgramProduct records.
 */
public without sharing class J_CareProgramProductTriggerHandler {
    /**
     * Before delete trigger handler for CareProgramProduct records.
     * Ensures that only users with the 'System Administrator' profile can delete CareProgramProduct records.
     *
     * @param cpProductList List of CareProgramProduct records to be deleted.
     * @description This method enforces the rule that only users with the 'System Administrator' 
     * profile are allowed to delete CareProgramProduct records. If the user does not have the required 
     * profile, an error is added to the record preventing deletion.
     */
	public void beforeDeleteMethod(List<CareProgramProduct> cpProductList){ 
        // Retrieve the current user's profile 
        Profile usrProfile=[select id,Name from Profile where id=:UserInfo.getProfileId() WITH SECURITY_ENFORCED];
        for(CareProgramProduct cpProd:cpProductList){  
            if(usrProfile.Name!='System Administrator'){
                cpProd.addError('You are not allowed to delete the Care Program Product');
            }            
        }        
    }
    
    /**
     * After insert trigger handler for CareProgramProduct records.
     * Creates sharing records for CareProgramProduct based on CareProgramId and OwnerId.
     *
     * @param cpProductList List of CareProgramProduct records that were inserted.
     * @description This method processes CareProgramProduct records after they are inserted, 
     * creating sharing records based on CareProgramId and OwnerId to ensure proper record access control.
     */
    public void afterInsertMethod(List<CareProgramProduct> cpProductList){
        map<string,map<string,string>> mpCPProductDetails = new map<string,map<string,string>>();
        map<string,string> prodDetails = new map<string,string>();
        for(CareProgramProduct cpProd:cpProductList){
            prodDetails = new map<string,string>();
            if(mpCPProductDetails.containskey(cpProd.CareProgramId)){
                prodDetails=mpCPProductDetails.get(cpProd.CareProgramId);
            }            
            prodDetails.put(cpProd.Id,cpProd.OwnerId);
            mpCPProductDetails.put(cpProd.CareProgramId,prodDetails);
        }
        ShareRecordInsertion_HelperClass.insertShareRecord('CareProgramProduct','CareProgramProductShare',mpCPProductDetails);
    }
    
    /**
     * After delete trigger handler for CareProgramProduct records.
     * Removes sharing records associated with deleted CareProgramProduct records.
     *
     * @param cpProductList List of CareProgramProduct records that were deleted.
     * @description This method deletes sharing records for CareProgramProduct that were deleted. 
     * It ensures that access control information is cleaned up when records are removed from the system.
     */
    public void afterDeleteMethod(List<CareProgramProduct> cpProductList){ 
        set<string> lstDeRecords = new set<String>(); 
        for(CareProgramProduct cpProd:cpProductList){
            lstDeRecords.add(cpProd.Id);
        }
        if(lstDeRecords!=null && lstDeRecords.size()>0){
            TeamSharing_HelperClass.deleteSharingRecords('CareProgramProductShare',lstDeRecords);
        }
    }
}