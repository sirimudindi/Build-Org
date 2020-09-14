@isTest
private class trac_CasesEmailTemplateTest {

	static {
		trac_TestUtils.setupCollaboratorPackage();
	}

	private static List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings;
	private static Case testCase1;
	static{
		testCase1 = trac_TestUtils.createCase('In Progress','Phone','foo@bar.com','Foo Bar1');
		testCase1.Email_to_Case_Address__c = 'test@example.com';
		insert testCase1;
		List<Map<String, Object>> defaultSettingAsUntypedObject = new List<Map<String, Object>>{
																	new Map<String, Object>{
																        'targetSObject' => new EmailMessage(),
																        'contextId' => testCase1.Id,
																        'actionType' => 'Email',
																        'actionName' => 'Case.Email',
																        'fromAddressList' => new List<String> { 'salesforce@test.com' }
																  	}
																};

		defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingAsUntypedObject), List<QuickAction.SendEmailQuickActionDefaults>.class);

	}

	@isTest static void DefaultCaseFeedEmailImplementor_SimpleTest(){
		//Create test data here
		Exception failureDuringExecution = null;
		trac_CasesEmailTemplate tracCasesEmailTemplate = new trac_CasesEmailTemplate();
		tracCasesEmailTemplate.outboundEmailMappings = new List<trac_outbound_email_mapping__mdt>{ new trac_outbound_email_mapping__mdt(inbound__c = 'test@example.com') };

		Test.startTest();
		try {
			tracCasesEmailTemplate.onInitDefaults(defaultsSettings);
		} catch(Exception failure) {
			failureDuringExecution = failure;
		}

		Test.stopTest();

		System.assertEquals(null, failureDuringExecution, 'There was an exception thrown during the test!');
	}

	@isTest static void DefaultCaseFeedEmailImplementor_SimpleTest_TwoEmailMappings(){
		//Create test data here
		Exception failureDuringExecution = null;
		trac_CasesEmailTemplate tracCasesEmailTemplate = new trac_CasesEmailTemplate();
		tracCasesEmailTemplate.outboundEmailMappings = new List<trac_outbound_email_mapping__mdt>{ new trac_outbound_email_mapping__mdt(inbound__c = 'test@example.com', group__c = ''), new trac_outbound_email_mapping__mdt(inbound__c = 'test@example.com') };

		Test.startTest();
		try {
			tracCasesEmailTemplate.onInitDefaults(defaultsSettings);
		} catch(Exception failure) {
			failureDuringExecution = failure;
		}

		Test.stopTest();

		System.assertEquals(null, failureDuringExecution, 'There was an exception thrown during the test!');
	}

	@isTest static void DefaultCaseFeedEmailImplementor_SimpleTest_GroupMatching(){
		//Create test data here
		Exception failureDuringExecution = null;
		trac_CasesEmailTemplate tracCasesEmailTemplate = new trac_CasesEmailTemplate();
		tracCasesEmailTemplate.outboundEmailMappings = new List<trac_outbound_email_mapping__mdt>{ new trac_outbound_email_mapping__mdt(group__c = '') };

		Test.startTest();
		try {
			tracCasesEmailTemplate.onInitDefaults(defaultsSettings);
		} catch(Exception failure) {
			failureDuringExecution = failure;
		}

		Test.stopTest();

		System.assertEquals(null, failureDuringExecution, 'There was an exception thrown during the test!');
	}

	@isTest static void findOutBoundAddr() {
		trac_CasesEmailTemplate casesEmailTemplate = new trac_CasesEmailTemplate();
		List<trac_outbound_email_mapping__mdt> testEmailMappings = new List<trac_outbound_email_mapping__mdt>();
		String testMailAddress = 'test@example.com;test2@example.com';
		Map<String, List<trac_outbound_email_mapping__mdt>> testOutboundEmailMap = new Map<String, List<trac_outbound_email_mapping__mdt>>();
		testOutboundEmailMap.put(testMailAddress, testEmailMappings);

		Test.startTest();

		List<trac_outbound_email_mapping__mdt> result = casesEmailTemplate.findOutBoundAddr(testOutboundEmailMap, testMailAddress);

		Test.stopTest();

		System.assertNotEquals(null, result, 'The findOutBoundAddr method should never return null.');
		System.assertEquals(0, result.size(), 'The findOutBoundAddr method should return the expected Email Mappings list.');
	}

	@isTest static void findOutBoundAddrSingleEmailAddress() {
		trac_CasesEmailTemplate casesEmailTemplate = new trac_CasesEmailTemplate();
		List<trac_outbound_email_mapping__mdt> testEmailMappings = new List<trac_outbound_email_mapping__mdt>();
		String testMailAddress = 'test@example.com';
		Map<String, List<trac_outbound_email_mapping__mdt>> testOutboundEmailMap = new Map<String, List<trac_outbound_email_mapping__mdt>>();
		testOutboundEmailMap.put(testMailAddress, testEmailMappings);

		Test.startTest();

		List<trac_outbound_email_mapping__mdt> result = casesEmailTemplate.findOutBoundAddr(testOutboundEmailMap, testMailAddress);

		Test.stopTest();

		System.assertNotEquals(null, result, 'The findOutBoundAddr method should never return null.');
		System.assertEquals(0, result.size(), 'The findOutBoundAddr method should return the expected Email Mappings list.');
	}
}