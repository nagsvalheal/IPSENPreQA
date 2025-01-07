@IsTest
public class J_TaskTriggerHandlerTest {
    @TestSetup
    static void makeData() {
       
        
        //Create Territory
        List<J_Territory__c> l_territory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(J_Active__c = true,
                                                        J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
                                                        //J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
                                                        J_TerritoryCode__c = 'test 1',
                                                        J_States__c = 'test 1',
                                                        Name = 'tename'
                                                       );
        l_territory.add(territoryCC);
        
        J_Territory__c territoryPEL = new J_Territory__c(J_Active__c = true,
                                                         J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
                                                         J_TerritoryType__c = 'PEL',
                                                         J_TerritoryCode__c = 'test 2',
                                                         J_States__c = 'test 2',
                                                         Name = 'tetwo'
                                                        );
        l_territory.add(territoryPEL);
        
        insert l_territory;
        
        //Create Patient
        Account patient = new Account(LastName = J_TestUtils.PATIENT_LAST_NAME,
                                      RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
                                      J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
                                      PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
                                      PersonMailingStreet = J_TestUtils.STREET_MAILING,
                                      PersonMailingCity = 'Coimbatore',
                                      PersonMailingCountry='Australia',
                                      PersonMailingState = 'Queensland',
                                      PersonEmail = 'test@test.com',
                                      FirstName='test'
                                     );
        insert patient;
        
        CareProgram CP1 = new CareProgram(Name = 'TEST CARE PROGRAM 1',
                                          Status = 'Active',
                                          StartDate = system.today(),
                                          EndDate = system.today() + 5
                                         );
        insert CP1;
        
        CareProgramEnrollee CE1 = new CareProgramEnrollee(Name = 'TEST ENROLLEE1',
                                                          Status = 'Pending',
                                                          Sub_Status__c='New Enrollment',
                                                          CareProgramId = CP1.Id,
                                                          Clinical_trial_participant__c = 'No',
                                                          AccountId = patient.id
                                                         );
        insert CE1;
        
        //Create Task
        String taskRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.TASK_RT_CARE_PLAN_TASK, J_ObjectUtils.TASK_API_NAME);
       
         User userDetails = new User(
            Alias = 'jStand',
            Email = 'standardusser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'john@axcme.com'
        );
        insert userDetails;
        
        Task t = new Task(RecordTypeId = taskRecordTypeId,
                          ActivityDate = Date.today().addDays(1),
                          OwnerId = userDetails.Id,
                          Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
                          Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                          Subject = 'Internal interaction',
                          WhatId = CE1.Id
                         );
        insert t;
        Task task = new Task(RecordTypeId = taskRecordTypeId,
                          ActivityDate = Date.today().addDays(1),
                          OwnerId = userDetails.Id,
                          Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
                          Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                          Subject = 'Internal interaction',
                          WhatId = CE1.Id
                         );
        insert task;
        Date d = System.today()+2;
 J_InteractionDetails__c interactionDetail1 = new J_InteractionDetails__c(
            
            
                J_Type__c       = J_ObjectUtils.INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP,
                //J_SubType__c    = 'In-person',
                J_FollowUpNeeded__c = true,
                Follow_up_Date_Time__c =  DateTime.newInstance(d.year(),d.month(), d.day(), 10, 43, 1),
                Followup_Notes__c = 'Test Notes',
                Follow_up_with__c = 'HCP',
                Care_Program_Enrollee__c = CE1.Id
          
            
        );
        J_InteractionDetails__c interactionDetail2 = new J_InteractionDetails__c(
              J_Type__c       = J_ObjectUtils.INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP,
                //J_SubType__c    = 'In-person',
                J_FollowUpNeeded__c = true,
                Follow_up_Date_Time__c =  DateTime.newInstance(d.year(),d.month(), d.day(), 10, 43, 1),
                Followup_Notes__c = 'Test Notes',
                Follow_up_with__c = 'HCP',
                Care_Program_Enrollee__c = CE1.Id
        );
        insert new List<J_InteractionDetails__c>{interactionDetail1, interactionDetail2};
            
        
    }
  
    @IsTest
    static void checkDeleteAccessTestJourneyUser() 
    {
       
        User userDetails = new User(
            Alias = 'jStand',
            Email = 'standaaqrduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'john@acwmes.com'
        );
        insert userDetails;
      
       Task newTask = new Task(
        Subject = J_ObjectUtils.TASK_SUBJECT_CUSTOM_CONTRACT_EXPIRATION,
        OwnerId = userDetails.Id,
        Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
        Priority = 'Normal'
    );
    insert newTask; 
        Test.startTest();
        Exception ex;
        try {
            System.runAs(userDetails) {
                delete newTask;
            }
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();
        
        System.assertNotEquals(null, ex);
    }
    
    @IsTest
    static void checkDeleteAccessTestAdminUser() 
    {
      
        User userDetails = new User(
            Alias = 'jStand',
            Email = 'statndarduserr@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'john@arcmee.com'
        );
        insert userDetails;
        User adminUser = new User(Alias = 'jAdm',
                                  Email = 'adminuser@testorg.com',
                                  EmailEncodingKey = 'UTF-8',
                                  LastName = 'AbcdTest',
                                  LanguageLocaleKey = 'en_US',
                                  LocaleSidKey = 'en_US',
                                  ProfileId = J_ObjectUtils.getProfileIdByName('System Administrator'),
                                  TimeZoneSidKey = 'America/Los_Angeles',
                                  Username = 'jTest@jTesting.com'
                                 );
        insert adminUser;
       
        Task newTask = new Task(
        Subject = J_ObjectUtils.TASK_SUBJECT_CUSTOM_CONTRACT_EXPIRATION,
        OwnerId = userDetails.Id,
        Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
        Priority = 'Normal'
    );
    insert newTask;
        Test.startTest();
        Exception ex;
        try {
            System.runAs(adminUser) {
                delete newTask;
            }
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();
        
        System.assertEquals(null, ex);
    }
    
    @IsTest
    static void checkPELOwnerTest_Insert() 
    {

         User userDetails = new User(
            Alias = 'jStand',
            Email = 'stavndarduser@ttestorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'john@avcmme.com'
        );
        insert userDetails;
        Id intDetRecordTypeId = J_ObjectUtils.getRecordTypeId('J_WelcomeCallDetails','J_InteractionDetails__c');
        CareProgramEnrollee enro = [select id from CareProgramEnrollee Limit 1];
        J_InteractionDetails__c testInteractionDetails = new J_InteractionDetails__c(RecordTypeId = intDetRecordTypeId,
                                                                                     J_UnsuccessfulCallAttempt__c='1',
                                                                                     J_AttemptedOutreachDate__c= system.today(),
                                                                                     Care_Program_Enrollee__c = enro.Id
                                                                                    );
        insert testInteractionDetails;
        
        
        
        CareProgramEnrollee enro1 = [select id from CareProgramEnrollee Limit 1];
        
        
        Task t = new Task(ActivityDate = Date.today().addDays(1),
                          OwnerId = userDetails.Id,
                          Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
                          Status = J_ObjectUtils.TASK_STATUS_PL_SUBMITTED,
                          Subject = 'Welcome Call',
                          WhatId = enro1.Id,
                          J_InteractionDetails__c = testInteractionDetails.Id            
                         );
        try{
            insert t;            
        }catch(Exception ex){            
            System.assert(ex.getMessage().contains('You should select PEL Enrollee Owner before submitting the task'));
        }
        
    }  
    
 @isTest
    static void testFetchAndUpdateInteractionDetails() {
        // Retrieve test data
        List<Task> tasks = [SELECT Id, WhatId, ActivityDate FROM Task];
        Map<Id, Date> interactionDetailIdToNewDateMap = new Map<Id, Date>();
        for (Task task : tasks) {
            interactionDetailIdToNewDateMap.put(task.WhatId, task.ActivityDate);
        }

        
        List<J_InteractionDetails__c> detailsToUpdate = J_TaskTriggerHandler.fetchAndUpdateInteractionDetails(interactionDetailIdToNewDateMap);

        
        System.assertEquals(0, detailsToUpdate.size(), 'The number of interaction details fetched should match the input map.');
      

   
        Test.startTest();
        J_TaskTriggerHandler.updateInteractionDetails(detailsToUpdate);
        Test.stopTest();

    }
    
}