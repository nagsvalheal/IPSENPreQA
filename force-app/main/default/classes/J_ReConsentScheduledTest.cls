/**
 *   @author         Arkadii Sychov
 *   @date           10/21/20
 *   @description    IPSC-213. Unit Tests for J_ReConsentScheduled
 *   @Modifier       Rajaa
 *   @date           12/16/24
 **/
@isTest
public class J_ReConsentScheduledTest {
	public static final String STATE_MAILING = 'Arkansas';
	public static final String CITY_MAILING = 'CITY';
	public static final String PATIENT_FIRST_NAME = 'patient_test';

	@TestSetup
	static void makeData() {
		//Create Territory
		List<J_Territory__c> territory = new List<J_Territory__c>();
		J_Territory__c territoryCC = new J_Territory__c(
			J_Active__c = true,
			J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
			J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_CC,
			J_TerritoryCode__c = 'test 1',
			J_States__c = 'test 1',
			Name = J_TestUtils.TERRITORY_NAME_CC
		);
		territory.add(territoryCC);

		J_Territory__c territoryPEL = new J_Territory__c(
			J_Active__c = true,
			J_ZipCodes__c = J_TestUtils.ZIP_MAILING,
			J_TerritoryType__c = J_TestUtils.TERRITORY_TYPE_PEL,
			J_TerritoryCode__c = 'test 2',
			J_States__c = 'test 2',
			Name = J_TestUtils.TERRITORY_NAME_PEL
		);
		territory.add(territoryPEL);

		insert territory;

		//Create Patient
		Account patient = new Account(
			FirstName = PATIENT_FIRST_NAME,
			LastName = J_TestUtils.PATIENT_LAST_NAME,
			RecordTypeId = J_ObjectUtils.getAccountRecordTypeId(
				J_ObjectUtils.PERSON_ACCOUNT_RT_JOURNEYS_PATIENT_NAME,
				true
			),
			J_PrimaryAddress__c = J_TestUtils.ACCOUNT_PRIMARY_ADDRESS_MAILING,
			PersonMailingPostalCode = J_TestUtils.ZIP_MAILING,
			PersonMailingStreet = J_TestUtils.STREET_MAILING,
			PersonMailingCity = CITY_MAILING,
			PersonMailingState = STATE_MAILING,
			PersonBirthdate = Date.today().addYears(-19),
			Patient_Status__pc = J_ObjectUtils.ACCOUNT_PATIENT_STATUS_PL_ACTIVE,
			Home_Work_Mobile__pc = J_ObjectUtils.ACCOUNT_HOME_WORK_MOBILE_PL_HOME,
			PersonHomePhone = '00099'
		);
		insert patient;
	}

	@isTest
	static void reConsentScheduledTest() {
		Test.startTest();
		Datetime dt = Datetime.now().addMinutes(1);
		String cronExp =
			'0 ' +
			dt.minute() +
			' * ' +
			dt.day() +
			' ' +
			dt.month() +
			' ? ' +
			dt.year();
		String jobId = System.schedule(
			'J_ReConsentScheduledTest',
			cronExp,
			new J_ReConsentScheduled()
		);
		Test.stopTest();
		Assert.areNotEqual(null, jobId, 'The batch ID should not be null.');
	}
}