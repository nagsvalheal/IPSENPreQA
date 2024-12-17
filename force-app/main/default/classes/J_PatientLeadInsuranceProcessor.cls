public without sharing class J_PatientLeadInsuranceProcessor {
    public static void processLeadInsurance(Map<Id, Lead> mapLead, List<Id> leadIds, Id accountId) {
        if (mapLead.get(leadIds[0]).J_Patient_Is_Patient_Insured__c == 'Yes') {
            system.debug('Lead Convert, ***********Get Insurance Begin*****************');
            
            // Fetch Insurance Information
            List<Lead_Insurance_Information__c> lstInsurance = fetchLeadInsurance(leadIds);
            system.debug('Lead Convert, lstInsurance: ' + lstInsurance + ' Size: ' + lstInsurance.size());
            
            //if (lstInsurance == null || lstInsurance.isEmpty()) return;
    
            // Fetch Record Type for Payer
            RecordType payerRecType = fetchPayerRecordType();
    
            // Separate Primary and Secondary Insurance
            List<Lead_Insurance_Information__c> primaryInsList = new List<Lead_Insurance_Information__c>();
            List<Lead_Insurance_Information__c> secondaryInsList = new List<Lead_Insurance_Information__c>();
            separateInsuranceRecords(lstInsurance, primaryInsList, secondaryInsList);
    
            // Process Primary and Secondary Insurance
            InsuranceData primaryInsurance = processPrimaryInsurance(primaryInsList, mapLead.get(leadIds[0]));
            InsuranceData secondaryInsurance = processSecondaryInsurance(secondaryInsList, mapLead.get(leadIds[0]));
    
            // Handle Payer Accounts
            List<Account> lstPayer = new List<Account>();
            Id payer1 = handlePayerAccount(primaryInsurance, payerRecType, lstPayer);
            Id payer2 = handlePayerAccount(secondaryInsurance, payerRecType, lstPayer);
    
            // Insert New Payers
            // if (!lstPayer.isEmpty() && Schema.sObjectType.Account.fields.Name.isCreateable()) {
            //     insert lstPayer;
            // }
    
            // Process Member Plans
            List<MemberPlan> planList = new List<MemberPlan>();

            if (primaryInsurance != null && payer1 != null) {
                system.debug('primaryInsurance'+primaryInsurance);
                system.debug('payer1'+payer1);
                processMemberPlan(planList, primaryInsurance, payer1, 'Primary', accountId, primaryInsList);
            }
            if (secondaryInsurance != null && payer2 != null) {
                processMemberPlan(planList, secondaryInsurance, payer2, 'Secondary', accountId, secondaryInsList);
            }
          
        
    // Process Member Plans
    //processMemberPlan(planList, primaryInsurance, payer1, 'Primary', accountId, primaryInsList);
    //processMemberPlan(planList, secondaryInsurance, payer2, 'Secondary', accountId, secondaryInsList);
    
    
    
            // Insert Member Plans
            if (!planList.isEmpty() && Schema.sObjectType.MemberPlan.fields.Name.isCreateable()) {
                insert planList;
            }
        }
    }
    
    private static List<Lead_Insurance_Information__c> fetchLeadInsurance(List<Id> leadIds) {
        return [SELECT id,Lead__c,Is_Primary_Insurance__c,Insurance_Co__c,Insurance_Co_Phone__c,Subscriber_Policy_ID__c,Policy_Employer_Group__c,Policyholder_same_as_patient__c,Policyholder_First_Name__c,Policyholder_Last_Name__c,Policyholder_Date_of_Birth__c,
        IsPhysicianaParticipatingProvider__c,Pharmacy_Benefit_Manager__c,RxBIN__c,RxPCN__c,RxGroup__c,RxID__c
                FROM Lead_Insurance_Information__c 
                WHERE Lead__c = :leadIds WITH SECURITY_ENFORCED];
    }
    
    private static RecordType fetchPayerRecordType() {
        system.debug('recordtype');
        return [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Journeys Payer' LIMIT 1];
    //    String fields = 'Id, Name';
    
    //    // Define the conditions for the query
    //    String conditions = 'SObjectType = \'Account\' AND Name = \'Journeys Payer\' LIMIT 1';
       
    //    // Execute the query using the utility method
    //    List<SObject> recordTypeList = COM_QueryUtility.executeQuery('RecordType', fields, conditions, false);
       
    //    // Ensure the result is not empty and return the first record as RecordType
    //    if (!recordTypeList.isEmpty()) {
    //        return (RecordType)recordTypeList[0]; // Cast the first SObject to RecordType
    //    }
       
    //    // Return null if no matching record is found
    //    return null;
    }
    
    private static void separateInsuranceRecords(List<Lead_Insurance_Information__c> lstInsurance,
                                          List<Lead_Insurance_Information__c> primaryInsList,
                                          List<Lead_Insurance_Information__c> secondaryInsList) {
        for (Lead_Insurance_Information__c ins : lstInsurance) {
            if (ins.Is_Primary_Insurance__c) {
                primaryInsList.add(ins);
            } else if (ins.Insurance_Co__c != null) {
                secondaryInsList.add(ins);
            }
        }
    }
    
    private static InsuranceData processPrimaryInsurance(List<Lead_Insurance_Information__c> primaryInsList, Lead lead) {
        if (primaryInsList.isEmpty()) {
            system.debug('processPrimaryInsurance');
            return null;
        }
        return createInsuranceData(primaryInsList[0], lead);
    
        // Lead_Insurance_Information__c primaryInsurance = primaryInsList[0];
        // InsuranceData data = new InsuranceData();
        // data.company = primaryInsurance.Insurance_Co__c;
        // data.phone = primaryInsurance.Insurance_Co_Phone__c;
        // data.policyId = primaryInsurance.Subscriber_Policy_ID__c;
        // data.policyGroup = primaryInsurance.Policy_Employer_Group__c;
        // data.policyHolderName = (primaryInsurance.Policyholder_same_as_patient__c == 'Yes') ? lead.Name :
        //                         (primaryInsurance.Policyholder_First_Name__c + ' ' + primaryInsurance.Policyholder_Last_Name__c).trim();
        // data.policyHolderDOB = (primaryInsurance.Policyholder_same_as_patient__c == 'Yes') ? lead.J_Date_of_Birth__c : primaryInsurance.Policyholder_Date_of_Birth__c;
    
        // return data;
    }
    
    private static InsuranceData processSecondaryInsurance(List<Lead_Insurance_Information__c> secondaryInsList, Lead lead) {
        if (secondaryInsList.isEmpty()) {
            system.debug('processSecondaryInsurance');
            return null;
        }
        return createInsuranceData(secondaryInsList[0], lead);
    
        // Lead_Insurance_Information__c secondaryInsurance = secondaryInsList[0];
        // InsuranceData data = new InsuranceData();
        // data.company = secondaryInsurance.Insurance_Co__c;
        // data.phone = secondaryInsurance.Insurance_Co_Phone__c;
        // data.policyId = secondaryInsurance.Subscriber_Policy_ID__c;
        // data.policyGroup = secondaryInsurance.Policy_Employer_Group__c;
        // data.policyHolderName = (secondaryInsurance.Policyholder_same_as_patient__c == 'Yes') ? lead.Name :
        //                         (secondaryInsurance.Policyholder_First_Name__c + ' ' + secondaryInsurance.Policyholder_Last_Name__c).trim();
        // data.policyHolderDOB = (secondaryInsurance.Policyholder_same_as_patient__c == 'Yes') ? lead.J_Date_of_Birth__c : secondaryInsurance.Policyholder_Date_of_Birth__c;
    
        // return data;
    }

    private static InsuranceData createInsuranceData(Lead_Insurance_Information__c insurance, Lead lead) {
        InsuranceData data = new InsuranceData();
        data.company = insurance.Insurance_Co__c;
        data.phone = insurance.Insurance_Co_Phone__c;
        data.policyId = insurance.Subscriber_Policy_ID__c;
        data.policyGroup = insurance.Policy_Employer_Group__c;
        data.policyHolderName = (insurance.Policyholder_same_as_patient__c == 'Yes') ? lead.Name :
                                (insurance.Policyholder_First_Name__c + ' ' + insurance.Policyholder_Last_Name__c).trim();
        data.policyHolderDOB = (insurance.Policyholder_same_as_patient__c == 'Yes') ? lead.J_Date_of_Birth__c : insurance.Policyholder_Date_of_Birth__c;
        return data;
    }
    
    private static Id handlePayerAccount(InsuranceData insurance, RecordType payerRecType, List<Account> lstPayer) {
        if (insurance == null || insurance.company == null) {
            return null;
        }
    
        Id payerId = checkPayerRecExist(payerRecType, insurance.company);
        if (payerId == null) {
            Account payer = assignPayer(insurance.company, null, payerRecType.Id);
            lstPayer.add(payer);
            system.debug('lstPayer'+lstPayer);
            if (!lstPayer.isEmpty() && Schema.sObjectType.Account.fields.Name.isCreateable()) {
                insert lstPayer;
                payerId = lstPayer[0].Id; // Get the ID of the newly created payer
            }
           // return payer.Id;
        }
        return payerId;
    }
    
    private static void processMemberPlan(List<MemberPlan> planList, InsuranceData insurance, Id payerId, String insuranceType, Id patientId, List<Lead_Insurance_Information__c> insuranceList) {
        system.debug('insuranceList'+insuranceList);
        system.debug('insurance'+insurance);
        system.debug('payerId'+payerId);
        system.debug('insuranceType'+insuranceType);
        if (insurance == null || payerId == null || insuranceList.isEmpty()) {
            System.debug('Skipping MemberPlan creation for ' + insuranceType + ' insurance due to missing data.');
            return;
        }
    
        // MemberPlan plan = assignMemberPlan(
        //     patientId,
        //     payerId,
        //     insurance.phone,
        //     insurance.policyGroup,
        //     insurance.policyHolderName,
        //     insurance.policyHolderDOB,
        //     insurance.policyId,
        //     (insuranceType == 'Primary' ? 'Yes' : 'No'),
        //     insuranceType,
        //     insuranceList
        // );
        J_patientLeadInsuranceWrapper wrapper = new J_patientLeadInsuranceWrapper(
            patientId,
            payerId,
            insurance.phone,
            insurance.policyGroup,
            insurance.policyHolderName,
            insurance.policyHolderDOB,
            insurance.policyId,
            (insuranceType == 'Primary' ? 'Yes' : 'No'),
            insuranceType,
            insuranceList
        );
        MemberPlan plan = assignMemberPlan(wrapper);
    
        planList.add(plan);
        System.debug('MemberPlan created: ' + plan);
    }
    
    
    
    // Helper class for Insurance Data
    public class InsuranceData {
        public String company;
        public String phone;
        public String policyId;
        public String policyGroup;
        public String policyHolderName;
        public Date policyHolderDOB;
    }
    
    public static id checkPayerRecExist(RecordType recTypeId, string name)
    {   
    
        String recordTypeName = recTypeId.Name;
        id recordID;
        if(recordTypeName =='Journeys Payer')
        {
            Account[] acc = [select id, Name from Account where RecordTypeId =:recTypeId.id AND AccountName_Lower__C = :name.toLowerCase() Limit 1];
            recordID = acc.size() == 0 ? null : acc[0].Id ;
        }
        System.debug('Lead Convert,checkPayerRecExist ---------:'+ recordID);
        return recordID;
    }
    
    public static Account assignPayer(string name,string status,string recTypeId)
    {
        Account acc = new Account();
        acc.RecordTypeId=recTypeId;
        acc.Name = name;
        acc.J_PayerStatus__c = 'Active';    
    
        return acc;
    }
    
    public static MemberPlan assignMemberPlan(J_patientLeadInsuranceWrapper wrapper) {
    MemberPlan memberPlan = new MemberPlan();
    memberPlan.MemberId = wrapper.patientId;
    memberPlan.Status = 'Pending';
    memberPlan.J_Role__c = wrapper.insuranceType;
    memberPlan.Name = 'N/A';
    memberPlan.PayerId = wrapper.payerId;
    memberPlan.J_MemberServicesPhoneNumber__c = wrapper.insurancePhone;
    memberPlan.J_PolicyNumber__c = wrapper.policyNo;
    
    if (wrapper.policyHolderName != null) {
    memberPlan.J_PolicyHolderName__c = wrapper.policyHolderName;
    }
    
    memberPlan.J_Policy_Holder_DOB__c = wrapper.policyHolderDOB;
    memberPlan.J_Subscriber_Policy_ID__c = wrapper.subscriberPolicyID;
    
    if (wrapper.relationToPolicyHolder == 'Yes') {
    memberPlan.J_Relation_to_Policy_Holder__c = 'Self';
    }
    
    // Populate additional details from the insurance list (if available)
    if (!wrapper.insuranceList.isEmpty()) {
    Lead_Insurance_Information__c insuranceDetails = wrapper.insuranceList[0];
    memberPlan.J_IsPhysicianaParticipatingProvider__c = insuranceDetails.IsPhysicianaParticipatingProvider__c;
    memberPlan.J_PBM_Name__c = insuranceDetails.Pharmacy_Benefit_Manager__c;
    memberPlan.PBM_Bin__c = insuranceDetails.RxBIN__c;
    memberPlan.PBM_PCN__c = insuranceDetails.RxPCN__c;
    memberPlan.PBM_Group__c = insuranceDetails.RxGroup__c;
    memberPlan.PBM_ID__c = insuranceDetails.RxID__c;
    }
    
    System.debug('MemberPlan Assigned: ' + memberPlan);
    return memberPlan;
    }
    

}