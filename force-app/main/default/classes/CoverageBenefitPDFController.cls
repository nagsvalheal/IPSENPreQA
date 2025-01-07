/**
* @description Controller for the Coverage Benefit PDF Visualforce Page.
* Handles data retrieval and processing of insurance-related information.
*/
public with sharing class CoverageBenefitPDFController {
    private Id enId; // Initializes Enrollee ID
    /** @description Represents the CoverageBenefit details for the patient */
    public CoverageBenefit ic { get; set; }
    
    /** @description Stores the Patient's Medication Dosage details */
    public PatientMedicationDosage dosing { get; set; }
    
    /** @description Stores the patient's Date of Birth */
    public string patientDob { get; set; }
    
    /** @description Stores the patient's insurance role */
    public insuranceRole role { get; set; }
    
    /** @description Stores the patient's insurance plan details */
    public insurancePlan iplan { get; set; }
    
    /** @description Stores the patient's insurance sub-plan details */
    public insurancesubPlan isubplan { get; set; }
    
    /** @description Stores the type of insurance the patient has */
    public insuranceType itype { get; set; }
    
    /** @description Stores the pharmacy benefits information for the patient */
    public pharmacybi phabi { get; set; }
    
    /** @description Stores the effective date of the patient's insurance coverage */
    public string effectiveDate { get; set; }
    
    /** @description Stores the pre-authorization string for the patient's insurance */
    public string preAuthString { get; set; }
    
    /** @description Stores the Benefit Verification date */
    public string dateBV { get; set; }
    
    /** @description Initializes and populates data for the Visualforce page */
    public CoverageBenefitPDFController() {
        initializeVariables();
        loadCoverageBenefit();
        loadDosing();
        
    }
    
    /** @description Initializes all variables used in the controller */
    private void initializeVariables() {
        ic = new CoverageBenefit(); // Initializes CoverageBenefit object
        role = new insuranceRole(); // Initializes insuranceRole object
        iplan = new insurancePlan(); // Initializes insurancePlan object
        isubplan = new insurancesubPlan(); // Initializes insurancesubPlan object
        itype = new insuranceType(); // Initializes insuranceType object
        phabi = new pharmacybi(); // Initializes pharmacybi object
        patientDob = ''; // Initializes Date of Birth as an empty string
        effectiveDate = ''; // Initializes Effective Date as an empty string
        preAuthString = ''; // Initializes Pre-Authorization string as empty
        dateBV = ''; // Initializes Benefit Verification date as empty
    }
    
    
    // Load CoverageBenefit data and populate relevant details
    private void loadCoverageBenefit() {
        String parentcbId = Id.valueOf(ApexPages.currentPage().getParameters().get('id'));
        if (!String.isEmpty(parentcbId)) {
            String sObjectType = 'CoverageBenefit';
            String fields = 'Id, Care_Program_Enrollee__c, J_BenefitYear__c, J_SpecialtyPharmacyPhone__c, ' +
                'J_SpecialtyPharmacyFax__c, J_DateBenefitVerified__c, J_Outcome__c, ' +
                'J_CoverageBenefitStatus__c, J_Prior_Authorization_Requirement__c, Authorization_information__c, ' +
                'J_AnnualMaxAmount__c, J_BenefitAdministratorPhone__c, J_PreferredSpecialtyPharmacy__c, ' +
                'J_PreferredSpecialtyPharmacy__r.Name, J_RxDEDPartofMajorMedical__c, J_LifetimeMax__c, ' +
                'J_InsurancePlanType__c, J_Lifetime_Max_Amount__c, J_AnnualMax__c, ' +
                'J_DeductibleIncludeinOOPMax__c, J_OOPMet__c, J_AccumulatorAdjustmentPlan__c, ' +
                'J_OOPMax__c, J_HowtoObtainAuthorization__c, J_CoInsurance__c, J_CoPay__c, J_Deductible__c, ' +
                'J_RxDEDCombinedwithMajorMedical__c, J_How_to_Obtain_Authoriz__c, ' +
                'J_PriorAuthorizationRequired__c, J_BenefitsStartDate__c, J_BenefitsEndDate__c, J_Benefit__c, ' +
                'Care_Program_Enrollee__r.Account.Name, Care_Program_Enrollee__r.Account.PersonHomePhone, ' +
                'Care_Program_Enrollee__r.Account.PersonBirthdate, Care_Program_Enrollee__r.Account.J_Mailing_Address__c, ' +
                'MemberPlan.PayerId, MemberPlan.Payer.Name, MemberPlan.J_ProviderLinePhoneNumber__c, ' +
                'MemberPlan.J_MemberServicesPhoneNumber__c, MemberPlan.J_Role__c, MemberPlan.J_InsuranceType__c, ' +
                'MemberPlan.J_PlanSubType__c, MemberPlan.J_PolicyHolderName__c, ' +
                'MemberPlan.J_Relation_to_Policy_Holder__c, MemberPlan.GroupNumber, MemberPlan.J_RxBinNumber__c, ' +
                'MemberPlan.J_PBM_Policy_Numb__c, MemberPlan.J_ThirdPartyAdministrator__c, MemberPlan.J_PolicyNumber__c, ' +
                'MemberPlan.J_PolicyStartDate__c, MemberPlan.J_PharmacyPlanName__c, MemberPlan.J_PolicyEndDate__c';
            
            String conditions = 'Id = \'' + parentcbId + '\' LIMIT 1';
            
            List<CoverageBenefit> cbList = (List<CoverageBenefit>) COM_QueryUtility.executeQuery(
                sObjectType, fields, conditions, false
            );
            
            if (cbList != null || !cbList.isEmpty()) {
                ic = cbList[0];
                // Set Enrollee ID
                enId = ic.Care_Program_Enrollee__c;
                // Populate other details
                populateDetails();
                loadDosing();
                
            }else {
                ic = null;
            }
        }
    }
    
    // Load Dosing details based on Enrollee ID
    private void loadDosing() {
        if (enId == null) {
            dosing = null; // No enrollee ID to filter on
            return;
        }
        
        String sObjectType = 'PatientMedicationDosage';
        String fields = 'Id, Care_Program_Enrollee_Name__c, Patient__c, Enrollee_HCP__c, ' +
            'Enrollee_HCP__r.HCP__c, Current_Dose_Record__c, Care_Program_Product1__c, ' +
            'Enrollee_HCP__r.HCP__r.J_Primary_ICD_10_Code__c, Enrollee_HCP__r.HCP__r.Name, ' +
            'Enrollee_HCP__r.HCP__r.J_NPI__c, Enrollee_HCP__r.HCP__r.J_TaxID__c, ' +
            'Enrollee_HCP__r.HCP__r.MobilePhone, Enrollee_HCP__r.HCP__r.MailingAddress, ' +
            'Enrollee_HCP__r.HCP__r.MailingStreet, Enrollee_HCP__r.HCP__r.MailingState, ' +
            'Enrollee_HCP__r.HCP__r.MailingCity, Enrollee_HCP__r.HCP__r.MailingCountry, ' +
            'Enrollee_HCP__r.HCP__r.MailingPostalCode';
        String conditions = 'Care_Program_Enrollee_Name__c = \'' + enId + '\' AND Current_Dose_Record__c = TRUE ' +
            'ORDER BY LastModifiedDate DESC LIMIT 1';
        
        List<PatientMedicationDosage> pmdList = (List<PatientMedicationDosage>) COM_QueryUtility.executeQuery(
            sObjectType, fields, conditions, false
        );
        
        if (!pmdList.isEmpty()) {
            dosing = pmdList[0];
        } else {
            dosing = null;
        }
    }
    
    // Populate all required details based on the CoverageBenefit record
    private void populateDetails() {
        if (ic.Care_Program_Enrollee__r.Account.PersonBirthdate != null) {
            patientDob = formatDate(ic.Care_Program_Enrollee__r.Account.PersonBirthdate);
        }
        if (ic.J_BenefitsStartDate__c != null) {
            effectiveDate = formatDate(ic.J_BenefitsStartDate__c);
        }
        if (ic.J_DateBenefitVerified__c != null) {
            dateBV = formatDate(ic.J_DateBenefitVerified__c);
        }
        if (ic.J_Prior_Authorization_Requirement__c != null) {
            preAuthString = ic.J_Prior_Authorization_Requirement__c.stripHtmlTags();
        }
        
        setInsuranceRoles();
        setInsurancePlans();
        setSubPlans();
        setPharmacyDetails();
        setInsuranceType();
    }
    
    // Helper: Format a date into MM/DD/YYYY
    private String formatDate(Date inputDate) {
        return inputDate.month() + '/' + inputDate.day() + '/' + inputDate.year();
    }
    
    // Populate insurance roles based on the MemberPlan's role
    private void setInsuranceRoles() {
        String insRole = ic.MemberPlan.J_Role__c; 
        role.isPrimary = (insRole == 'Primary');
        role.isSecondary = (insRole == 'Secondary');
        role.isTertiary = (insRole == 'Tertiary');
    }
    
    /** @description Sets the insurance type based on the value of J_InsurancePlanType__c */
    private void setInsuranceType() {
        String insType = ic.J_InsurancePlanType__c; // Retrieves the insurance plan type from the CoverageBenefit object
        itype.selfInsured = (insType == 'self insured'); // Sets selfInsured to true if the insurance type is 'self insured'
        itype.fullFunded = (insType == 'Full funded'); // Sets fullFunded to true if the insurance type is 'Full funded'
    }
    
    // Populate insurance plans based on the MemberPlan's type
    private void setInsurancePlans() {
        String planType = ic.MemberPlan.J_InsuranceType__c;
        iplan.commercial = (planType == 'Commercial');
        iplan.medicare = (planType == 'Medicare');
        iplan.medicaid = (planType == 'Medicaid');
        iplan.healthInsurance = (planType == 'HIX');
        iplan.uninsured = (planType == 'Uninsured');
        iplan.highRiskFed = (planType == 'High Risk FEF');
        iplan.highRiskState = (planType == 'High Risk State');
        iplan.militaryScchip = (planType == 'Military SCCHIP');
    }
    
    // Populate insurance subplans based on the MemberPlan's subtype
    private void setSubPlans() {
        String subPlanType = ic.MemberPlan.J_PlanSubType__c;
        isubplan.chmo = (subPlanType == 'C HMO');
        isubplan.cother = (subPlanType == 'C Other');
        isubplan.cpbm = (subPlanType == 'C PBM');
        isubplan.cpos = (subPlanType == 'C POS');
        isubplan.cppo = (subPlanType == 'C ppo');
        isubplan.hmo = (subPlanType == 'HMO');
        isubplan.epo = (subPlanType == 'EPO');
        isubplan.fep = (subPlanType == 'FEP');
        isubplan.indemnity = (subPlanType == 'Indemnity');
        isubplan.ipa = (subPlanType == 'IPA');
        isubplan.militaryNetwork = (subPlanType == 'Military Network');
        isubplan.militarySupplemental = (subPlanType == 'Military Supplemental');
        isubplan.other = (subPlanType == 'Other');
        isubplan.partA = (subPlanType == 'Part A');
        isubplan.partB = (subPlanType == 'Part B');
        isubplan.partD = (subPlanType == 'Part D');
        isubplan.pos = (subPlanType == 'POS');
        isubplan.stateProgram = (subPlanType == 'State Program');
        isubplan.supplementalMediGap = (subPlanType == 'Supplemental/ Medi Gap');
        isubplan.unKnown = (subPlanType == 'Unknown');
    }
    
    // Populate pharmacy benefits based on various CoverageBenefit fields
    private void setPharmacyDetails() {
        phabi.rxYes = (ic.J_RxDEDPartofMajorMedical__c == 'Yes');
        phabi.rxNo = (ic.J_RxDEDPartofMajorMedical__c == 'No');
        phabi.aapYes = (ic.J_AccumulatorAdjustmentPlan__c == 'Yes');
        phabi.aapNo = (ic.J_AccumulatorAdjustmentPlan__c == 'No');
        phabi.amaxYes = (ic.J_AnnualMax__c == 'Yes');
        phabi.lmaxYes = (ic.J_LifetimeMax__c == 'No');
        phabi.lmaxNo = (ic.J_LifetimeMax__c == 'Yes');
        phabi.parYes = (ic.J_PriorAuthorizationRequired__c == 'Yes');
        phabi.parNo = (ic.J_PriorAuthorizationRequired__c == 'No');
        phabi.dedYes = (ic.J_DeductibleIncludeinOOPMax__c == 'Yes');
        phabi.dedNo = (ic.J_DeductibleIncludeinOOPMax__c == 'No');
        phabi.metYes = (ic.J_OOPMet__c == 'Yes');
        phabi.metNo = (ic.J_OOPMet__c == 'No');
        phabi.rxoopYes = (ic.J_RxDEDCombinedwithMajorMedical__c == 'Yes');
        phabi.rxoopNo = (ic.J_RxDEDCombinedwithMajorMedical__c == 'No');
        phabi.outYes = (ic.J_Outcome__c == 'Covered');
        phabi.outYes = (ic.J_Outcome__c == 'Covered with restrictions');
        phabi.outNo = (ic.J_Outcome__c == 'Not covered');
    }
    /**
* @description Class representing the different roles an insurance can have for a patient.
* This class defines boolean properties for primary, secondary, and tertiary insurance roles.
*/
    public class InsuranceRole {
        
        /** @description Represents if the insurance is primary for the patient */
        public Boolean isPrimary { get; set; }
        
        /** @description Represents if the insurance is secondary for the patient */
        public Boolean isSecondary { get; set; }
        
        /** @description Represents if the insurance is tertiary for the patient */
        public Boolean isTertiary { get; set; }
        
        /**
* @description Constructor to initialize all the insurance roles to false.
* This ensures the object is initialized with default values, assuming no insurance role initially.
*/
        public InsuranceRole() {
            isPrimary = false;
            isSecondary = false;
            isTertiary = false;
        }
    }
    
    /**
* @description Class representing different types of insurance plans.
* This class defines boolean properties for various insurance options, 
* such as commercial, medicare, medicaid, etc.
*/
    public class InsurancePlan {
        
        /** @description Represents if the patient has commercial insurance */
        public Boolean commercial { get; set; }
        
        /** @description Represents if the patient has medicare insurance */
        public Boolean medicare { get; set; }
        
        /** @description Represents if the patient has medicaid insurance */
        public Boolean medicaid { get; set; }
        
        /** @description Represents if the patient has health insurance */
        public Boolean healthInsurance { get; set; }
        
        /** @description Represents if the patient is uninsured */
        public Boolean uninsured { get; set; }
        
        /** @description Represents if the patient is enrolled in a high-risk federal program */
        public Boolean highRiskFed { get; set; }
        
        /** @description Represents if the patient is enrolled in a high-risk state program */
        public Boolean highRiskState { get; set; }
        
        /** @description Represents if the patient is enrolled in military SCHIP (State Children's Health Insurance Program) */
        public Boolean militaryScchip { get; set; }
        
        /**
* @description Constructor to initialize all the insurance plan options to false.
* This ensures the object is initialized with default values.
*/
        public InsurancePlan() {
            commercial = false;
            medicare = false;
            medicaid = false;
            healthInsurance = false;
            uninsured = false;
            highRiskFed = false;
            highRiskState = false;
            militaryScchip = false;
        }
    }
    
    /**
* @description Class representing different types of insurance sub-plans.
* This class includes various boolean properties that define different sub-plans under an insurance policy.
*/
    public class InsurancesubPlan {
        
        /** @description Represents if the insurance plan is CHMO (Commercial Health Maintenance Organization) */
        public Boolean chmo { get; set; }
        
        /** @description Represents if the insurance plan is 'Other' under the sub-plan category */
        public Boolean cother { get; set; }
        
        /** @description Represents if the insurance plan is PBM (Pharmacy Benefits Manager) */
        public Boolean cpbm { get; set; }
        
        /** @description Represents if the insurance plan is POS (Point of Service) */
        public Boolean cpos { get; set; }
        
        /** @description Represents if the insurance plan is PPO (Preferred Provider Organization) */
        public Boolean cppo { get; set; }
        
        /** @description Represents if the insurance plan is EPO (Exclusive Provider Organization) */
        public Boolean epo { get; set; }
        
        /** @description Represents if the insurance plan is FEP (Federal Employee Program) */
        public Boolean fep { get; set; }
        
        /** @description Represents if the insurance plan is HMO (Health Maintenance Organization) */
        public Boolean hmo { get; set; }
        
        /** @description Represents if the insurance plan is indemnity-based */
        public Boolean indemnity { get; set; }
        
        /** @description Represents if the insurance plan is IPA (Independent Practice Association) */
        public Boolean ipa { get; set; }
        
        /** @description Represents if the insurance plan is a military network */
        public Boolean militaryNetwork { get; set; }
        
        /** @description Represents if the insurance plan is military supplemental */
        public Boolean militarySupplemental { get; set; }
        
        /** @description Represents if the insurance plan is of 'Other' type */
        public Boolean other { get; set; }
        
        /** @description Represents if the insurance plan is part A of Medicare */
        public Boolean partA { get; set; }
        
        /** @description Represents if the insurance plan is part B of Medicare */
        public Boolean partB { get; set; }
        
        /** @description Represents if the insurance plan is part D of Medicare */
        public Boolean partD { get; set; }
        
        /** @description Represents if the insurance plan is POS (Point of Service) */
        public Boolean pos { get; set; }
        
        /** @description Represents if the insurance plan is PPO (Preferred Provider Organization) */
        public Boolean ppo { get; set; }
        
        /** @description Represents if the insurance plan is a state program */
        public Boolean stateProgram { get; set; }
        
        /** @description Represents if the insurance plan is a supplemental MediGap */
        public Boolean supplementalMediGap { get; set; }
        
        /** @description Represents if the insurance plan is unknown */
        public Boolean unKnown { get; set; }
        
        /**
* @description Constructor to initialize all the sub-plan options to false.
* This ensures that each insurance sub-plan is initialized with a default value of false.
*/
        public InsurancesubPlan() {
            chmo = false;
            cother = false;
            cpbm = false;
            cpos = false;
            cppo = false;
            epo = false;
            fep = false;
            hmo = false;
            indemnity = false;
            ipa = false;
            militaryNetwork = false;
            militarySupplemental = false;
            other = false;
            partA = false;
            partB = false;
            partD = false;
            pos = false;
            ppo = false;
            stateProgram = false;
            supplementalMediGap = false;
            unKnown = false;
        }
    }
    
    /**
* @description Inner class representing the details of the insurance type (self-insured or fully funded).
*/
    public class InsuranceType {
        
        /** @description Represents if the insurance is self-insured */
        public Boolean selfInsured { get; set; }
        
        /** @description Represents if the insurance is fully funded */
        public Boolean fullFunded { get; set; }
        
        /**
* @description Constructor to initialize insurance type options to false.
* This ensures that the insurance type is initialized with default values.
*/
        public InsuranceType() {
            selfInsured = false;
            fullFunded = false;
        }
    }
    
    /**
* @description Inner class representing pharmacy benefits information.
* This class contains boolean properties for various pharmacy-related coverage options.
*/
    public class Pharmacybi {
        
        /** @description Represents if the patient has Rx (prescription) coverage */
        public Boolean rxYes { get; set; }
        
        /** @description Represents if the patient does not have Rx (prescription) coverage */
        public Boolean rxNo { get; set; }
        
        /** @description Represents if the patient has AAP (Authorized Alternative Pharmacy) coverage */
        public Boolean aapYes { get; set; }
        
        /** @description Represents if the patient does not have AAP (Authorized Alternative Pharmacy) coverage */
        public Boolean aapNo { get; set; }
        
        /** @description Represents if the patient has AMAX (Alternative Maximum) coverage */
        public Boolean amaxYes { get; set; }
        
        /** @description Represents if the patient does not have AMAX (Alternative Maximum) coverage */
        public Boolean amaxNo { get; set; }
        
        /** @description Represents if the patient has LMAX (Local Maximum) coverage */
        public Boolean lmaxYes { get; set; }
        
        /** @description Represents if the patient does not have LMAX (Local Maximum) coverage */
        public Boolean lmaxNo { get; set; }
        
        /** @description Represents if the patient has PAR (Participating Pharmacy) coverage */
        public Boolean parYes { get; set; }
        
        /** @description Represents if the patient does not have PAR (Participating Pharmacy) coverage */
        public Boolean parNo { get; set; }
        
        /** @description Represents if the patient has deductible (ded) coverage */
        public Boolean dedYes { get; set; }
        
        /** @description Represents if the patient does not have deductible (ded) coverage */
        public Boolean dedNo { get; set; }
        
        /** @description Represents if the patient has RXOOP (Out-of-Pocket) coverage */
        public Boolean rxoopYes { get; set; }
        
        /** @description Represents if the patient does not have RXOOP (Out-of-Pocket) coverage */
        public Boolean rxoopNo { get; set; }
        
        /** @description Represents if the patient has out-of-network coverage */
        public Boolean outYes { get; set; }
        
        /** @description Represents if the patient does not have out-of-network coverage */
        public Boolean outNo { get; set; }
        
        /** @description Represents if the patient has met coverage */
        public Boolean metYes { get; set; }
        
        /** @description Represents if the patient does not have met coverage */
        public Boolean metNo { get; set; }
        
        /**
* @description Constructor to initialize pharmacy benefits options to false.
* This ensures the pharmacy benefits fields are initialized with default values.
*/
        public Pharmacybi() {
            rxYes = false;
            rxNo = false;
            aapYes = false;
            aapNo = false;
            amaxYes = false;
            amaxNo = false;
            lmaxYes = false;
            lmaxNo = false;
            parYes = false;
            parNo = false;
            dedYes = false;
            dedNo = false;
            rxoopYes = false;
            rxoopNo = false;
            outYes = false;
            outNo = false;
            metYes = false;
            metNo = false;
        }
    }
}