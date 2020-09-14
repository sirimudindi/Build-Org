/**
 * @author Steve Doucette, Traction on Demand 
 * @date 1/22/2018
 */
@isTest
public with sharing class trac_ExcessiveCaseAlertTest {

	private static final String CRON_STRING = '0 0 0 3 9 ? 2022';
	private static final String JOB_NAME = '%' + trac_ExcessiveCaseAlert.JOB_NAME_PREFIX + '%';

	private static final Integer THRESHOLD = 10;

	private static Case_Alert_Settings__c settings;

	private static void setup() {
		trac_TestUtils.setupCollaboratorPackage();

		OrgWideEmailAddress owa = [
				SELECT Address
				FROM OrgWideEmailAddress
				LIMIT 1
		];

		settings = Case_Alert_Settings__c.getOrgDefaults();
		settings.Interval_In_Minutes__c = 5;
		settings.Non_Business_Hours_Threshold__c = settings.Threshold__c = THRESHOLD;
		settings.Business_Hours_Lookback__c = settings.Non_Business_Hours_Lookback__c = 10;
		settings.From_Address__c = owa.Address;
		settings.Email_To__c = UserInfo.getUserEmail();
		upsert settings;
	}

	@isTest
	public static void testNoOwaInCustomSetting() {
		setup();

		settings.From_Address__c = 'invalidEmail@invalid.com';
		update settings;

		Test.startTest();
		System.schedule(JOB_NAME, CRON_STRING, new trac_ExcessiveCaseAlert());
		Test.stopTest();
	}

	@isTest
	public static void testEmptyEmailToInCustomSetting() {
		setup();

		settings.Email_To__c = '';
		settings.Non_Business_Hours_Email_To__c = '';
		settings.Run_During_Business_Hours__c = settings.Run_During_Non_Business_Hours__c = true;
		update settings;

		Test.startTest();
		System.schedule(JOB_NAME, CRON_STRING, new trac_ExcessiveCaseAlert());
		Test.stopTest();
	}

	@isTest
	public static void testNoRunsCheckedInCustomSetting() {
		setup();

		Test.startTest();
		System.schedule(JOB_NAME, CRON_STRING, new trac_ExcessiveCaseAlert());
		Test.stopTest();
	}

	@isTest
	public static void testRunDuringBusinessHours() {
		setup();

		settings.Run_During_Business_Hours__c = true;
		update settings;

		Test.startTest();
		System.schedule(JOB_NAME, CRON_STRING, new trac_ExcessiveCaseAlert());
		Test.stopTest();
	}

	@isTest
	public static void testRunDuringNonBusinessHours() {
		setup();

		settings.Run_During_Non_Business_Hours__c = true;
		update settings;

		Test.startTest();
		System.schedule(JOB_NAME, CRON_STRING, new trac_ExcessiveCaseAlert());
		Test.stopTest();
	}

	@isTest
	public static void testCasesDoesNotExceedThreshold() {
		setup();

		settings.Run_During_Non_Business_Hours__c = settings.Run_During_Business_Hours__c = true;
		update settings;

		List<Case> cases = new List<Case>();
		for (Integer i = 0; i < THRESHOLD; i++) {
			cases.add(new Case());
		}
		insert cases;

		Test.startTest();
		System.schedule(JOB_NAME, CRON_STRING, new trac_ExcessiveCaseAlert());
		Test.stopTest();
	}

	@isTest
	public static void testCasesExceedsThreshold() {
		setup();

		settings.Run_During_Non_Business_Hours__c = settings.Run_During_Business_Hours__c = true;
		update settings;

		List<Case> cases = new List<Case>();
		for (Integer i = 0; i < THRESHOLD + 1; i++) {
			cases.add(new Case());
		}
		insert cases;

		Test.startTest();
		System.schedule(JOB_NAME, CRON_STRING, new trac_ExcessiveCaseAlert());
		Test.stopTest();
	}

	@isTest
	public static void coverTriggerHandlerBase() {
		setup();

		Case c = new Case();
		insert c;

		delete c;
		undelete c;
	}
}