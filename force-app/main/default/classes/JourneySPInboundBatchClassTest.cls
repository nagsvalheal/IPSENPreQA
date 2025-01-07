@isTest
public class JourneySPInboundBatchClassTest {
	@TestSetup
    static void makeData() {

        UserRole ccRole = [SELECT Id FROM UserRole WHERE DeveloperName = 'Care_Coordinator'];
        User u = new User(
            Alias = 'jStand',
            Email = 'standarduser@testorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'AbcdTest',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = J_ObjectUtils.getProfileIdByName(J_ObjectUtils.PROFILE_NAME_STANDARD_JOURNEYS_USER),
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = J_TestUtils.USERNAME_TEST_CC
            ,UserRoleId = ccRole.Id
        );
        insert u;
        System.runAs(u) {
            
            List<J_Territory__c> lTerritory = new List<J_Territory__c>();
            J_Territory__c territoryCC = new J_Territory__c(J_Active__c = true,
                                                            J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
                                                            J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
                                                            J_TerritoryCode__c = 'test CC',
                                                            J_States__c = 'test 1',
                                                            Name = J_TestUtils.TERRITORY_NAME_CC
                                                            //,OwnerId = u.id
                                                           );
            lTerritory.add(territoryCC);
            
            J_Territory__c territoryPEL = new J_Territory__c(J_Active__c = true,
                                                             J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
                                                             J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
                                                             J_TerritoryCode__c = 'test PEL',
                                                             J_States__c = 'test 2',
                                                             Name = J_TestUtils.TERRITORY_NAME_PEL
                                                            );
            lTerritory.add(territoryPEL);
            
            insert lTerritory;
           }  
    }
    @isTest
    static void batchClassUpdateTest()
    {
        //Create Patient
        Account patient = new Account(
            LastName = J_TestUtils.PATIENT_LAST_NAME,
            FirstName = 'patient_last',
            RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME, true),
            J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
            PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
            PersonMailingStreet = J_TestUtils.STREET_MAILING,
            PersonMailingCity = 'City',
            PersonMailingState = 'Kansas',
            Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE
        );
        insert patient;
            
        //Create CareProgram
        CareProgram cp = new CareProgram(Name = 'Test Care Program',
                                         StartDate = Date.today(),
                                         EndDate = Date.today().addDays(1),
                                         Status = 'Active'
                                        );
        insert cp;
            
        //Create CareProgramEnrollee
        CareProgramEnrollee cpEnrollee = new CareProgramEnrollee(Name = 'Test Enrollee',
                                                          CareProgramId = CP.id,
                                                          Status = 'Pending',
                                                          Sub_Status__c= 'New Enrollment',
                                                          PA_Consent_Status__c = 'Active',
                                                          AccountId = patient.id
                                                         );
        insert cpEnrollee;
        
        CareProgramEnrollee cpe = [SELECT Id, AccountId, Enrollee_ID__c FROM CareProgramEnrollee WHERE Id = :cpEnrollee.Id];
        System.assertEquals(patient.Id, cpe.AccountId, 'Enrollee should be linked to the correct patient.');
        
        List<J_SP_Inbound__c> inboundList = new List<J_SP_Inbound__c>();
        
        J_SP_Inbound__c inbound1 = new J_SP_Inbound__c();
        inbound1.J_Record_type__c = 'Shipment';
        inbound1.J_Claim_CoPay_Applied__c = 'Y';
        inbound1.J_Claim_Co_Ins_percent__c = 100;
        inbound1.J_Claim_OOP_Met__c = 'Y';
        inbound1.J_Claim_PPayer_Paid_Amt__c = 353;
        inbound1.J_Claim_Pt_Paid_Amt__c = 353;
        inbound1.J_Claim_Type__c = 'Medical';
        inbound1.J_HCP_FirstName__c = 'Test First';
        inbound1.J_HCP_LastName__c = 'Test Last';
        inbound1.J_HCP_Location__c = 'NY';
        inbound1.J_HCP_NPI__c = 'NPI1';
        inbound1.J_HUB_Patient_ID__c = 'Hub1';
        inbound1.J_INS_PP_Group_ID__c = 'PPSGP1';
        inbound1.J_INS_PP_ID__c ='INSPP2';
        inbound1.J_INS_PP_PBM__c = 'INSPBM1';
        inbound1.J_INS_PP_Plan_Name__c = 'Plan 1';
        inbound1.J_INS_PP_Type__c = 'Commercial';
        inbound1.J_INS_SecP_BIN__c = 'INS SEC 1';
        inbound1.J_INS_SecP_Group_ID__c = 'SEC GP1';
        inbound1.J_INS_SecP_Name__c = 'SEC PNAME1';
        inbound1.J_INS_SecP_PCN__c = 'INS PCN1';
        inbound1.J_INS_SecP_Plan_Name__c = 'SEC PLAN NAME 1';
        inbound1.J_Journey_Patient_Id__c = patient.J_Patient_ID__c;
        inbound1.J_PA_Req__c = 'Y';
        inbound1.J_Product_Name__c = 'SOHONOS DAILY DOSE';
        inbound1.J_RX_Day_Supply__c = 1111.0000;
        inbound1.J_RX_Dosage_Type__c = 'Chronic';
        inbound1.J_RX_Fill__c = 11111;
        inbound1.J_RX_NDC__c = '123456';
        inbound1.J_RX_Num__c = 'RX1';
        inbound1.J_RX_Qty__c = 11113;
        inbound1.J_RX_Refil_Remaining__c = 11112;
        inbound1.J_RX_Shipment_ID__c = 'RXSHIP1';
        inbound1.J_RX_Shipment_Type__c = 'COM';
        inbound1.J_RX_UOM__c = 'mg'; //Milligram (mg)
        inbound1.J_SP_Loc_NCPDP__c = 'LocationNDP1';
        inbound1.J_SP_Patient_Id__c = 'PAT1';
        inbound1.J_SP_Unique_Id__c = 'Unique1';
        inbound1.J_SR__c = 'SR2';
        inbound1.J_Status__c = 'Active';
        inbound1.J_Sub_Status__c = 'Val';
        inbound1.J_Import_Status__c='Created';
        inbound1.Enrollee_ID__c = cpe.Enrollee_ID__c;
        inbound1.J_SP_Resta_Flg__c = 'Y';
        inbound1.J_Claim_CoPay_Elg__c ='Y';
        inbound1.J_INS_SecP_Type__c='Cash';
        inbound1.J_INS_SecP_Name__c ='test';
        inbound1.J_INS_SecP_State__c='test';
        inboundList.add(inbound1);
        
        J_SP_Inbound__c inbound2 = new J_SP_Inbound__c();
        inbound2.J_Record_type__c = 'Status';
        inbound2.J_Claim_CoPay_Applied__c = 'N';
        inbound2.J_Claim_Co_Ins_percent__c = 200;
        inbound2.J_Claim_OOP_Met__c = 'N';
        inbound2.J_Claim_PPayer_Paid_Amt__c = 353;
        inbound2.J_Claim_Pt_Paid_Amt__c = 3534;
        inbound2.J_Claim_Type__c = 'Pharmacy';
        inbound2.J_HCP_FirstName__c = 'Test First';
        inbound2.J_HCP_LastName__c = 'Test Last';
        inbound2.J_HCP_Location__c = 'NY';
        inbound2.J_HCP_NPI__c = 'NPI2';
        inbound2.J_HUB_Patient_ID__c = 'Hub2';
        inbound2.J_INS_PP_Group_ID__c = 'PPSGP2';
        inbound2.J_INS_PP_ID__c ='INSPP1';
        inbound2.J_INS_PP_PBM__c = 'INSPBM2';
        inbound2.J_INS_PP_Plan_Name__c = 'Plan 2';
        inbound2.J_INS_PP_Type__c = 'Cash';
        inbound2.J_INS_SecP_BIN__c = 'INS SEC 2';
        inbound2.J_INS_SecP_Group_ID__c = 'SEC GP2';
        inbound2.J_INS_SecP_Name__c = 'SEC PNAME2';
        inbound2.J_INS_SecP_PCN__c = 'INS PCN2';
        inbound2.J_INS_SecP_Plan_Name__c = 'SEC PLAN NAME 2';
        inbound2.J_Journey_Patient_Id__c = patient.J_Patient_ID__c;
        inbound2.J_PA_Req__c = 'Y';
        inbound2.J_Product_Name__c = 'Sohonos';
        inbound2.J_RX_Day_Supply__c = 2222.0000;
        inbound2.J_RX_Dosage_Type__c = 'Chronic';
        inbound2.J_RX_Fill__c = 22222;
        inbound2.J_RX_NDC__c = 'RX NDC1';
        inbound2.J_RX_Num__c = 'RX2';
        inbound2.J_RX_Qty__c = 11223;
        inbound2.J_RX_Refil_Remaining__c = 11122;
        inbound2.J_RX_Shipment_ID__c = 'RXSHIP2';
        inbound2.J_RX_Shipment_Type__c = 'PAP';
        inbound2.J_RX_UOM__c = 'Milligram (mg)';
       	inbound2.J_SP_Loc_NCPDP__c = 'LocationNDP2';
        inbound2.J_SP_Patient_Id__c = 'PAT2';
        inbound2.J_SP_Unique_Id__c = 'Unique2';
        inbound2.J_SR__c = 'SR2';
       	inbound2.J_Status__c = 'Active';
        inbound2.J_Sub_Status__c = 'Val';
        inbound2.J_Import_Status__c='Created';
        inbound2.Enrollee_ID__c = cpe.Enrollee_ID__c;
        inbound2.J_SP_Resta_Flg__c = 'N';
        inbound2.J_Claim_CoPay_Elg__c ='N';
        inboundList.add(inbound2);
        
        /*For Failure NDC Code non numeric*/
        J_SP_Inbound__c inbound3 = new J_SP_Inbound__c();
        inbound3.J_Record_type__c = 'Shipment';
        inbound3.J_Claim_CoPay_Applied__c = 'Y';
        inbound3.J_Claim_Co_Ins_percent__c = 100;
        inbound3.J_Claim_OOP_Met__c = 'Y';
        inbound3.J_Claim_PPayer_Paid_Amt__c = 353;
        inbound3.J_Claim_Pt_Paid_Amt__c = 353;
        inbound3.J_Claim_Type__c = 'Medical';
        inbound3.J_HCP_FirstName__c = 'Test First';
        inbound3.J_HCP_LastName__c = 'Test Last';
        inbound3.J_HCP_Location__c = 'NY';
        inbound3.J_HCP_NPI__c = 'NPI1';
        inbound3.J_HUB_Patient_ID__c = 'Hub1';
        inbound3.J_INS_PP_Group_ID__c = 'PPSGP1';
        inbound3.J_INS_PP_ID__c ='INSPP2';
        inbound3.J_INS_PP_PBM__c = 'INSPBM1';
        inbound3.J_INS_PP_Plan_Name__c = 'Plan 1';
        inbound3.J_INS_PP_Type__c = 'Commercial';
        inbound3.J_INS_SecP_BIN__c = 'INS SEC 1';
        inbound3.J_INS_SecP_Group_ID__c = 'SEC GP1';
        inbound3.J_INS_SecP_Name__c = 'SEC PNAME1';
        inbound3.J_INS_SecP_PCN__c = 'INS PCN1';
        inbound3.J_INS_SecP_Plan_Name__c = 'SEC PLAN NAME 1';
        inbound3.J_Journey_Patient_Id__c = patient.J_Patient_ID__c;
        inbound3.J_PA_Req__c = 'Y';
        inbound3.J_Product_Name__c = 'SOHONOS DAILY DOSE';
        inbound3.J_RX_Day_Supply__c = 1111.0000;
        inbound3.J_RX_Dosage_Type__c = 'Chronic';
        inbound3.J_RX_Fill__c = 11111;
        inbound3.J_RX_NDC__c = 'RX NDC1';
        inbound3.J_RX_Num__c = 'RX1';
        inbound3.J_RX_Qty__c = 11113;
        inbound3.J_RX_Refil_Remaining__c = 11112;
        inbound3.J_RX_Shipment_ID__c = 'RXSHIP1';
        inbound3.J_RX_Shipment_Type__c = 'COM';
        inbound3.J_RX_UOM__c = 'ml'; //Milliliter (ml)
        inbound3.J_SP_Loc_NCPDP__c = 'LocationNDP1';
        inbound3.J_SP_Patient_Id__c = 'PAT1';
        inbound3.J_SP_Unique_Id__c = 'Unique1';
        inbound3.J_SR__c = 'SR2';
        inbound3.J_Status__c = 'Active';
        inbound3.J_Sub_Status__c = 'Val';
        inbound3.J_Import_Status__c='Created';
        inbound3.Enrollee_ID__c = cpe.Enrollee_ID__c;
        inbound3.J_SP_Resta_Flg__c = 'Y';
        inbound3.J_Claim_CoPay_Elg__c ='Y';
        inbound3.J_INS_SecP_Type__c='Cash';
        inbound3.J_INS_SecP_Name__c ='test';
        inbound3.J_INS_SecP_State__c='test';
        inboundList.add(inbound3);
        
        insert inboundList;
        List<J_SP_Inbound__c> insertedRecords = [SELECT Id, J_Status__c FROM J_SP_Inbound__c WHERE J_Journey_Patient_Id__c = :patient.J_Patient_ID__c];
        System.assertEquals(3, insertedRecords.size(), 'Three inbound records should have been created.');
        
        Test.startTest();
            JourneySPInboundBatchClass ba= new JourneySPInboundBatchClass();
            Id jobid= Database.executeBatch(ba,5);
        Test.stopTest();
        
        List<J_SP_Inbound__c> processedRecords = [SELECT Id, J_Status__c FROM J_SP_Inbound__c WHERE Id IN :insertedRecords];
        for (J_SP_Inbound__c record : processedRecords) {
        System.assertEquals('Active', record.J_Status__c, 'Inbound record should have been processed by the batch.');
        }
    }
}