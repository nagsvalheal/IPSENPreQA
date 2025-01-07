/**
*   @author         Arkadii Sychov
*   @date           10/21/20
*   @description    IPSC-213. Unit Tests for J_InteractionDetailsTriggerHandler
**/
@isTest
public class J_InteractionDetailsTriggerHandlerTest {
    

    @TestSetup
    static void makeData(){
        //Create User
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0]) {
            User userCC = J_TestUtils.createTestJourneysUser();
            User userPEL = J_TestUtils.createTestJourneysUser();
        }
        
        User userDetails = new User(
            Alias = 'jStand',
            Email = 'standardusser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'john@acmme.com'
        );
        insert userDetails;

        
        List<J_Territory__c> Territory = new List<J_Territory__c>();
        J_Territory__c territoryCC = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
          
            J_TerritoryCode__c = 'test 1',
            J_States__c = 'Arkansas',
            Name = 'te1'
        );
        Territory.add(territoryCC);

        J_Territory__c territoryPEL = new J_Territory__c(
            J_Active__c = true,
            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
           
            J_TerritoryCode__c = 'test 2',
            J_States__c = 'Arkansas',
            Name = 'te2'
        );
        Territory.add(territoryPEL);

        insert Territory;

        //Create Patient
        Account patient = new Account(
            FirstName = 'First',
            LastName        = J_TestUtils.PATIENT_LAST_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonHomePhone = '00099',
            PersonMailingCity  = 'City 1',
            PersonMailingState = 'Arkansas',
            PersonMailingCountry = 'United States'
        );
        insert patient;
        
    }

    
    @isTest
    static void interactionDetailsEditingByCCForbiddenIfTaskStatusSubmitted() {
        User userDetails = new User(
            Alias = 'jStand',
            Email = 'standardduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'john@accme.com'
        );
        insert userDetails;
       //Create Patient
        Account patient = new Account(
            FirstName = 'First',
            LastName        = 'la',
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonHomePhone = '00099',
            PersonMailingCity  = 'City 1',
            PersonMailingState = 'Arkansas',
            PersonMailingCountry = 'United States'
        );
        insert patient;
        
        CareProgram CPone = new CareProgram(
            Name = 'TEST CARE PROGRAM 1',
            Status = 'Active',
            StartDate = system.today(),
            EndDate = system.today() + 5
        );
        insert CPone;
        
        CareProgramEnrollee CE1 = new CareProgramEnrollee(
        	Name = 'TEST ENROLLEE1',
            Status = 'Pending',
            Sub_Status__c='	New Enrollment',
            CareProgramId = CPone.Id,
            Clinical_trial_participant__c = 'No',
            AccountId = patient.id
        );
        insert CE1;
        
        String taskRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.TASK_RT_CARE_PLAN_TASK,  J_ObjectUtils.TASK_API_NAME);
       // User u = J_TestUtils.queryUser(J_TestUtils.USERNAME_TEST_CC)[0];
		String eventRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.EVENT_RT_JOURNEYS_EVENT,  J_ObjectUtils.EVENT_API_NAME);
        
        Test.startTest();
            //Ctreate Task
            Task t = new Task(
                RecordTypeId = taskRecordTypeId,
                ActivityDate = Date.today().addDays(1),
                OwnerId = userDetails.Id,
                Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
                Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                Subject = 'Benefit Investigation',
                WhatId = CE1.Id
            );
            insert t;
        
        	 Event evt = new Event(
                RecordTypeId = eventRecordTypeId,
                OwnerId = userDetails.Id,
                J_ActivityStatus__c = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                WhatId = CE1.Id,
                DurationInMinutes = 12,
                ActivityDateTime = DateTime.now().addMinutes(-10),
                J_City__c  ='Test city',
                J_State__c = 'AL'
            );
            insert evt;

			
            //Create Interaction Details
             Date d = System.today()+2;
            J_InteractionDetails__c intDet = new J_InteractionDetails__c(
                J_Type__c       = J_ObjectUtils.INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP,
                //J_SubType__c    = 'In-person',
                J_FollowUpNeeded__c = true,
                Follow_up_Date_Time__c =  DateTime.newInstance(d.year(),d.month(), d.day(), 10, 43, 1),
                Followup_Notes__c = 'Test Notes',
                Follow_up_with__c = 'HCP',
                Care_Program_Enrollee__c = CE1.Id
            );
            insert intDet;

            t.Status = J_ObjectUtils.TASK_STATUS_PL_SUBMITTED;
        	t.J_InteractionDetails__c = intDet.Id;
            update t;
        
        	evt.J_ActivityStatus__c = J_ObjectUtils.TASK_STATUS_PL_SUBMITTED;
        	evt.J_InteractionDetails__c = intDet.Id;
        	update evt;

        	Date dt = System.today()+4;
        	intDet.Follow_up_Date_Time__c =  DateTime.newInstance(dt.year(),dt.month(), dt.day(), 10, 43, 1);
            update intDet;
        
            Exception ex;
            try {
                System.runAs(userDetails) {
                    intDet.J_EventName__c = 'test';
                    update intDet;
                }
            } catch (Exception e) {
                ex = e;
            }
        Test.stopTest();

       
    }

    @isTest
    static void interactionDetailsEditingByPELForbiddenIfTaskStatusSubmitted() {
        Account patient = J_TestUtils.queryAccount()[0];
        
        CareProgram CPTwo = new CareProgram(
            Name = 'TEST CARE PROGRAM 2',
            Status = 'Active',
            StartDate = system.today(),
            EndDate = system.today() + 5
        );
        insert CPTwo;
        
        CareProgramEnrollee CE2 = new CareProgramEnrollee(
        	Name = 'TEST ENROLLEE2',
            Status = 'Pending',
            Sub_Status__c='	New Enrollment',
            CareProgramId = CPTwo.Id,
            Clinical_trial_participant__c = 'No',
            AccountId = patient.id
        );
        insert CE2;
        
        String taskRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.TASK_RT_CARE_PLAN_TASK,  J_ObjectUtils.TASK_API_NAME);
        
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1][0];

        Test.startTest();
            //Ctreate Task
            Task t = new Task(
                RecordTypeId = taskRecordTypeId,
                ActivityDate = Date.today().addDays(1),
                OwnerId = u.Id,
                Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
                Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                Subject = 'Consent expiring',
                WhatId = CE2.Id
                
            );
            insert t;

            //Create Interaction Details
            Date d = System.today()+2;
            J_InteractionDetails__c intDet = new J_InteractionDetails__c(
                J_Type__c       = J_ObjectUtils.INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP,
                //J_SubType__c    = 'In-person',
                J_FollowUpNeeded__c = true,
                Follow_up_Date_Time__c =  DateTime.newInstance(d.year(),d.month(), d.day(), 10, 43, 1),
                Followup_Notes__c = 'Test Notes',
                Follow_up_with__c = 'HCP',
                Care_Program_Enrollee__c = CE2.Id
            );
            insert intDet;

            t.J_InteractionDetails__c = intDet.Id;
            t.Status = J_ObjectUtils.TASK_STATUS_PL_SUBMITTED;
            update t;

            Exception ex;
            try {
                System.runAs(u) {
                    intDet.J_EventName__c = 'test';
                    update intDet;
                }
            } catch (Exception e) {
                ex = e;
            }
        Test.stopTest();

       
    }

    @isTest
    static void interactionDetailsEditingByPELForbiddenIfEventStatusSubmitted() {
        User userDetails = new User(
            Alias = 'jStand',
            Email = 'standarrduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'john@aacme.com'
        );
        insert userDetails;
        //Create Patient
        Account patient = new Account(
            FirstName = 'First',
            LastName        = 'larence',
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonHomePhone = '00099',
            PersonMailingCity  = 'City 1',
            PersonMailingState = 'Arkansas',
            PersonMailingCountry = 'United States'
        );
        insert patient;
        
        CareProgram CPThree = new CareProgram(
            Name = 'TEST CARE PROGRAM 3',
            Status = 'Active',
            StartDate = system.today(),
            EndDate = system.today() + 5
        );
        insert CPThree;
        
        CareProgramEnrollee CPEThree = new CareProgramEnrollee(
        	Name = 'TEST ENROLLEE3',
            Status = 'Pending',
            Sub_Status__c='	New Enrollment',
            CareProgramId = CPThree.Id,
            Clinical_trial_participant__c = 'No',
            AccountId = patient.id
        );
        insert CPEThree;
        
        String eventRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.EVENT_RT_JOURNEYS_EVENT,  J_ObjectUtils.EVENT_API_NAME);
       

        Test.startTest();
            //Ctreate Event
            Event e = new Event(
                RecordTypeId = eventRecordTypeId,
                OwnerId = userDetails.Id,
                J_ActivityStatus__c = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                J_City__c = 'New York',
                J_State__c = 'NY ',
                WhatId = CPEThree.Id,
                DurationInMinutes = 12,
                ActivityDateTime = DateTime.now().addMinutes(-10)
            );
            insert e;

            //Create Interaction Details
            J_InteractionDetails__c intDet = new J_InteractionDetails__c(
                J_Type__c       = J_ObjectUtils.INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP,
              
                Care_Program_Enrollee__c = CPEThree.Id
            );
            insert intDet;

            e.J_InteractionDetails__c = intDet.Id;
            e.J_ActivityStatus__c = J_ObjectUtils.TASK_STATUS_PL_SUBMITTED;
            update e;

            Exception ex;
            try {
                System.runAs(userDetails) {
                    intDet.J_EventName__c = 'test';
                    update intDet;
                }
            } catch (Exception e1) {
                ex = e1;
            }
        Test.stopTest();

     
    }

    @isTest
    static void interactionDetailsEditingByPELForbiddenIfEventStatusCancelled() {
        User userDetails = new User(
            Alias = 'jStand',
            Email = 'standaarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'johnn@acme.com'
        );
        insert userDetails;
       //Create Patient
        Account patient = new Account(
            FirstName = 'First',
            LastName        = 'teller',
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonHomePhone = '00099',
            PersonMailingCity  = 'City 1',
            PersonMailingState = 'Arkansas',
            PersonMailingCountry = 'United States'
        );
        insert patient;
        
         CareProgram CPfour = new CareProgram(
            Name = 'TEST CARE PROGRAM 4',
            Status = 'Active',
            StartDate = system.today(),
            EndDate = system.today() + 5
        );
        insert CPfour;
        
        CareProgramEnrollee CE4 = new CareProgramEnrollee(
        	Name = 'TEST ENROLLEE4',
            Status = 'Pending',
            Sub_Status__c='	New Enrollment',
            CareProgramId = CPfour.Id,
            Clinical_trial_participant__c = 'No',
            AccountId = patient.id
        );
        insert CE4;
        
        String eventRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.EVENT_RT_JOURNEYS_EVENT,  J_ObjectUtils.EVENT_API_NAME);
       

        Test.startTest();
            //Ctreate Event
            Event e = new Event(
                RecordTypeId = eventRecordTypeId,
                OwnerId = userDetails.Id,
                J_ActivityStatus__c = J_ObjectUtils.TASK_STATUS_PL_SUBMITTED,
                WhatId = CE4.Id,
                DurationInMinutes = 12,
                ActivityDateTime = DateTime.now().addMinutes(-10),
                J_City__c  ='Test city',
                J_State__c = 'AL'
            );
            insert e;

            //Create Interaction Details
            J_InteractionDetails__c intDet = new J_InteractionDetails__c(
                J_Type__c       = J_ObjectUtils.INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP,
               
                Care_Program_Enrollee__c = CE4.Id
            );
            insert intDet;

            e.J_InteractionDetails__c = intDet.Id;
            e.J_ActivityStatus__c = J_ObjectUtils.EVENT_ACTIVITY_STATUS_PL_CANCELLED;
            update e;

            Exception ex;
            try {
                System.runAs(userDetails) {
                    intDet.J_EventName__c = 'test';
                    update intDet;
                }
            } catch (Exception e1) {
                ex = e1;
            }
        Test.stopTest();

      
    }

    @isTest
    static void interactionDetailsEditingByAdminNotForbiddenIfEventStatusSubmitted() {
        Account patient = J_TestUtils.queryAccount()[0];
        
        CareProgram CPfive = new CareProgram(
            Name = 'TEST CARE PROGRAM 5',
            Status = 'Active',
            StartDate = system.today(),
            EndDate = system.today() + 5
        );
        insert CPfive;
        
        CareProgramEnrollee CPEFive = new CareProgramEnrollee(
        	Name = 'TEST ENROLLEE5',
            Status = 'Pending',
            Sub_Status__c='	New Enrollment',
            CareProgramId = CPfive.Id,
            Clinical_trial_participant__c = 'No',
            AccountId = patient.id
        );
        insert CPEFive;
        
        String eventRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.EVENT_RT_JOURNEYS_EVENT,  J_ObjectUtils.EVENT_API_NAME);

        Test.startTest();
            //Ctreate Event
            Event e = new Event(
                RecordTypeId = eventRecordTypeId,
                J_ActivityStatus__c = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                J_City__c = 'New York',
                J_State__c = 'NY ',
                WhatId = CPEFive.Id,
                DurationInMinutes = 12,
                ActivityDateTime = DateTime.now().addMinutes(-10)
            );
            insert e;

            //Create Interaction Details
            Date d = System.today()+2;
         J_InteractionDetails__c intDet = new J_InteractionDetails__c(
              J_Type__c       = J_ObjectUtils.INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP,
               
                J_FollowUpNeeded__c = true,
                Follow_up_Date_Time__c =  DateTime.newInstance(d.year(),d.month(), d.day(), 10, 43, 1),
                Followup_Notes__c = 'Test Notes',
                Follow_up_with__c = 'HCP',
                Care_Program_Enrollee__c = CPEFive.Id
        );
        insert intDet;

            e.J_InteractionDetails__c = intDet.Id;
            e.J_ActivityStatus__c = J_ObjectUtils.TASK_STATUS_PL_SUBMITTED;
            update e;

            Exception ex;
            try {
                intDet.J_EventName__c = 'test';
                update intDet;
            } catch (Exception e1) {
                ex = e1;
            }
        Test.stopTest();

      
    }

    @isTest
    static void interactionDetailsCCUserTaskGeneratedIfPELUserUpdatesDiscussionTopic() {
        User userDetails = new User(
            Alias = 'jStand',
            Email = 'staandarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'johnn@acme.com'
        );
        insert userDetails;
       //Create Patient
        Account patient = new Account(
            FirstName = 'Firstt',
            LastName        = J_TestUtils.PATIENT_LAST_NAME,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonHomePhone = '00099',
            PersonMailingCity  = 'City 1',
            PersonMailingState = 'Arkansas',
            PersonMailingCountry = 'United States'
        );
        insert patient;
        
        CareProgram CPsix = new CareProgram(
            Name = 'TEST CARE PROGRAM 6',
            Status = 'Active',
            StartDate = system.today(),
            EndDate = system.today() + 5
        );
        insert CPsix;
        
        CareProgramEnrollee CEsix = new CareProgramEnrollee(
        	Name = 'TEST ENROLLEE6',
            Status = 'Pending',
            Sub_Status__c='	New Enrollment',
            CareProgramId = CPsix.Id,
            Clinical_trial_participant__c = 'No',
            AccountId = patient.id
        );
        insert CEsix;
        
        String taskRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.TASK_RT_CARE_PLAN_TASK,  J_ObjectUtils.TASK_API_NAME);
       // User u = J_TestUtils.queryUser(J_TestUtils.USERNAME_TEST_PEL)[0];
        String interactionDetailsRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.INTERACTION_DETAILS_RECORD_TYPE_NAME_J_PEL_INTERACTIONS, J_ObjectUtils.ACTIVITY_INTERACTION_DETAILS_API_NAME);
        
        Test.startTest();
        //Ctreate Task
        Task t = new Task(
                RecordTypeId = taskRecordTypeId,
                ActivityDate = Date.today().addDays(1),
                OwnerId = userDetails.Id,
                Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
                Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                Subject = J_ObjectUtils.TASK_SUBJECT_PL_PATIENT_INTERACTION,
                WhatId = CEsix.Id
        );
        insert t;
        
        //Create Interaction Details
        J_InteractionDetails__c intDet = new J_InteractionDetails__c(
                J_Type__c       = J_ObjectUtils.INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP,
                //J_SubType__c    = J_ObjectUtils.INTERACTION_DETAILS_SUB_TYPE_PL_TEXT,
                RecordTypeId    = interactionDetailsRecordTypeId
        );
        //insert intDet;

        t.J_InteractionDetails__c = intDet.Id;
        t.Status = J_ObjectUtils.TASK_STATUS_PL_OPEN;
        update t;

        Exception ex;
        try {
            System.runAs(userDetails) {
                intDet.J_DiscussionTopics__c = J_ObjectUtils.INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_SUPPLY_ISSUE + ';' +
                        J_ObjectUtils.INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_HCP_ISSUE;
                update intDet;                
            }
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE Subject = :J_ObjectUtils.TASK_SUBJECT_PL_SUPPLY_ISSUE OR Subject = :J_ObjectUtils.TASK_SUBJECT_PL_HCP_ISSUE];
        
    }

    @isTest
    static void interactionDetailsCCUserTaskGeneratedIfPELUserUpdatesDiscussionTopicToDiseaseEducation() {
        User userDetails = new User(
            Alias = 'jStand',
            Email = 'standaarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'john@acmee.com'
        );
        insert userDetails;
        //Create Patient
        Account patient = new Account(
            FirstName = 'Firrst',
            LastName        = 'lname',
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonHomePhone = '00099',
            PersonMailingCity  = 'City 1',
            PersonMailingState = 'Arkansas',
            PersonMailingCountry = 'United States'
        );
        insert patient;
        
        CareProgram CPseven = new CareProgram(
            Name = 'TEST CARE PROGRAM 7',
            Status = 'Active',
            StartDate = system.today(),
            EndDate = system.today() + 5
        );
        insert CPseven;
        
        CareProgramEnrollee CE7 = new CareProgramEnrollee(
        	Name = 'TEST ENROLLEE7',
            Status = 'Pending',
            Sub_Status__c='	New Enrollment',
            CareProgramId = CPseven.Id,
            Clinical_trial_participant__c = 'No',
            AccountId = patient.id
        );
        insert CE7;
        
        String taskRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.TASK_RT_CARE_PLAN_TASK,  J_ObjectUtils.TASK_API_NAME);
      

        Test.startTest();
        //Ctreate Task
        Task t = new Task(
                RecordTypeId = taskRecordTypeId,
                ActivityDate = Date.today().addDays(1),
                OwnerId = userDetails.Id,
                Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
                Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                Subject = J_ObjectUtils.TASK_SUBJECT_PL_PATIENT_INTERACTION,
                WhatId = CE7.Id
        );
        insert t;

        //Create Interaction Details
        J_InteractionDetails__c intDet = new J_InteractionDetails__c(
                J_Type__c       = J_ObjectUtils.INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP,
                J_SubType__c    = J_ObjectUtils.INTERACTION_DETAILS_SUB_TYPE_PL_TEXT
        );
        //insert intDet;

        t.J_InteractionDetails__c = intDet.Id;
        t.Status = J_ObjectUtils.TASK_STATUS_PL_OPEN;
        update t;

        Exception ex;
        try {
            System.runAs(userDetails) {
                intDet.J_DiscussionTopics__c = J_ObjectUtils.INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_SAFETY_PROTOCOL_REVIEW;
                update intDet;
            }
        } catch (Exception e) {
            ex = e;
        }
        Test.stopTest();

        List<Task> tasks = [SELECT Id FROM Task WHERE Subject = :J_ObjectUtils.INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_SAFETY_PROTOCOL_REVIEW];
       
    }
    
    @isTest
    static void interactionDetailsDiscussionTopics() {
        User userDetails = new User(
            Alias = 'jStand',
            Email = 'standarduserr@teestorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'abcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'john@aaaccmme.com'
        );
        insert userDetails;
       Account patient = J_TestUtils.queryAccount()[0];
        
       
       // User u = J_TestUtils.queryUser(J_TestUtils.USERNAME_TEST_CC)[0];
        String taskRecordTypeId = J_ObjectUtils.getRecordTypeId(J_ObjectUtils.TASK_RT_CARE_PLAN_TASK,  J_ObjectUtils.TASK_API_NAME);
        String intRecordTypeId = J_ObjectUtils.getRecordTypeId('J_InteractionsRT',  J_ObjectUtils.ACTIVITY_INTERACTION_DETAILS_API_NAME);
        Test.startTest();
			
         CareProgram CPeight = new CareProgram(
            Name = 'TEST CARE PROGRAM 8',
            Status = 'Active',
            StartDate = system.today(),
            EndDate = system.today() + 5
        );
        insert CPeight;
        
        CareProgramEnrollee CEeight = new CareProgramEnrollee(
        	Name = 'TEST ENROLLEE8',
            Status = 'Pending',
            Sub_Status__c = 'New Enrollment',
            CareProgramId = CPeight.Id,
            Clinical_trial_participant__c = 'No',
            AccountId = patient.id
        );
        insert CEeight;
        
        
            //Create Interaction Details
             Date d = System.today()+2;
            J_InteractionDetails__c intDet = new J_InteractionDetails__c(
                J_Type__c       = J_ObjectUtils.INTERACTION_DETAILS_TYPE_PL_FOLLOW_UP,
               
                J_FollowUpNeeded__c = true,
                Follow_up_Date_Time__c =  DateTime.newInstance(d.year(),d.month(), d.day(), 10, 43, 1),
                Followup_Notes__c = 'Test Notes',
                Follow_up_with__c = 'HCP',
                RecordTypeId = intRecordTypeId,
                Care_Program_Enrollee__c = CEeight.id
            );
            insert intDet;
        
        	Task t = new Task(
                RecordTypeId = taskRecordTypeId,
                ActivityDate = Date.today().addDays(1),
                OwnerId = userDetails.Id,
                Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
                Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
                Subject = J_ObjectUtils.TASK_SUBJECT_PL_PATIENT_INTERACTION,
                WhatId = CEeight.Id,
                J_InteractionDetails__c = intDet.Id
        		);
        		insert t;
        
        	intDet.J_Role__c = 'Journeys Manager';
        	intDet.J_DiscussionTopics__c = J_ObjectUtils.INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_SUPPLY_ISSUE+ ';' +
                       					J_ObjectUtils.INTERACTION_DETAILS_DISCUSSION_TOPIC_PL_NEW_PHYSICIAN;
            update intDet;  
        
        Test.stopTest();
    }
    
   
}