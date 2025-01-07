@isTest 
public class BatchCreateMisdShipmentTaskOnPatientTest {
    
    @TestSetup
    static void makeData() {

        UserRole ccRole = (UserRole)COM_QueryUtility.executeQuery(
            'UserRole', 
            'Id', 
            'DeveloperName = \'Care_Coordinator\'', 
            true
        )[0];
        
        User u = new User(
            Alias = 'jStand',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'AbcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = J_TestUtils.USERNAME_TEST_CC,
            UserRoleId = ccRole.Id
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{u}, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
        
        System.runAs(u) {
            //Create Care program
            CareProgram cp = new CareProgram(
                Name = 'Care Program',
                StartDate = system.today(),
                Status = 'Active'
            );
            COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{cp}, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
            
            String recordTypeId = Schema.SObjectType.J_Territory__c.getRecordTypeInfosByName()
                    .get('Territory')
                    .getRecordTypeId();
            
            List<J_Territory__c> lTerritory = new List<J_Territory__c>();
            J_Territory__c territoryCC = new J_Territory__c(
                J_Active__c = true,
                J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
                J_TerritoryType__c = 'CC',
                J_TerritoryCode__c = 'test CC',
                J_States__c = 'test 1',
                Name = 'CC Default',
                OwnerId = u.id,
                Care_Program__c = cp.Id,
                recordTypeId = recordTypeId
            );
            lTerritory.add(territoryCC);
            
            J_Territory__c territoryPEL = new J_Territory__c(
                J_Active__c = true,
                J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
                J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
                J_TerritoryCode__c = 'test PEL',
                J_States__c = 'test 2',
                Name = J_TestUtils.TERRITORY_NAME_PEL
            );
            lTerritory.add(territoryPEL);
            
            COM_DatabaseOperationsUtility.insertOperation(lTerritory, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
        }
    }
    
    @isTest 
    static void runBatchToCreateMissedShipmentOnPatient() 
    {
        CareProgram cpf = (CareProgram)COM_QueryUtility.executeQuery(
            'CareProgram', 
            'Id', 
            '', 
            true
        )[0];
        
        Account patient = new Account(
            FirstName = 'Patient1',
            LastName = 'Test2',
            RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c =  'Mailing',
            PersonMailingPostalCode = '11111',
            PersonMailingStreet = 'Street',
            PersonMailingState= 'Arkansas',
            PersonMailingCity = 'City',
            PersonBirthdate = Date.parse('10/28/2004')
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{patient}, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
        
        Id currentUserId = UserInfo.getUserId();
        CareProgramEnrollee cpe = new CareProgramEnrollee(
            Name = 'Enrollee Test23',
            Status = 'Pending',
            Sub_Status__c = 'New Enrollment',
            CareProgramId = cpf.Id,
            Clinical_trial_participant__c = 'Yes',
            AccountId = patient.Id,
            System_Assigned_Territory__c = False,
            CC_Owner__c = currentUserId
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{cpe}, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
        
        AuthorizationForm af = new AuthorizationForm(Name = 'PA Form');
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{af}, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
        
        AuthorizationFormText aft = new AuthorizationFormText(
            Name = 'PA text',
            AuthorizationFormId = af.Id,
            Locale = '',
            SummaryAuthFormText = 'you will have separate test methods for insert and update scenarios'
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{aft}, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
        
        AuthorizationFormConsent afc = new AuthorizationFormConsent(
            ConsentGiverId = cpe.Id,
            AuthorizationFormTextId = aft.Id,
            Name = 'PA Consent',
            J_TypeOfConsent__c = 'Patient Authorization',
            Consented_by_others__c = 'No',
            J_ConsentStatus__c = 'Active',
            ConsentCapturedDateTime = system.today(),
            J_Mail__c = 'Opt-in',
            J_SMS__c = 'Opt-in',
            J_Email__c = 'Opt-in',
            J_Meetings__c = 'Opt-in',
            J_Phone__c = 'Opt-in',
            J_MarketingMeterial__c = 'Opt-in',
            J_EnrollmentFormAttached__c = true
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{afc}, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
        
        J_Order__c orderObj = new J_Order__c(
            J_NDC_Number__c = '1020202',
            Care_Program_Enrollee__c = cpe.Id,
            J_SP_Refill_Date__c = system.today()-4,
            J_Order_Ship_Date__c = Date.newInstance(2024, 7, 22)
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{orderObj}, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
        
        J_Order__c orderObj1 = new J_Order__c(
            J_NDC_Number__c = '1020202',
            Care_Program_Enrollee__c = cpe.Id,
            J_SP_Refill_Date__c = Date.newInstance(2024, 6, 17),
            J_Order_Ship_Date__c = system.today()-6
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{orderObj1}, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
        
        J_Order__c orderObj2 = new J_Order__c(
            J_NDC_Number__c = '1020202',
            Care_Program_Enrollee__c = cpe.Id,
            J_SP_Refill_Date__c = system.today()-4,
            J_Order_Ship_Date__c = system.today()-6
        );
        COM_DatabaseOperationsUtility.insertOperation(new List<SObject>{orderObj2}, 'BatchCreateMisdShipmentTaskOnPatientTest', false);
        
        batchToCreateMissedShipmentTaskOnPatient bJob = new batchToCreateMissedShipmentTaskOnPatient();
        Database.executeBatch(bJob); 
        
        List<Task> tasks = (List<Task>)COM_QueryUtility.executeQuery(
            'Task', 
            'Id, Subject, WhatId, Status', 
            'WhatId = \'' + patient.Id + '\'', 
            true
        );
        System.assertEquals(1, tasks.size(), 'One task should be created for the patient.');
        
        batchToCreateMissedShipmentTaskOnPatient bJob1 = new batchToCreateMissedShipmentTaskOnPatient();
        Database.executeBatch(bJob1);
    }
}