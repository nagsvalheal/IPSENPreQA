public class NAFTriggerHandler {
    
	public NAFTriggerHandler(){
        
    }
    
    public void beforeDeleteMethod(List<J_NAF__c> lstNAF){  
        Id profileId = System.UserInfo.getProfileId();
        Profile profileInfo = [SELECT Id, Name FROM Profile WHERE Id = :profileId];   
        if(profileInfo.Name != 'System Administrator'){
            for(J_NAF__c naf:lstNAF){ 
                naf.addError('You are not allowed to delete the NAF record');            
            }
        }        
    }
}