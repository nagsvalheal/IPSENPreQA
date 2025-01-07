@isTest
public class FollowupEventsRelatedListControllerTest {
    
    @testSetup
    static void setup() {
     
        String eventRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.EVENT_RT_JOURNEYS_EVENT,  J_ObjectUtils.EVENT_API_NAME);
       
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
        Event eve = new Event(
            RecordTypeId = eventRecordTypeId,            
            OwnerId = userDetails.Id,
            J_ActivityStatus__c = J_ObjectUtils.TASK_STATUS_PL_OPEN,
            J_City__c = 'New York',
            J_State__c = 'NY ',
            DurationInMinutes = 12,
            ActivityDateTime = DateTime.now().addMinutes(-10)
        );
        insert eve;
    }
    
    static testMethod void fetchTaskRecordstest() {        
        Event newEvent = [SELECT Id FROM Event limit 1];
        Test.startTest();
        	list<Event> eventList = FollowupEventsRelatedListController.fetchEventRecords(newEvent.Id); 
        	system.assert(eventList!=null);
        Test.stopTest();
    }

}