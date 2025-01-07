@isTest
public class ConvertLeadToPatientMergeTest {
    
    @TestSetup
    static void makeData(){
        //Create Account
        Account patient = new Account(
            FirstName = 'TFNameM',
            LastName = 'TLNameM'+datetime.now(),
            PersonBirthdate = system.today()-6666,
            RecordTypeId    = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = 'Mailing',
            PersonMailingPostalCode = '10023',
            PersonMailingStreet = 'Test Street',
            PersonMailingCity = 'Test City',
            PersonMailingState = 'Arizona',
            PersonMailingCountry = 'United States',
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE
        );
        insert patient;
        
        //Create Cre Program
        CareProgram cp = new CareProgram(
            Name = 'Test Care Program',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(1),
            Status = 'Active'
        );
		insert cp;
        
        // Required to create Patient Medication Dosage
        CodeSetBundle code = new CodeSetBundle(Name='Sohonos');
        insert code; 
    }
    
    @isTest
    public static void convertLeadTest()
    {
        Account patient = [SELECT ID from Account WHERE FirstName = 'TFNameM' LIMIT 1];
        CareProgram cp = [SELECT ID from CareProgram LIMIT 1];
        
        Lead le = new lead(FirstName = 'TFNMerge',LastName='LNMerge'+datetime.now(),J_Date_of_Birth__c=system.today()-6666,
                           Street='Address 1',City='City1',State='Texas',PostalCode='65434',
                           J_Prescriber_Preferred_Method_of_Contact__c='Phone', 
                           Other_diagnosis__c = 'Typhoid ',
                           J_Secondary_ICD_10_Code__c = 'T123', 
                           J_Cell_Phone__c='1234567890',Preferred_Phone__c='Cell',J_Sex__c='Male',
                           J_Consent_Effective_Date__c =system.today(),Consented_by_Others__c ='Yes',J_Patient_Is_Patient_Insured__c ='Yes',
                           J_Consent_text_message__c ='Yes - I Agree',J_Consent_voice_call__c='Yes - I Agree',J_Consent_email__c='Yes - I Agree',
                           J_Consent_mail__c='Yes - I Agree',J_Consent_marketing_info__c ='No - I Do Not Agree',
                           Care_Program__c = cp.Id,
                           recordtypeid=J_ObjectUtils.getRecordTypeId((J_ObjectUtils.LEAD_PATIENT_RECORD_TYPE),'LEAD'));
        insert le;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = le.FirstName+' '+le.LastName +' - Journeys Enrollment Form',
            PathOnClient = le.FirstName+' '+le.LastName +' - Journeys Enrollment Form.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = testContent.ContentDocumentId;
        newLink.LinkedEntityId = le.Id;        
        insert newLink;
        
        List<Lead_Consented_Contact__c> lstcc = new List<Lead_Consented_Contact__c>();
        Lead_Consented_Contact__c cc ;
        cc = new Lead_Consented_Contact__c(Lead__c = le.id,Parent_Legal_Consent__c = true,
                                           First_Name__c = 'TNMergeCG',Last_Name__c='LastNameMergeCG',
                                           Phone__c='1234567890',Email__c='test@test.com',Relationship_To_Patient__c ='Other',Enter_Relationship__c ='Other');
        lstcc.add(cc);
        cc = new Lead_Consented_Contact__c(Lead__c = le.id,Parent_Legal_Consent__c = false,
                                           First_Name__c = 'TNMergeCC1',Last_Name__c='LastNameMergeCC1'+datetime.now(),
                                           Phone__c='1234567890',Email__c='test@test.com',Relationship_To_Patient__c ='Other',Enter_Relationship__c ='Other');
        lstcc.add(cc);
        cc = new Lead_Consented_Contact__c(Lead__c = le.id,Parent_Legal_Consent__c = false,
                                           First_Name__c = 'TNMergeCC2',Last_Name__c='LastNameMergeCC2'+datetime.now(),
                                           Phone__c='1234567890',Email__c='test@test.com',Relationship_To_Patient__c ='Other',Enter_Relationship__c ='Other');
        lstcc.add(cc);
        cc = new Lead_Consented_Contact__c(Lead__c = le.id,Parent_Legal_Consent__c = false,
                                           First_Name__c = 'TNMergeCC3',Last_Name__c='LastNameMergeCC3'+datetime.now(),
                                           Phone__c='1234567890',Email__c='test@test.com',Relationship_To_Patient__c ='Other',Enter_Relationship__c ='Other');
        
        lstcc.add(cc);
        insert lstcc;
        test.startTest();
        Lead_Consent_For_Information__c consentInfo = new Lead_Consent_For_Information__c (
            Lead__c = le.id,Signature_of_Patient_or_Parent_LG__c= true,Signatured_Date__c=system.today(),Type__c='Use of Person Health Information' );
        insert consentInfo;
        
        Lead_Consent_For_Information__c consentInfo2 = new Lead_Consent_For_Information__c (
            Lead__c = le.id,Signature_of_Patient_or_Parent_LG__c= true,Signatured_Date__c=system.today(),Type__c='Use of Genetic Information' );
        insert consentInfo2;
        
        List<Lead_Insurance_Information__c> lstInsurance = new List<Lead_Insurance_Information__c> ();
        Lead_Insurance_Information__c ins;
        ins = new Lead_Insurance_Information__c(Lead__c = le.id,Is_Primary_Insurance__c =true,Insurance_Co__c ='test Insurance Company Merge',Insurance_Co_Phone__c='123456789',
                                                Subscriber_Policy_ID__c='123456789',Policy_Employer_Group__c='123456789',
                                                Policyholder_same_as_patient__c ='Yes',Policyholder_First_Name__c ='PolicyholderFname',Policyholder_Last_Name__c='PolicyholderLName',
                                                Policyholder_Date_of_Birth__c = system.today()-500);
        lstInsurance.add(ins);
        ins = new Lead_Insurance_Information__c(Lead__c = le.id,Is_Primary_Insurance__c =false,Insurance_Co__c ='test Insurance Company Merge',Insurance_Co_Phone__c='123456789',
                                                Subscriber_Policy_ID__c='324456789',Policy_Employer_Group__c='543256789',
                                                Policyholder_same_as_patient__c ='Yes',Policyholder_First_Name__c ='PolicyholderFname',Policyholder_Last_Name__c='PolicyholderLName',
                                                Policyholder_Date_of_Birth__c = system.today()-500);
        
        lstInsurance.add(ins);
        insert lstInsurance ;
        
        ConvertLeadToPatientMerge.FlowRequest r = new ConvertLeadToPatientMerge.FlowRequest ();
        r.iLeadID = le.Id;
        r.iAccountID = patient.id;
        
        ConvertLeadToPatientMerge.convertLead(new List<ConvertLeadToPatientMerge.FlowRequest>{r});
        
        // Create a list of iCaregiverData objects
        List<CheckCaregiverRelationship.iCaregiverData> lstRequest = new List<CheckCaregiverRelationship.iCaregiverData>();
        CheckCaregiverRelationship.iCaregiverData caregiverData = new CheckCaregiverRelationship.iCaregiverData();
        caregiverData.iAccount = patient.id;
        caregiverData.iFirstName = 'TestNameMergeCG';
        caregiverData.iLastName = 'LastNameMergeCG';
        caregiverData.iPhone = '123-456-7890';
        caregiverData.iRelationship = 'Parent';
        lstRequest.add(caregiverData);
        
        // Call the CheckExist method
        //List<Id> result = CheckCaregiverRelationship.CheckExist(lstRequest);
        
        //list<Account> ac = [select id from Account LIMIT 1];
        test.stopTest();
        //system.assert(ac.size()==1, 'Account created after Lead creation');
    }
    
    @isTest
    public static void convertHCPLeadTest()
    {
        Account patient = [SELECT ID from Account LIMIT 1];
        CareProgram cp = [SELECT ID from CareProgram LIMIT 1];
        
        Product2 p = new Product2 (Name ='Product',ProductCode ='Test ProductCode',NDC_Code__c ='1234567898',Dosage__c = '2.5',QuantityUnitOfMeasure='Milligrams (mg)',IsActive=true);
        insert p;
        
        CareProgramProduct cpp = new CareProgramProduct(Name='CareProgramProduct', CareProgramId = cp.Id,ProductId = p.Id, Status ='Active');
        insert cpp;
        
        Lead le = new lead(FirstName = 'TestName',LastName='LastName'+datetime.now(),J_Date_of_Birth__c=system.today()-6600,
                           Street='Address 1',City='City1',State='Texas',PostalCode='65434',
                           J_Prescriber_Preferred_Method_of_Contact__c='Phone', 
                           Other_diagnosis__c = 'Typhoid ',
                           J_Secondary_ICD_10_Code__c = 'T123', 
                           J_Cell_Phone__c='1234567890',Preferred_Phone__c='Cell',J_Sex__c='Male',
                           J_Consent_Effective_Date__c =system.today(),Consented_by_Others__c ='Yes',J_Patient_Is_Patient_Insured__c ='Yes',
                           J_Caregiver_Name_HCP__c = 'CGHCPTestName',J_Caregiver_Last_Name_HCP__c = 'CGHCPTestLName',J_Caregiver_Email_HCP__c = 'test@test.com',
                           J_Caregiver_Phone_HCP__c ='1236547896',J_Relationship_to_Patient_HCP__c ='Other',J_Enter_Relationship_HCP__c ='Other',
                           Care_Program__c = cp.Id,
                           recordtypeid=J_ObjectUtils.getRecordTypeId((J_ObjectUtils.LEAD_HCF_RECORD_TYPE),'LEAD'));
        insert le;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = le.FirstName+' '+le.LastName +' - Journeys HCP Enrollment Form',
            PathOnClient = le.FirstName+' '+le.LastName +' - Journeys HCP Enrollment Form.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;
        ContentVersion testContent = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];
        ContentDocumentLink newLink = new ContentDocumentLink();
        newLink.ContentDocumentId = testContent.ContentDocumentId;
        newLink.LinkedEntityId = le.Id;        
        insert newLink;
        
        Lead_Associated_Physician__c physician = new Lead_Associated_Physician__c(
            Lead__c = le.id,Name ='PFname',Last_Name__c='PLname',Preferred_Method_of_Contact__c='Phone',
            Email__c= 'test@test.com',Phone__c='1236547896',Fax__c='1236547896',
            Tax_ID__c='123456789',DEA__c='123456',State_License__c='123456',Medicaid_Provider__c='123456',Medicare_PTAN__c='123456',
            NPI__c='123456',Best_Time_to_Contact__c='Afternoon',Office_Institution__c='123456',Role__c='Speciality',Specialty__c='Genetics',
            Office_Contact_Title__c='Title',Primary_ICD_10_Code__c='123456',Secondary_ICD_10_Code__c='123456',
            Physician_Address__CountryCode__s='US',Physician_Address__Street__s='123', Physician_Address__City__s='City', 
            Physician_Address__StateCode__s ='AL',  Physician_Address__PostalCode__s='45678');
        insert physician;
        
        
        //Enrollee_HCP__c eHCP = new Enrollee_HCP__c(Care_Program_Enrollee__c = le.id, HCP__c = physician.id, Status__c = 'Active',Name = 'Enrollee HCP');

        
        Lead_Prescription_Information__c prescription = new Lead_Prescription_Information__c(Lead__c= le.id,Drug__c ='Drug',Dosage__c='2.5', Dosage_Unit__c='mg', Directions__c = 'By mouth daily with food',
                                                                                             Dosage_Type__c = 'Chronic', Sig__c='1',Frequency__c=2, No_of_Refills__c=3, Total_Daily_Quantity__c = 2,
                                                                                            Care_Program_Product__c = cpp.Id);
        insert prescription;
        
        
        ConvertLeadToPatientMerge.FlowRequest r = new ConvertLeadToPatientMerge.FlowRequest ();
        r.iLeadID = le.Id;
        r.iAccountID = patient.id;
        
        test.startTest();
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0])
        {
            ConvertLeadToPatientMerge.convertLead(new List<ConvertLeadToPatientMerge.FlowRequest>{r});
        }
        //list<Account> ac = [select id from Account LIMIT 1];
        test.stopTest();
    }

}