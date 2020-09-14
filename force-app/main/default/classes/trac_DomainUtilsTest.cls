@isTest(SeeAllData=false)
private class trac_DomainUtilsTest {
	private static testmethod void testGetDomainsWithExistingDomains(){
		Set<String> setOfURL = new Set<String>();
		Map<String, Domain__c> domainResultMap;

		Domain__c newDomain1 = trac_TestUtils.createDomain('account1', 'domain1', 'test1.com');
		Domain__c newDomain2 = trac_TestUtils.createDomain('account2', 'domain2', 'test2.com');

		for(Integer i = 0; i < 5; i++){
			setOfURL.add('test' + i + '.com');
		}

		Test.startTest();

        
		domainResultMap = trac_DomainUtils.getDomains(setOfURL);

		Test.stopTest();

		System.assertEquals(5, domainResultMap.size());

	}

	private static testmethod void testGetDomainsWIthNoExistingDominas(){
		Set<String> setOfURL = new Set<String>();
		Map<String, Domain__c> domainResultMap;
		
		for(Integer i = 0; i < 5; i++){
			setOfURL.add('test' + i + '.com');
		}

		Test.startTest();

		domainResultMap = trac_DomainUtils.getDomains(setOfURL);

		Test.stopTest();

		System.assertEquals(5, domainResultMap.size());
	}
}