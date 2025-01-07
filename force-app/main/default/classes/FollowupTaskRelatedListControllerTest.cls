@isTest
public class FollowupTaskRelatedListControllerTest {
    
    @testSetup
    static void setup() {
        //Create User
       
        String taskRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.TASK_RT_CARE_PLAN_TASK, J_ObjectUtils.TASK_API_NAME);
        
            User userDetails = new User(
            Alias = 'jStand',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'john@acme.com'
        );
        insert userDetails;
        Task t = new Task(
            RecordTypeId = taskRecordTypeId,
            ActivityDate = Date.today().addDays(1),
            OwnerId = userDetails.Id,
            Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
            Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
            Subject = J_ObjectUtils.TASK_SUBJECT_CUSTOM_CONTRACT_EXPIRATION
        );
        insert t;
    }
    
    static testMethod void fetchTaskRecordstest() {        
        Task newTask = [SELECT Id FROM Task limit 1];
        Test.startTest();
        	list<Task> taskList = FollowupTaskRelatedListController.fetchTaskRecords(newTask.Id); 
        	system.assert(taskList!=null);
        Test.stopTest();
    }

}