public class PAContractTriggerHandler {
    
	public PAContractTriggerHandler(){
        
    }
    
    public void beforeDeleteMethod(List<J_PAContract__c> lstPACont){  
        Id profileId = System.UserInfo.getProfileId();
        Profile profileInfo = [SELECT Id, Name FROM Profile WHERE Id = :profileId];   
        if(profileInfo.Name != 'System Administrator'){
            for(J_PAContract__c paContnaf:lstPACont){ 
                paContnaf.addError('You are not allowed to delete the Patient Ambassador Contract record');            
            }
        }        
    }
}