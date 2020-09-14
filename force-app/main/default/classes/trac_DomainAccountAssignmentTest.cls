/*
 * @description trac_DomainAccountAssignmentTest tests the trac_DomainAccountAssignment
 *
 * @author Thomas Tran
 * @company Traction on Demand
 *
 * @date 09-25-2014
 */

@isTest(SeeAllData=false)
private class trac_DomainAccountAssignmentTest {

	private static testmethod void syncAccountLastActivityDateWithDomains() {
		Account testAccount = new Account(
				Name = 'Example Account'
		);
		insert testAccount;

		Event testEvent = new Event(
				DurationInMinutes = 60,
				WhatId = testAccount.Id,
				ActivityDateTime = System.now()
		);
		insert testEvent;

		Domain__c testDomain = new Domain__c(
				Account__c = testAccount.Id,
				Domain_Name_URL__c = 'example.com'
		);
		insert testDomain;

		testAccount = [ SELECT Id, LastActivityDate FROM Account WHERE Id = :testAccount.Id ];

		Map<Id, Account> oldAccounts = new Map<Id, Account> { testAccount.Id => testAccount };
		Map<Id, Account> newAccounts = new Map<Id, Account>{ testAccount.Id => testAccount };

		Exception resultException;

		Test.startTest();

		try {
			trac_DomainAccountAssignment.syncAccountLastActivityDateWithDomains(oldAccounts, newAccounts);
		} catch(Exception e) {
			resultException = e;
		}

		Test.stopTest();

		System.assertEquals(null, resultException);
	}

	/** @description Tests the assignAccountToDomain method. Ensure that
	*              the accounts are properly assigned to the domain.
	*
	* @author Thomas Tran
	* @company Traction on Demand
	* @date 09-24-2014
	*/
	private static testmethod void createAccountWithNoExistingDomain() {
		Account accountResult;
		Domain__c domainResult;
		Test.startTest();

		Account newAccount = new Account(
			Name = 'Traction Test',
			Domain__c = 'TractionTESTS.COM'
		);

        
		insert newAccount;

		Test.stopTest();

		accountResult = [
			SELECT Domain__c
			FROM Account
			WHERE Id = :newAccount.Id
			LIMIT 1
		];

		domainResult = [
			SELECT Domain_Name_URL__c
			FROM Domain__c
			WHERE Account__c = :newAccount.Id
			LIMIT 1
		];

		System.assert(accountResult != null); //Check if the account was successfully created
		System.assert(domainResult != null); //Check if the domain was successfully created
		SYstem.debug('Account URL: ' + accountResult.Domain__c + ' Domain URL: ' + domainResult.Domain_Name_URL__c);
		System.assertEquals(accountResult.Domain__c, domainResult.Domain_Name_URL__c); //Compare the two domain url values from account to domain
	}
	/*
	 * @description Tests the assignAccountToDomain method. Ensure that
	 *              the accounts are properly assigned to the domain.
	 *
	 * @author Majeda Mahfuz
	 * @company Traction on Demand
	 * @date 10-24-2014
	 */
	private static testmethod void updateAccountWithNoExistingDomain() {
		Domain__c domainResult;
		Test.startTest();

		Account newAccount = new Account(
			Name = 'Traction Test',
			Domain__c = 'TractionTESTS.COM'
		);

		insert newAccount;
		newAccount.Domain__c = 'TestTraction.COM';
		update newAccount;

		Test.stopTest();

		domainResult = [
			SELECT Domain_Name_URL__c
			FROM Domain__c
			WHERE Account__c = :newAccount.Id AND Domain_Name_URL__c =: newAccount.Domain__c
			LIMIT 1
		];

		System.assert(domainResult != null); //Check if the domain was successfully created
	}
	/*
	 * @description Tests the assignAccountToDomain method. Ensure that
	 *              the accounts are properly assigned to the domain. Also
	 *              determines that it uses the existing domain
	 *
	 * @author Thomas Tran
	 * @company Traction on Demand
	 * @date 09-24-2014
	 */
	private static testmethod void createAccountWithExistingDomain() {
		Account accountResult;
		List<Domain__c> domainResult;

		Domain__c newDomain = new Domain__c(
			Name = 'TractionTESTS.COM',
			Domain_Name_URL__c = 'tractiontests.com'
		);

		insert newDomain;

		Test.startTest();

		Account newAccount = new Account(
			Name = 'Traction Test',
			Domain__c = 'TractionTESTS.COM'
		);

		insert newAccount;

		Test.stopTest();

		domainResult = [
			SELECT Domain_Name_URL__c
			FROM Domain__c
		];

		accountResult = [
			SELECT Domain__c
			FROM Account
			WHERE Id = :newAccount.Id
			LIMIT 1
		];

		System.assert(domainResult.size() == 1); //Checks the the existing domains gets used
		System.assertEquals(accountResult.Domain__c, domainResult[0].Domain_Name_URL__c);

		
	}
	/*
	 * @description Tests the assignAccountToDomain method. Ensure that
	 *              the accounts are properly assigned to the domain. Also
	 *              determines that it uses the existing domain
	 *
	 * @author Majeda Mahfuz
	 * @company Traction on Demand
	 * @date 10-24-2014
	 */
	private static testmethod void updateAccountWithExistingDomain() {
		Domain__c domainResult;

		Domain__c newDomain = new Domain__c(
			Name = 'TractionTESTS.COM',
			Domain_Name_URL__c = 'tractiontests.com'
		);

		insert newDomain;

		Test.startTest();

		Account newAccount = new Account(
			Name = 'Traction Test',
			Domain__c = 'testTraction.COM'
		);
		insert newAccount;
		newAccount.Domain__c = 'TractionTESTS.COM';
		update newAccount;
		Test.stopTest();

		domainResult = [
			SELECT Domain_Name_URL__c, Account__c
			FROM Domain__c
			WHERE Id = :newDomain.Id
		];

		System.assertEquals(domainResult.Account__c, newAccount.Id);

		
	}

	private static testmethod void test_syncAccountLastActivityDateWithDomains() {		
		Domain__c newDomain = trac_TestUtils.createDomain('www.test.com');
		insert newDomain;

		Account newAcct = new Account();
		newAcct.Name = 'test account';
		newAcct.Domain__c = 'www.test.com';
		insert newAcct;

		List<Domain__c> lstDomains = new List<Domain__c>();
        lstDomains = [Select Id,Name,Last_Activity_Date__c,Account__c From Domain__c Limit 1 ];
        
        //check if domain is created or already exists
        System.assert(lstDomains.size()>0);
        System.assert(lstDomains[0].Name == 'www.test.com' );
        System.assert(lstDomains[0].Last_Activity_Date__c == null );
        System.assert(lstDomains[0].Account__c == newAcct.Id );

		User newUser = trac_TestUtils.createUser('test@tractioondemand.com.test', 'tst', 'firstName', 'lastName');
		Task newTask = trac_TestUtils.createTask(newAcct.Id, null, 'test subject', newUser.Id, 'Call', 'Completed', Date.today());
		insert newTask; 

		lstDomains = [Select Id,Name,Last_Activity_Date__c,Account__c From Domain__c Limit 1 ];
        
        //check if domain is created or already exists
        System.assert(lstDomains.size()>0);
        System.assert(lstDomains[0].Name == 'www.test.com' );
        //System.assert(lstDomains[0].Last_Activity_Date__c == newTask.ActivityDate );
        System.assert(lstDomains[0].Account__c == newAcct.Id );

	}

}