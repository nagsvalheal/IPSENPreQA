/**
 * @description       : Test class for the EmailMessageDetails trigger. It validates the creation of 
 *                      Email_Data__c records based on EmailMessage insertions linked to various related objects.
 * @author            : Abinsha Basheer
 * @group             : 
 * @last modified on  : 22-11-2023
 * @last modified by  : Abinsha Basheer
 */

 @isTest
 public class EmailMessageDetailsTest {
 
     /**
      * @description : Tests the EmailMessageDetails trigger for a scenario where EmailMessage is linked to 
      *                CareProgramEnrollee. Validates that Email_Data__c records are created with appropriate fields.
      */
     @isTest
     static void testEmailMessageDetailsTrigger() {
         Date startDates = Date.newInstance(2023, 10, 1);
         Date endDates = Date.newInstance(2023, 12, 31);
 
         // Create a test Account
         Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
             .get('J_Journeys_Patient').getRecordTypeId();
 
         Account newPersonAccount = new Account();
         newPersonAccount.Patient_Type__c = 'US';
         newPersonAccount.FirstName = 'Fred';
         newPersonAccount.LastName = 'Smith';
         newPersonAccount.RecordTypeId = personAccountRecordTypeId;
         newPersonAccount.Active_Enrollment__pc = true;
         newPersonAccount.IsActive = true;
         insert newPersonAccount;
 
         newPersonAccount.Patient_Status__pc = 'Active';
         update newPersonAccount;
 
         CareProgram cprogram = new CareProgram(
             Name = 'Test',
             Status = 'Active',
             StartDate = startDates,
             EndDate = endDates
         );
         insert cprogram;
 
         CareProgramEnrollee careProgramEnrollees = new CareProgramEnrollee(
             Name = 'Enrollee Test',
             Status = 'Pending',
             Sub_Status__c = 'PAP Enrollment',
             PA_Consent_Status__c = 'Active',
             CareProgramId = cprogram.Id,
             Clinical_trial_participant__c = 'Yes',
             AccountId = newPersonAccount.Id
         );
         insert careProgramEnrollees;
 
         // Create a test EmailMessage
         EmailMessage testEmailMessage = new EmailMessage(
             Subject = 'Internal interaction',
             ToAddress = 'test@example.com',
             MessageDate = System.now(),
             HtmlBody = '<html><body><p>This is a test HTML body.</p></body></html>',
             RelatedToId = careProgramEnrollees.Id
         );
         insert testEmailMessage;
 
         // Validate that the Email_Data__c record is created and fields are populated correctly
         List<Email_Data__c> emailDataList = [
             SELECT Id, Subject__c, Statuses__c, To_Address__c, Send_Date_Time__c,
                    Sent_email_ID__c, Messages__c, Related_To__c, Care_Program_Enrollee__c
             FROM Email_Data__c WHERE Sent_email_ID__c = :testEmailMessage.Id
         ];
         System.assertEquals(1, emailDataList.size(), 'EmailData record was created');
         if (!emailDataList.isEmpty()) {
         Email_Data__c emailData = emailDataList[0];
         System.assertEquals(testEmailMessage.Subject, emailData.Subject__c, 'Subject is Internal interaction');
         System.assertEquals(testEmailMessage.ToAddress, emailData.To_Address__c, 'ToAddress is test@example.com');
         System.assertEquals(testEmailMessage.MessageDate, emailData.Send_Date_Time__c, 'Message Date is current date and time');
         System.assertEquals(testEmailMessage.Id, emailData.Sent_email_ID__c, 'Sent email ID matches');
         System.assertEquals(careProgramEnrollees.Id, emailData.Care_Program_Enrollee__c, 'CareProgramEnrollee ID matches');
         }
     }
 
     /**
      * @description : Tests the EmailMessageDetails trigger for a scenario where EmailMessage is linked to 
      *                J_Charitable__c. Validates that Email_Data__c records are created with appropriate fields.
      */
     @isTest
     static void testEmailMessageDetailsTriggerForJCharitable() {
         Date startDates = Date.newInstance(2023, 10, 1);
         Date endDates = Date.newInstance(2023, 12, 31);
 
         CareProgram cprogram = new CareProgram(
             Name = 'Test',
             Status = 'Active',
             StartDate = startDates,
             EndDate = endDates
         );
         insert cprogram;
 
         Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
             .get('J_Journeys_Patient').getRecordTypeId();
 
         Account newPersonAccount = new Account();
         newPersonAccount.Patient_Type__c = 'US';
         newPersonAccount.FirstName = 'Fred';
         newPersonAccount.LastName = 'Smith';
         newPersonAccount.RecordTypeId = personAccountRecordTypeId;
         newPersonAccount.Active_Enrollment__pc = true;
         newPersonAccount.IsActive = true;
         insert newPersonAccount;
 
         newPersonAccount.Patient_Status__pc = 'Active';
         update newPersonAccount;
 
         CareProgramEnrollee careProgramEnrollee = new CareProgramEnrollee(
             Name = 'Fred - Test',
             AccountId = newPersonAccount.Id,
             Status = 'Pending',
             Sub_Status__c = 'New Enrollment',
             PA_Consent_Status__c = 'Active',
             CareProgramId = cprogram.Id
         );
         insert careProgramEnrollee;
 
         J_Charitable__c jCharitableRecord = new J_Charitable__c(
             J_Exception_Approver_text__c = 'Test Charitable Record',
             J_CharitableStatus__c = 'Closed',
             Care_Program_Enrollee__c = careProgramEnrollee.Id,
             J_CharitableFormAttached__c = TRUE
         );
         insert jCharitableRecord;
 
         EmailMessage testEmailMessage = new EmailMessage(
             Subject = 'Internal interaction',
             ToAddress = 'test@example.com',
             MessageDate = System.now(),
             HtmlBody = '<html><body><p>This is a test HTML body.</p></body></html>',
             RelatedToId = jCharitableRecord.Id
         );
         insert testEmailMessage;
 
         List<Email_Data__c> emailDataList = [
             SELECT Id, Subject__c, Statuses__c, To_Address__c, Send_Date_Time__c,
                    Sent_email_ID__c, Messages__c, Related_To__c, PAP_TPAP__c
             FROM Email_Data__c WHERE Sent_email_ID__c = :testEmailMessage.Id
         ];
         System.assertEquals(1, emailDataList.size(), 'EmailData record was created');
         if (!emailDataList.isEmpty()) {
         Email_Data__c emailData = emailDataList[0];
         System.assertEquals(testEmailMessage.Subject, emailData.Subject__c, 'Subject is Internal interaction');
         System.assertEquals(testEmailMessage.ToAddress, emailData.To_Address__c, 'ToAddress is test@example.com');
         System.assertEquals(testEmailMessage.MessageDate, emailData.Send_Date_Time__c, 'Message Date is current date and time');
         System.assertEquals(testEmailMessage.Id, emailData.Sent_email_ID__c, 'Sent email ID matches');
         System.assertEquals(jCharitableRecord.Id, emailData.PAP_TPAP__c, 'RelatedToId is J_Charitable__c');
         }
     }
 
     // Remaining methods have been formatted similarly.
     // Due to space constraints, I’ll stop here. Let me know if you'd like the rest of the class formatted and shared in another response.
     /**
     * @description : Tests the EmailMessageDetails trigger for a scenario where EmailMessage is linked to 
     *                J_Copay__c. Validates that Email_Data__c records are created with appropriate fields.
     */
    @isTest
    static void testEmailMessageDetailsTriggerForCopay() {
        Date startDates = Date.newInstance(2023, 10, 1);
        Date endDates = Date.newInstance(2023, 12, 31);

        CareProgram cprogram = new CareProgram(
            Name = 'Test',
            Status = 'Active',
            StartDate = startDates,
            EndDate = endDates
        );
        insert cprogram;

        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('J_Journeys_Patient').getRecordTypeId();

        Account newPersonAccount = new Account();
        newPersonAccount.Patient_Type__c = 'US';
        newPersonAccount.FirstName = 'Fred';
        newPersonAccount.LastName = 'Smith';
        newPersonAccount.RecordTypeId = personAccountRecordTypeId;
        newPersonAccount.Active_Enrollment__pc = true;
        newPersonAccount.IsActive = true;
        insert newPersonAccount;

        newPersonAccount.Patient_Status__pc = 'Active';
        update newPersonAccount;

        CareProgramEnrollee careProgramEnrollee = new CareProgramEnrollee(
            Name = 'Fred - Test',
            AccountId = newPersonAccount.Id,
            Status = 'Pending',
            Sub_Status__c = 'New Enrollment',
            PA_Consent_Status__c = 'Active',
            CareProgramId = cprogram.Id
        );
        insert careProgramEnrollee;

        MemberPlan mp = new MemberPlan(
            Name = 'MEMBER_PLAN_NAME',
            MemberId = newPersonAccount.Id,
            Status = 'Active',
            J_InsuranceType__c = 'Commercial',
            J_PolicyNumber__c = '001',
            J_Role__c = 'Primary'
        );
        insert mp;

        CoverageBenefit cb = new CoverageBenefit(
            Name = 'COVERAGE_BENEFIT_PLAN_NAME',
            MemberPlanId = mp.Id,
            Care_Program_Enrollee__c = careProgramEnrollee.Id,
            J_CoverageBenefitStatus__c = 'Active'
        );
        insert cb;

        J_Copay__c copay = new J_Copay__c(
            Care_Program_Enrollee__c = careProgramEnrollee.Id,
            J_EnrollmentStartDate__c = Date.today(),
            Insurance_Plan__c = mp.Id,
            J_CopayEnrollmentID__c = '12345',
            J_CurrentCopayStatus__c = J_ObjectUtils.COPAY_CURRENT_COPAY_STATUS_PL_ACTIVE
        );
        insert copay;

        EmailMessage testEmailMessage = new EmailMessage(
            Subject = 'Internal interaction',
            ToAddress = 'test@example.com',
            MessageDate = System.now(),
            HtmlBody = '<html><body><p>This is a test HTML body.</p></body></html>',
            RelatedToId = copay.Id
        );
        insert testEmailMessage;

        List<Email_Data__c> emailDataList = [
            SELECT Id, Subject__c, Statuses__c, To_Address__c, Send_Date_Time__c,
                   Sent_email_ID__c, Messages__c, Related_To__c, Copay__c
            FROM Email_Data__c WHERE Sent_email_ID__c = :testEmailMessage.Id
        ];
        System.assertEquals(1, emailDataList.size(), 'EmailData record was created');
        if (!emailDataList.isEmpty()) {
        Email_Data__c emailData = emailDataList[0];
        System.assertEquals(testEmailMessage.Subject, emailData.Subject__c, 'Subject is Internal interaction');
        System.assertEquals(testEmailMessage.ToAddress, emailData.To_Address__c, 'ToAddress is test@example.com');
        System.assertEquals(testEmailMessage.MessageDate, emailData.Send_Date_Time__c, 'Message Date is current date and time');
        System.assertEquals(testEmailMessage.Id, emailData.Sent_email_ID__c, 'Sent email ID matches');
        System.assertEquals(copay.Id, emailData.Copay__c, 'RelatedTo is test Copay ID');
        }
    }

    /**
     * @description : Tests the EmailMessageDetails trigger for a scenario where EmailMessage is linked to 
     *                Prior_Authorization__c. Validates that Email_Data__c records are created with appropriate fields.
     */
    @isTest
    static void testEmailMessageDetailsTriggerForPriorAuthorization() {
        Date startDates = Date.newInstance(2023, 10, 1);
        Date endDates = Date.newInstance(2023, 12, 31);

        CareProgram cprogram = new CareProgram(
            Name = 'Test',
            Status = 'Active',
            StartDate = startDates,
            EndDate = endDates
        );
        insert cprogram;

        Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
            .get('J_Journeys_Patient').getRecordTypeId();

        Account newPersonAccount = new Account();
        newPersonAccount.Patient_Type__c = 'US';
        newPersonAccount.FirstName = 'Fred';
        newPersonAccount.LastName = 'Smith';
        newPersonAccount.RecordTypeId = personAccountRecordTypeId;
        newPersonAccount.Active_Enrollment__pc = true;
        newPersonAccount.IsActive = true;
        insert newPersonAccount;

        newPersonAccount.Patient_Status__pc = 'Active';
        update newPersonAccount;

        CareProgramEnrollee careProgramEnrollee = new CareProgramEnrollee(
            Name = 'Fred - Test',
            AccountId = newPersonAccount.Id,
            Status = 'Pending',
            Sub_Status__c = 'New Enrollment',
            PA_Consent_Status__c = 'Active',
            CareProgramId = cprogram.Id
        );
        insert careProgramEnrollee;

        MemberPlan mem = new MemberPlan(
            Name = 'Demo',
            MemberNumber = '123sds',
            Status = 'Active',
            J_PolicyNumber__c = '123',
            J_Role__c = 'Primary',
            J_InsuranceType__c = 'Commercial',
            MemberId = newPersonAccount.Id
        );
        insert mem;

        CarePreauth priorAuth = new CarePreauth(
            Authorization_Number__c = 'PA12345',
            Name = 'demo',
            MemberPlanId = mem.Id
        );
        insert priorAuth;

        EmailMessage testEmailMessage = new EmailMessage(
            Subject = 'Internal interaction',
            ToAddress = 'test@example.com',
            MessageDate = System.now(),
            HtmlBody = '<html><body><p>This is a test HTML body.</p></body></html>',
            RelatedToId = priorAuth.Id
        );
        insert testEmailMessage;

        List<Email_Data__c> emailDataList = [
            SELECT Id, Subject__c, Statuses__c, To_Address__c, Send_Date_Time__c,
                   Sent_email_ID__c, Messages__c, Related_To__c, Prior_Authorization__c
            FROM Email_Data__c WHERE Sent_email_ID__c = :testEmailMessage.Id
        ];
        System.assertEquals(1, emailDataList.size(), 'EmailData record was created');
        if (!emailDataList.isEmpty()) {
        Email_Data__c emailData = emailDataList[0];
        System.assertEquals(testEmailMessage.Subject, emailData.Subject__c, 'Subject is Internal interaction');
        System.assertEquals(testEmailMessage.ToAddress, emailData.To_Address__c, 'ToAddress is test@example.com');
        System.assertEquals(testEmailMessage.MessageDate, emailData.Send_Date_Time__c, 'Message Date is current date and time');
        System.assertEquals(testEmailMessage.Id, emailData.Sent_email_ID__c, 'Sent email ID matches');
        System.assertEquals(priorAuth.Id, emailData.Prior_Authorization__c, 'Related to Prior Authorization');
        }
    }
}