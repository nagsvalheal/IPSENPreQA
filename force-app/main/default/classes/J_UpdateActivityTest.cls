@isTest
public class J_UpdateActivityTest {
  
  @TestSetup
  static void makeData() {
    User u = new User(
      Alias = 'jStand',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LastName = 'AbcdTest',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = J_ObjectUtils.getProfileIdByName(
        J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER
      ),
      TimeZoneSidKey = 'America/Los_Angeles',
      Username = 'jTest@jTesting.com',
      Patient_Ambassador_Manager__c = true
    );
    insert u;

    //Create Territory
    List<J_Territory__c> listOfTerritories = new List<J_Territory__c>();
    J_Territory__c territoryCC = new J_Territory__c(
      J_Active__c = true,
      J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
      J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
      J_TerritoryCode__c = 'test 1',
      J_States__c = 'test 1',
      Name = J_TestUtils.TERRITORY_NAME_CC
    );
    listOfTerritories.add(territoryCC);

    J_Territory__c territoryPEL = new J_Territory__c(
      J_Active__c = true,
      J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
      J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
      J_TerritoryCode__c = 'test 2',
      J_States__c = 'test 2',
      Name = J_TestUtils.TERRITORY_NAME_PEL
    );
    listOfTerritories.add(territoryPEL);

    insert listOfTerritories;
    
    String taskRecordTypeId = J_ObjectUtils.getRecordTypeId(
      J_ObjectUtils.TASK_RT_CARE_PLAN_TASK,
      J_ObjectUtils.TASK_API_NAME
    );
    String eventRecordTypeId = J_ObjectUtils.getRecordTypeId(
      J_ObjectUtils.EVENT_RT_JOURNEYS_EVENT,
      J_ObjectUtils.EVENT_API_NAME
    );
    
    //Create Patient
    Account patient = new Account(
      FirstName = 'First',
      LastName = J_TestUtils.PATIENT_LAST_NAME,
      RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(
        J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME,
        true
      ),
      J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
      PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
      PersonMailingStreet = J_TestUtils.STREET_MAILING,
      PersonBirthdate = Date.today().addYears(-19),
      Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
      Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
      PersonHomePhone = '00099',
      PersonMailingCity = 'Coimbatore',
      PersonMailingCountry = 'Australia',
      PersonMailingState = 'Queensland',
      J_PatientAmbassadorStatus__c = 'Active',
      Patient_Ambassador_Manager__c = u.id
    );
    insert patient;

    //Create Care Program
    CareProgram cp = new CareProgram(
      Name = 'Test Care Program',
      StartDate = Date.today(),
      EndDate = Date.today().addDays(1),
      Status = 'Active',
      Organisation_Fax_number__c = '17650334563'
    );
    insert cp;

    // Create a CareProgramEnrollee record and set the lookup field to the CareProgram record created above
    CareProgramEnrollee enrollee = new CareProgramEnrollee(
      Name = 'Test Enrollee',
      Status = 'Pending',
      Sub_Status__c = 'New Enrollment',
      Clinical_trial_participant__c = 'No',
      AccountId = patient.Id,
      CareProgramId = cp.Id
    );
    insert enrollee;

    // Create Task
    Task t = new Task(
      RecordTypeId = taskRecordTypeId,
      ActivityDate = Date.today().addDays(1),
      OwnerId = u.Id,
      Priority = J_ObjectUtils.TASK_PRIORITY_PL_NORMAL,
      Status = J_ObjectUtils.TASK_STATUS_PL_OPEN,
      Subject = 'Welcome Call',
      WhatId = enrollee.Id
    );
    insert t;

  
  }

  @isTest
  static void createInteractionDetailsTest() {
    User u = [SELECT Id FROM User WHERE Username = 'jTest@jTesting.com'];
    UserRole role = [
      SELECT Id
      FROM UserRole
      WHERE DeveloperName = 'Journeys_Manager'
    ];
    u.UserRoleId = role.Id;
    update u;
    
    Task tsk = [SELECT Id FROM Task LIMIT 1];
    String result;
    Exception ex;
    
    Test.startTest();
    try {
      System.runAs(u) {
        result = J_UpdateActivity.updateActivity(tsk.Id, 'Task');
      }
    } catch (Exception e) {
      ex = e;
    }
    Test.stopTest();
    
    // Verify that no exception was thrown
    System.assert(ex == null, 'Expected no exception, but got: ' + ex);
    
    // Verify that the interaction detail was created and task was updated
    Task updatedTask = [SELECT Id, J_InteractionDetails__c FROM Task WHERE Id = :tsk.Id];
    System.assertNotEquals(null, updatedTask.J_InteractionDetails__c, 'Interaction detail should be created and linked to the task.');
    
    // Verify the result message
    //System.assertEquals('Interaction Record created successfully', result, 'Expected success message.');
  }

  @isTest
  static void createInteractionDetailsExceptionTest() {
    User u = [SELECT Id FROM User WHERE Username = 'jTest@jTesting.com'];
    UserRole role = [
      SELECT Id
      FROM UserRole
      WHERE DeveloperName = 'Care_Coordinator'
    ];
    u.UserRoleId = role.Id;
    update u;
    
      }
}