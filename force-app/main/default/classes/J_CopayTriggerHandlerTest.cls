/**
 *   @author         Arkadii Sychov
 *   @date           10/29/20
 *   @description    IPSC-213. Unit Tests for J_CopayTriggerHandler
 **/
@isTest
public class J_CopayTriggerHandlerTest {
	static final String ACTIVE_STATUS = 'Active'; // Example status constant for the test

	@isTest
	static void testCheckOnExistingActiveCopayNoOverlaps() {
		// Test setup
		Account patient = J_TestUtils.createPatient();
		CareProgram careProgram = J_TestUtils.createCareProgram();
		CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(
			patient.Id,
			careProgram.Id
		);
		MemberPlan memberPlan = J_TestUtils.createMemberPlan(patient.Id);

		CoverageBenefit cb = new CoverageBenefit(
			Name = 'COVERAGE_BENEFIT_PLAN_NAME',
			MemberPlanId = memberPlan.Id,
			Care_Program_Enrollee__c = enrollee.Id,
			J_CoverageBenefitStatus__c = 'Active'
		);
		insert cb;

		// Create two non-overlapping copay records
		J_Copay__c copay1 = new J_Copay__c(
			Care_Program_Enrollee__c = enrollee.Id,
			Insurance_Plan__c = memberPlan.Id,
			J_CurrentCopayStatus__c = ACTIVE_STATUS,
			J_EnrollmentStartDate__c = Date.today().addDays(-20),
			J_EnrollmentEndDate__c = Date.today().addDays(-10)
		);
		J_Copay__c copay2 = new J_Copay__c(
			Care_Program_Enrollee__c = enrollee.Id,
			Insurance_Plan__c = memberPlan.Id,
			J_CurrentCopayStatus__c = ACTIVE_STATUS,
			J_EnrollmentStartDate__c = Date.today().addDays(-5),
			J_EnrollmentEndDate__c = Date.today()
		);
		insert new List<J_Copay__c>{ copay1, copay2 };

		// Simulate Trigger Execution
		Map<Id, J_Copay__c> triggerMap = new Map<Id, J_Copay__c>{
			copay2.Id => copay2
		};
		Test.startTest();
		new J_CopayTriggerHandler().checkOnExistingActiveCopay(triggerMap);
		Test.stopTest();

		// Assert no errors occurred
		System.assertEquals(
			0,
			copay2.getErrors().size(),
			'No errors should occur for non-overlapping copays.'
		);
	}

	@isTest
	static void testCheckOnExistingActiveCopayWithOverlaps() {
		// Test setup
		Account patient = J_TestUtils.createPatient();
		CareProgram careProgram = J_TestUtils.createCareProgram();
		CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(
			patient.Id,
			careProgram.Id
		);
		MemberPlan memberPlan = J_TestUtils.createMemberPlan(patient.Id);

		CoverageBenefit cb = new CoverageBenefit(
			Name = 'COVERAGE_BENEFIT_PLAN_NAME',
			MemberPlanId = memberPlan.Id,
			Care_Program_Enrollee__c = enrollee.Id,
			J_CoverageBenefitStatus__c = 'Active'
		);
		insert cb;

		// Create an existing copay and a new overlapping copay
		J_Copay__c existingCopay = new J_Copay__c(
			Care_Program_Enrollee__c = enrollee.Id,
			Insurance_Plan__c = memberPlan.Id,
			J_CurrentCopayStatus__c = ACTIVE_STATUS,
			J_EnrollmentStartDate__c = Date.today().addDays(-10),
			J_EnrollmentEndDate__c = Date.today()
		);
		insert existingCopay;

		J_Copay__c overlappingCopay = new J_Copay__c(
			Care_Program_Enrollee__c = enrollee.Id,
			Insurance_Plan__c = memberPlan.Id,
			J_CurrentCopayStatus__c = ACTIVE_STATUS,
			J_EnrollmentStartDate__c = Date.today().addDays(-5),
			J_EnrollmentEndDate__c = Date.today().addDays(5)
		);

		// Simulate Trigger Execution
		Test.startTest();
		try {
			insert overlappingCopay; // This DML will trigger the addError logic
		} catch (Exception e) {
			System.assert(
				e.getMessage()
					.contains(
						Label.J_ThereIsExistingActiveCopayRecordOnTheseDates
					),
				'Expected overlapping copay error message.'
			);
		}
		Test.stopTest();
	}

	@isTest
	static void testHasDateOverlap() {
		// Directly test date overlap logic
		J_CopayTriggerHandler handler = new J_CopayTriggerHandler();

		Date start1 = Date.today();
		Date end1 = Date.today().addDays(5);
		Date start2 = Date.today().addDays(3);
		Date end2 = Date.today().addDays(8);

		// Case 1: Overlapping
		Boolean result = handler.isOverlapping(start1, end1, start2, end2);
		System.assert(result, 'Expected overlapping dates.');

		// Case 2: Non-overlapping
		start2 = Date.today().addDays(6);
		result = handler.isOverlapping(start1, end1, start2, end2);
		System.assert(!result, 'Expected non-overlapping dates.');
	}

	@isTest
	static void testGetActiveCopayExisted() {
		// Test setup
		Account patient = J_TestUtils.createPatient();
		CareProgram careProgram = J_TestUtils.createCareProgram();
		CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(
			patient.Id,
			careProgram.Id
		);
		MemberPlan memberPlan = J_TestUtils.createMemberPlan(patient.Id);

		CoverageBenefit cb = new CoverageBenefit(
			Name = 'COVERAGE_BENEFIT_PLAN_NAME',
			MemberPlanId = memberPlan.Id,
			Care_Program_Enrollee__c = enrollee.Id,
			J_CoverageBenefitStatus__c = 'Active'
		);
		insert cb;

		J_Copay__c activeCopay = new J_Copay__c(
			Care_Program_Enrollee__c = enrollee.Id,
			Insurance_Plan__c = memberPlan.Id,
			J_CurrentCopayStatus__c = ACTIVE_STATUS,
			J_EnrollmentStartDate__c = Date.today().addDays(-10),
			J_EnrollmentEndDate__c = Date.today()
		);
		insert activeCopay;

		List<Id> enrolleeIds = new List<Id>{ enrollee.Id };

		Test.startTest();
		Map<Id, J_Copay__c> result = new J_CopayTriggerHandler()
			.getActiveCopayExisted(new List<Id>(), enrolleeIds);
		Test.stopTest();

		// Assertions
		System.assert(
			result.containsKey(enrollee.Id),
			'Expected active copay to be retrieved.'
		);
	}

	@isTest
	static void testValidateOverlapWithCharitables() {
		// Step 1: Create mock data for copay and charitable (active records)
		Account patient = J_TestUtils.createPatient();
		CareProgram careProgram = J_TestUtils.createCareProgram();
		CareProgramEnrollee enrollee = J_TestUtils.createCareProgramEnrollee(
			patient.Id,
			careProgram.Id
		);
		MemberPlan memberPlan = J_TestUtils.createMemberPlan(patient.Id);

		// Coverage Benefit for copay
		CoverageBenefit cb = new CoverageBenefit(
			Name = 'COVERAGE_BENEFIT_PLAN_NAME',
			MemberPlanId = memberPlan.Id,
			Care_Program_Enrollee__c = enrollee.Id,
			J_CoverageBenefitStatus__c = 'Active'
		);
		insert cb;

		// Step 2: Create an active copay record (copay dates overlap with active charitable record)
		J_Copay__c copay = new J_Copay__c(
			Care_Program_Enrollee__c = enrollee.Id,
			Insurance_Plan__c = memberPlan.Id,
			J_CurrentCopayStatus__c = 'Active',
			J_EnrollmentStartDate__c = Date.today().addDays(-10),
			J_EnrollmentEndDate__c = Date.today().addDays(5)
		);
		insert copay;

		// Step 3: Create a single active charitable record (dates overlap with copay record)
		J_Charitable__c charitable = new J_Charitable__c(
			Care_Program_Enrollee__c = enrollee.Id,
			J_CharitableStatus__c = 'Closed',
			J_Persons_in_Family_Household__c = 11,
			J_Annual_Household_Income__c = 11111,
			J_CharitableProgramType__c = 'PAP', // Adjust as needed
			J_Enrollment_Start_Date__c = Date.today().addDays(-5),
			J_Enrollment_End_Date__c = Date.today().addDays(5)
		);
		insert charitable;

		// Step 4: Prepare Map for charitable records to be passed
		Map<Id, J_Charitable__c> existingCharitables = new Map<Id, J_Charitable__c>{
			charitable.Id => charitable
		};

		// Step 5: Simulate Trigger Execution
		Test.startTest();

		// Invoke the handler method that checks for overlap
		new J_CopayTriggerHandler()
			.validateOverlapWithCharitables(copay, existingCharitables);

		Test.stopTest();

		// Step 6: Assert the expected behavior
		// Assert that the overlap error is added for the active copay and charitable record
		System.assertEquals(
			1,
			copay.getErrors().size(),
			'Expected 1 overlap error.'
		);
		System.assert(
			copay.getErrors()[0]
				.getMessage()
				.contains(
					Label.J_ThereIsExistingActivePAPTPAPRecordOnTheseDates
				),
			'Expected correct overlap error message.'
		);
	}
}