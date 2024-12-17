/**
*   @author         Arkadii Sychov
*   @date           09/25/20
*   @description    The class comtains common methods and constants for work with objects 
*       IPSC-73
**/
public without sharing class J_ObjectUtils {
    //
    public static final String GENERIC_LOG_MESSAGE = '***EXCEPTION Logger*** ';
    public static final String MESSAGE_AT = 'at ';
    public static final String MESSAGE_DOUBLE_COLON = ' :: ';
	public static final string LEAD_PATIENT_RECORD_TYPE = 'Patients_Caregivers';
    public static final string LEAD_HCF_RECORD_TYPE = 'Healthcare_Providers';
    public static final String PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME = 'J_Journeys_Patient';
    public static final String PERSON_ACCOUNT_RT_JOURNEYS_CAREGIVER_NAME = 'J_Journeys_Caregiver';
    public static final String ACCOUNT_API_NAME = 'Account';
    public static final String ACCOUNT_FIELD_API_NAME_CC_TERRITORY = 'J_CCTerritory__c';
    public static final String ACCOUNT_FIELD_API_NAME_PEL_TERRITORY = 'J_PELTerritory__c';
    public static final String SEND_MESSAGE_OBJECT_API_NAME_PEL_TERRITORY = 'J_Send_Message__c';
    

    public static final String ACCOUNT_PRIMARY_ADDRESS_PL_VALUE_MAILING = 'Mailing';
    public static final String ACCOUNT_PRIMARY_ADDRESS_PL_VALUE_OTHER = 'Other';
    public static final String ACCOUNT_PATIENT_STATUS_PL_INACTIVE = 'Inactive';
    public static final String ACCOUNT_PATIENT_STATUS_PL_ACTIVE = 'Active';
    public static final String ACCOUNT_HOME_WORK_MOBILE_PL_HOME = 'Home';
    public static final String ACCOUNT_PATIENT_AMBASSADOR_STATUS_PL_ACTIVE = 'Active';

    public static final String CONSENT_CONSENT_STATUS_PL_EXPIRING = 'Expiring';
    public static final String CONSENT_CONSENT_STATUS_PL_ACTIVE = 'Active';
    public static final String CONSENT_CONSENT_STATUS_PL_EXPIRED = 'Expired';

    public static final String TASK_API_NAME = 'Task';
    public static final String TASK_RT_CARE_PLAN_TASK = 'CarePlanTask';
    public static final String TASK_PRIORITY_PL_NORMAL = 'Normal';
    public static final String TASK_STATUS_PL_OPEN = 'Scheduled';
    public static final String TASK_STATUS_PL_SUBMITTED = 'Submitted';
    public static final String TASK_STATUS_PL_CANCELLED = 'Cancelled';
    public static final String TASK_SUBJECT_PL_CONSENT_EXPIRING = 'Consent Expiring';
    public static final String TASK_SUBJECT_PL_EXPIRATION = 'Expiration';
    public static final String TASK_SUBJECT_PL_SUPPLY_ISSUE = 'Supply Issue';
    public static final String TASK_SUBJECT_PL_HCP_ISSUE = 'HCP Issue';
    public static final String TASK_SUBJECT_PL_NEW_PHYSICIAN = 'New Physician';
    public static final String TASK_SUBJECT_PL_PATIENT_INTERACTION = 'Patient Interaction';
    public static final String TASK_SUBJECT_PL_INSURANCE = 'Insurance';
    public static final String TASK_SUBJECT_CUSTOM_CONTRACT_EXPIRATION = 'Contract Expiration';
    public static final String TASK_SUBJECT_CUSTOM_PEL_WELCOME_CALL = 'PEL Welcome Call';

    public static final String EVENT_API_NAME = 'Event';
    public static final String EVENT_RT_JOURNEYS_EVENT = 'JourneysEvent';
    public static final String EVENT_ACTIVITY_STATUS_PL_SUBMITTED = 'Submitted';
    public static final String EVENT_ACTIVITY_STATUS_PL_CANCELLED = 'Cancelled';

    public static final String ACTIVITY_INTERACTION_DETAILS_API_NAME = 'J_InteractionDetails__c';
    public static final String USER_API_NAME = 'User';

    public static final String INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP = 'Follow-Up';
    public static final String INTERACTION_DETAILS_SUB_TYPE_PL_TEXT = 'Text';
    public static final String INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_SUPPLY_ISSUE = 'Supply Issue';
    public static final String INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_HCP_ISSUE = 'HCP issue';
    public static final String INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_NEW_PHYSICIAN = 'New physician';
    public static final String INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_INSURANCE = 'Insurance';
    public static final String INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_DISEASE_EDUCATION = 'Disease Education';
    public static final String INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_SAFETY_PROTOCOL_REVIEW = 'Safety Protocol Review';
    public static final String INTERACTION_DETAILS_SUBJECT_PL_PATIENT_INTERACTION = 'Patient Interaction';
    public static final String INTERACTION_DETAILS_RECORD_TYPE_NAME_J_PEL_INTERACTIONS = 'J_PELInteractions';
    public static final String INTERACTION_DETAILS_RECORD_TYPE_NAME_J_PATIENT_MEETING_EVENT_DETAILS = 'J_PatientMeetingEventDetails';

    public static final String CHARITABLE_CHARITABLE_STATUS_PL_ACTIVE = 'Active';
    public static final String CHARITABLE_CHARITABLE_STATUS_PL_IN_PROCESS = 'In Process';
    public static final String CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP = 'PAP';
    public static final String CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_TPAP = 'TPAP';

    public static final String COPAY_CURRENT_COPAY_STATUS_PL_ACTIVE = 'Active';
    public static final String COPAY_CURRENT_COPAY_STATUS_PL_INACTIVE = 'Inactive';

    public static final String COVERAGE_BENEFIT_COVERAGE_BENEFIT_STATUS_PL_ACTIVE = 'Active';

    public static final String PROFILE_NAME_STANDARD_JOURNEYS_USER = 'Standard Journeys User';
    public static final String PERMISSION_SET_GROUP_API_NAME_CC = 'J_Care_Coordinator_Permissions_Group';
    public static final String PERMISSION_SET_GROUP_API_NAME_PEL = 'J_PEL_Permissions_Group';
    public static final String ROLE_NAME_PEL_USER = 'Patient_Education_Liaison';
    public static final String ROLE_NAME_CC_USER = 'Care_Coordinator';
    public static final String ROLE_NAME_JM_USER ='Journeys_Manager';

    public static final String SEND_MESSAGE_SENDER_RECORDTYPE = 'J_Send_Messages';
    public static final String SEND_MESSAGE_RECEIVER_RECORDTYPE = 'J_Received_Messages';
    
    public static final String CASE_API_NAME = 'Case';
    public static final String CASE_RT_CARE_PLANTASK = 'CarePlan';

    public static final String CC = 'CC';
    public static final String PEL = 'PEL';

    public static final Map<String, String> INTERACTION_DETAILS_DISCUSSION_TOPIC_TO_TASK_SUBJECT_MAPPING = new Map<String, String>{
        INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_SUPPLY_ISSUE    => TASK_SUBJECT_PL_SUPPLY_ISSUE,
        INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_HCP_ISSUE       => TASK_SUBJECT_PL_HCP_ISSUE,
        INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_NEW_PHYSICIAN   => TASK_SUBJECT_PL_NEW_PHYSICIAN,
        INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_INSURANCE       => TASK_SUBJECT_PL_INSURANCE
    };
    public static Map<String, Id> mapRecordTypes = new Map<String, Id>();

    //Sets to true in J_ContentVersion_INSERTTest to ignore Test.isRunningTest() method in J_ContentVersion_INSERT Trigger
    public static Boolean ignoreIsRunningTestInContentVersionTrigger = false;
    public static Boolean ignoreAccessCheck = false;
    public static set<string> pelObjectExcludes= new set<string>{'User','J_PAContract__c','J_NAF__c','J_PatientAmbassadorNAF__c','J_Consent__c','Event','Case','J_Send_Message__c','CarePreauth','CoverageBenefit'}; // NOPMD
    public static final String INTERACTION_DETAILS_RECORD_TYPE_NAME_PATIENT_AMBASSADOR_EVENT = 'J_PatientAmbassadorEvent';     

    /**
     *  @description Returns Id of Accont/PersonAccount record type, depending on isPersonType 
     *  IPSC-73
     *  @param  recordTypeDevName   developer name of the requested record type
     *  @param  isPersonType        marker shows where to search the rt - Account or PersonAccount
     *  @return Id of the requested record type
     */

    
    public static Id getAccountRecordTypeId(String recordTypeDevName, Boolean isPersonType) {  
        if (String.isBlank(recordTypeDevName) || isPersonType == null) {
            return null;
        }
        
        List<RecordType> accRecTyId = [
            SELECT Id 
            FROM RecordType 
            WHERE SobjectType = :ACCOUNT_API_NAME 
                AND IsPersonType = : isPersonType
                AND DeveloperName = : recordTypeDevName
                WITH USER_MODE
        ];
        if (!accRecTyId.isEmpty()) {
            return accRecTyId[0].Id;
        }
        return null;
   }  
     /**
        * @description Retrieves the Record Type Id for a given object and record type developer name.
        * @param sObjectType The API name of the SObject type (e.g., 'Contact').
        * @param developerName The Developer Name of the record type (e.g., 'Physician').
        * @return The Record Type Id as an Id.
        */
        public static Id getRecordTypeId(String developerName, String sObjectType) {
            String recordTypeCombination = sObjectType + '_' + developerName;
        
            // Check if RecordTypeId is already cached
            if (mapRecordTypes.containsKey(recordTypeCombination)) {
                return mapRecordTypes.get(recordTypeCombination);
            } else {
                // Retrieve and cache the Record Type Id
                try {
                    // Get Describe information for the object
                    Map<String, Schema.RecordTypeInfo> recordTypeInfoMap = 
                        Schema.getGlobalDescribe().get(sObjectType).getDescribe().getRecordTypeInfosByDeveloperName();
                    
                    // Validate and fetch RecordTypeId
                    if (recordTypeInfoMap.containsKey(developerName)) {
                        Id recordTypeId = recordTypeInfoMap.get(developerName).getRecordTypeId();
                        mapRecordTypes.put(recordTypeCombination, recordTypeId);
                        return recordTypeId;
                    } else {
                        throw new IllegalArgumentException('Record Type not found: ' + developerName);
                    }
                } catch (Exception ex) {
                    // Log or rethrow as needed
                    throw new IllegalArgumentException('Error retrieving Record Type Id: ' + ex.getMessage(), ex);
                }
            }
        }



      /**
     *  @description Returns Id of the profile
     *  @param  profileName   developer name of the requested profile
     *  @return Id of the requested profile
     */
    public static String getProfileIdByName(String profileName) {
        if (String.isBlank(profileName)) {
            return null;
        }
        String sObjectType = 'Profile';
        String fields = 'Id, Name';
        String conditions = 'Name = \'' + profileName + '\'';

        List<Profile> proRecTyId = COM_QueryUtility.executeQuery(sObjectType,fields,conditions,false);


        if (!proRecTyId.isEmpty()) {
            return proRecTyId[0].Id;
        }
        return null;
    }

}