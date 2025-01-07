@isTest
public class ConvertLeadToPatientTest {
    @isTest
    public static void convertLeadTest(){
        
        //Create Cre Program
        CareProgram cp = new CareProgram(
            Name = 'Test Care Program',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(1),
            Status = 'Active'
        );
		insert cp;
        
        Lead le = new lead(FirstName = 'TestName',LastName='LastName'+datetime.now(),J_Date_of_Birth__c=system.today()-500,
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
                                           First_Name__c = 'TestNameCG',Last_Name__c='LastNameCG'+datetime.now(),
                                           Phone__c='1234567890',Email__c='test@test.com',Relationship_To_Patient__c ='Other',Enter_Relationship__c ='Other');
        lstcc.add(cc);
        cc = new Lead_Consented_Contact__c(Lead__c = le.id,Parent_Legal_Consent__c = false,
                                           First_Name__c = 'TestNameCC1',Last_Name__c='LastNameCC1'+datetime.now(),
                                           Phone__c='1234567890',Email__c='test@test.com',Relationship_To_Patient__c ='Other',Enter_Relationship__c ='Other');
        lstcc.add(cc);
        cc = new Lead_Consented_Contact__c(Lead__c = le.id,Parent_Legal_Consent__c = false,
                                           First_Name__c = 'TestNameCC2',Last_Name__c='LastNameCC2'+datetime.now(),
                                           Phone__c='1234567890',Email__c='test@test.com',Relationship_To_Patient__c ='Other',Enter_Relationship__c ='Other');
        lstcc.add(cc);
        cc = new Lead_Consented_Contact__c(Lead__c = le.id,Parent_Legal_Consent__c = false,
                                           First_Name__c = 'TestNameCC3',Last_Name__c='LastNameCC3'+datetime.now(),
                                           Phone__c='1234567890',Email__c='test@test.com',Relationship_To_Patient__c ='Other',Enter_Relationship__c ='Other');
        
        lstcc.add(cc);
        insert lstcc;

        Lead_Consent_For_Information__c consentInfo = new Lead_Consent_For_Information__c (
            Lead__c = le.id,Signature_of_Patient_or_Parent_LG__c= true,Signatured_Date__c=system.today(),Type__c='Use of Person Health Information' );
        insert consentInfo;
        
                Lead_Consent_For_Information__c consentInfo2 = new Lead_Consent_For_Information__c (
            Lead__c = le.id,Signature_of_Patient_or_Parent_LG__c= true,Signatured_Date__c=system.today(),Type__c='Use of Genetic Information' );
        insert consentInfo2;
        
        List<Lead_Insurance_Information__c> lstInsurance = new List<Lead_Insurance_Information__c> ();
        Lead_Insurance_Information__c ins;
        ins = new Lead_Insurance_Information__c(Lead__c = le.id,Is_Primary_Insurance__c =true,Insurance_Co__c ='test Insurance Company',Insurance_Co_Phone__c='123456789',
                                                Subscriber_Policy_ID__c='123456789',Policy_Employer_Group__c='123456789',
                                                Policyholder_same_as_patient__c ='Yes',Policyholder_First_Name__c ='PolicyholderFname',Policyholder_Last_Name__c='PolicyholderLName',
                                                Policyholder_Date_of_Birth__c = system.today()-500);
        lstInsurance.add(ins);
        ins = new Lead_Insurance_Information__c(Lead__c = le.id,Is_Primary_Insurance__c =false,Insurance_Co__c ='test Insurance Company',Insurance_Co_Phone__c='123456789',
                                                Subscriber_Policy_ID__c='324456789',Policy_Employer_Group__c='543256789',
                                                Policyholder_same_as_patient__c ='Yes',Policyholder_First_Name__c ='PolicyholderFname',Policyholder_Last_Name__c='PolicyholderLName',
                                                Policyholder_Date_of_Birth__c = system.today()-500);
        
        lstInsurance.add(ins);
        insert lstInsurance ;
                
        test.startTest();
        ConvertLeadToPatient.convertLead(new list<id> {le.id});
        //list<Account> ac = [select id from Account];
        test.stopTest();
        //system.assert(ac.size()==1, 'Account created after Lead creation');
    }
    
    @isTest
    public static void convertHCPLeadTest(){
        //Create Cre Program
        CareProgram cp = new CareProgram(
            Name = 'Test HCP Care Program',
            StartDate = Date.today(),
            EndDate = Date.today().addDays(1),
            Status = 'Active'
        );
		insert cp;
        
        Product2 p = new Product2 (Name ='Product',ProductCode ='Test ProductCode',NDC_Code__c ='1234567898',Dosage__c = '2.5',QuantityUnitOfMeasure='Milligrams (mg)',IsActive=true);
        insert p;
        
        CareProgramProduct cpp = new CareProgramProduct(Name='CareProgramProduct', CareProgramId = cp.Id,ProductId = p.Id, Status ='Active');
        insert cpp;
        
        Lead le = new lead(FirstName = 'HCPFName',LastName='HCPLName'+datetime.now(),J_Date_of_Birth__c=system.today()-6600,
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

        
        Lead_Prescription_Information__c prescription = new Lead_Prescription_Information__c(Lead__c= le.id,Drug__c ='Drug',Dosage__c='2.5', Dosage_Unit__c='mg', Dosage_Type__c = 'Chronic',
                                                                                             Sig__c='1',Frequency__c= 2,No_of_Refills__c= 3, Directions__c = 'By mouth daily with food', Total_Daily_Quantity__c = 2,
                                                                                            Care_Program_Product__c = cpp.Id);
        insert prescription;
        
        // Required to create Patient Medication Dosage
        CodeSetBundle code = new CodeSetBundle(Name='Sohonos');
        insert code; 
        test.startTest();
        System.runAs([SELECT Id FROM User WHERE Id = :UserInfo.getUserId()][0])
        {
            ConvertLeadToPatient.convertLead(new list<id> {le.id});
        }
        //list<Account> ac = [select id from Account];
        //system.assert(ac.size()==1, 'Account created after Lead creation');
        test.stopTest();
    }
    
}