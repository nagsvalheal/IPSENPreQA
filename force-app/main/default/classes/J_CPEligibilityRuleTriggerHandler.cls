/**
 * @class J_CPEligibilityRuleTriggerHandler
 * @description Handles trigger-related logic for the CareProgramEligibilityRule object, including
 *              enforcing profile-based restrictions on record deletion.
 * @visibility public without sharing
 */
public without sharing class J_CPEligibilityRuleTriggerHandler {
    /**
 * @description Ensures that only users with the 'System Administrator' profile can delete records 
 *              of the CareProgramEligibilityRule object. If the user does not have the required profile, 
 *              an error is added to the record to prevent deletion.
 *
 * @param cpEligRuleList List of CareProgramEligibilityRule records that are being deleted.
 *
 * @throws DmlException if an error occurs during the deletion process or if the user's profile
 *                      does not allow deletion of the records.
 */
    public void beforeDeleteMethod(List<CareProgramEligibilityRule> cpEligRuleList){  
        string sobjectType ='profile';
        string fields ='Id, Name';
        String conditions = 'Id = \'' + UserInfo.getProfileId() + '\'';
        Boolean withUserMode = true;
        List<SObject> profiles = COM_QueryUtility.executeQuery(
        sObjectType,
        fields,
        conditions,
        withUserMode
    );
    if (!profiles.isEmpty()) {
        Profile usrProfile = (Profile) profiles[0];
        for (CareProgramEligibilityRule cpEligRule : cpEligRuleList) {  
            if (usrProfile.Name != 'System Administrator') {
                cpEligRule.addError('You are not allowed to delete the Care Program Eligibility Rule');
            }            
        }
    }
    }

    /**
 * @description Processes a list of CareProgramEligibilityRule records after insert. The method groups the records
 *              by their associated CareProgramId and prepares them for sharing by invoking the TeamSharing_HelperClass.
 *
 * @param cpEligRuleList List of CareProgramEligibilityRule records that were inserted.
 */
    
    public void afterInsertMethod(List<CareProgramEligibilityRule> cpEligRuleList){
        map<string,map<string,string>> mpEligRuleDetails = new map<string,map<string,string>>();
        map<string,string> ruleDetails = new map<string,string>();
        for(CareProgramEligibilityRule cpEligRule:cpEligRuleList){
            ruleDetails = new map<string,string>();
            if(mpEligRuleDetails.containskey(cpEligRule.CareProgramId)){
                ruleDetails=mpEligRuleDetails.get(cpEligRule.CareProgramId);
            }            
            ruleDetails.put(cpEligRule.Id,cpEligRule.OwnerId);
            mpEligRuleDetails.put(cpEligRule.CareProgramId,ruleDetails);
        }
        TeamSharing_HelperClass.insertShareRecords('CareProgramEligibilityRule','CareProgramEligibilityRuleShare',mpEligRuleDetails);    
    }
    /**
 * @description Handles post-deletion logic for CareProgramEligibilityRule records, including dynamic query execution.
 *              Deletes sharing records associated with the deleted rules using the TeamSharing_HelperClass.
 *
 * @param cpEligRuleList List of CareProgramEligibilityRule records that were deleted.
 */
    public void afterDeleteMethod(List<CareProgramEligibilityRule> cpEligRuleList){ 
        set<string> lstDeRecords = new set<String>(); 
        for(CareProgramEligibilityRule cpEligRule:cpEligRuleList){
            lstDeRecords.add(cpEligRule.Id);
        }
        if(lstDeRecords!=null && lstDeRecords.size()>0){
            TeamSharing_HelperClass.DeleteSharingRecords('CareProgramEligibilityRuleShare',lstDeRecords);
        }
    }
}