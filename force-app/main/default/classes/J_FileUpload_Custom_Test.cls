@isTest
public class J_FileUpload_Custom_Test {
    @isTest
     static void testFileUpload(){
        Test.startTest();

         //Create Patient
         Account patient = new Account(
             LastName = J_TestUtils.PATIENT_LAST_NAME,
             FirstName = 'patient_last',
             RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
             J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
             PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
             PersonMailingStreet = J_TestUtils.STREET_MAILING,
             PersonMailingCity = 'Coimbatore',
             PersonMailingCountry='Australia',
             PersonMailingState = 'Queensland',
             PersonEmail = 'test@test.com'
         );
         insert patient;
         // create a care program
         CareProgram cp = new CareProgram(
             Name = 'Care Program',
             StartDate = system.today(),
             Status = 'Active'
         );
         insert cp;
        
        // create enrollee
        CareProgramEnrollee cpEnrollee = new CareProgramEnrollee(
            Name = 'Enrollee Test',
            Status = 'Pending',
            Sub_Status__c='	New Enrollment',
            PA_Consent_Status__c = 'Active',
            CareProgramId = cp.id,
            Clinical_trial_participant__c = 'Yes',
            AccountId = patient.id
        );
        insert cpEnrollee;
         
          MemberPlan mp = new MemberPlan(
            Name        = 'MEMBER_PLAN_NAME',
            MemberId    = patient.Id,
            Status = 'Active',
            J_InsuranceType__c = 'Commercial',
            J_PolicyNumber__c = '001',
            J_Role__c = 'Primary'
        );
        insert mp;
         CoverageBenefit cb = new CoverageBenefit (
            Name            =' COVERAGE_BENEFIT_PLAN_NAME',
            MemberPlanId    = mp.Id,
            //MemberId = patienten.Id,
            Care_Program_Enrollee__c = cpEnrollee.id,
            J_CoverageBenefitStatus__c = 'Active'
        );
        insert cb;

        ContentVersion content= new ContentVersion(); 
        content.Title='test crm patient - Benefit Investigation Summary (9).PDF'; 
        content.PathOnClient='/' + content.Title + '.PDF'; 
        //Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData = Blob.valueOf('Test Content');
        //content.LinkedEntityId=cb.id;
        content.origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=cb.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        //contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
             
        insert contentlink;
        J_FileUpload_Custom.uploadFile('base64', 'test crm patient - Benefit Investigation Summary (9).PDF', cb.id);
        J_FileUpload_Custom.getLinkedFile(cb.id);
      	J_FileUpload_Custom.createContentDistribution(content.id);
        Test.stopTest();
          // Assert that the ContentDocumentLink is correctly linked to the CoverageBenefit
          ContentDocumentLink resultContentLink = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :cb.Id LIMIT 1];
          System.assertEquals(cb.Id, resultContentLink.LinkedEntityId, 'The ContentDocumentLink should be correctly linked to the CoverageBenefit.');
        
    }
       
}