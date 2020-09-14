@isTest(SeeAllData=false)
private class trac_ContactDomainAssignmentTest {
	
	/*
	 * @description Creating a new contact that creates a new domain.
	 */
	private testmethod static void assignDomainToContactAccountNetNew_Test() {
		List<Account> accountResultQuery = new List<Account>();
		List<Contact> contactResultQuery = new List<Contact>();
		List<Domain__c> domainResultQuery = new List<Domain__c>();

		Account newAccount = new Account(
			Name = 'Traction Test'
		);
		insert newAccount;
        

		Contact newContact = new Contact(
			Salutation = 'Mr.',
			FirstName = 'T1',
			LastName = 'Test',
			AccountId = newAccount.Id,
			Domain__c = 'test.ca'
		);

		Test.startTest();

		insert newContact;

		Test.stopTest();

		accountResultQuery = [
			SELECT Id
			FROM Account
		];

		contactResultQuery = [
			SELECT Id, AccountId, Domain_Lookup__c
			FROM Contact
		];

		domainResultQuery = [
			SELECT Id, Account__c
			FROM Domain__c
			WHERE Id = :contactResultQuery[0].Domain_Lookup__c
		];

		System.assertEquals(1, accountResultQuery.size());
		System.assertEquals(1, contactResultQuery.size());
		System.assert(!domainResultQuery.isEmpty());
		System.assertEquals(accountResultQuery[0].Id, domainResultQuery[0].Account__c);
		System.assertEquals(domainResultQuery[0].Id, contactResultQuery[0].Domain_Lookup__c);

	}
	/*
	 * @description Tests assigning domain on contact update
	 *
	 * @author Majeda Mahfuz
	 * @company Traction on Demand
	 * @date 10-24-2014
	 */
	private testmethod static void onUpdateassignDomainToContactAccountNetNew_Test() {
		Contact contactResult;
		List<Domain__c> domainResult = new List<Domain__c>();
		system.debug(LoggingLevel.ERROR, 'line 64');
		Account newAccount = new Account(
			Name = 'Traction Test'
		);
		insert newAccount;

		Contact newContact = new Contact(
			Salutation = 'Mr.',
			FirstName = 'T1',
			LastName = 'Test',
			AccountId = newAccount.Id
		);
		insert newContact;
		newContact.Domain__c = 'test2.ca';
		update newContact;
		system.debug(LoggingLevel.ERROR, 'newContact.Domain__c ' + newContact.Domain__c);

		contactResult = [
			SELECT Id, AccountId, Domain_Lookup__c, Domain__c
			FROM Contact
			WHERE Id = :newContact.Id
		];
		system.debug(LoggingLevel.ERROR, ' contactResult ' + contactResult.Domain__c + ', ' + contactResult.Domain_Lookup__c);
		domainResult = [
			SELECT Id, Account__c, Domain_Name_URL__c
			FROM Domain__c
			WHERE Domain_Name_URL__c = :contactResult.Domain__c
		];
		system.debug(LoggingLevel.ERROR, domainResult);

		System.assertEquals(domainResult[0].Id, contactResult.Domain_Lookup__c);
		System.assertEquals(domainResult[0].Account__c, contactResult.AccountId);

	}
	/*
	 * @description Creating a new contact to an existing domain with a different account.
	 */
	private testmethod static void assignDomainToContactAccountExistingDomainDifferentAccount_Test() {
		try{
			Account newAccount = new Account(
				Name = 'Traction Test'
			);

			insert newAccount;

			Account newAccount2 = new Account(
				Name = 'Traction Test2'
			);

			insert newAccount2;

			Domain__c newDomain = new Domain__c(
				Name = 'Traction Test Domain',
				Domain_Name_URL__c = 'test.ca',
				Account__c = newAccount2.Id
			);

			insert newDomain;

			Contact newContact = new Contact(
				Salutation = 'Mr.',
				FirstName = 'T1',
				LastName = 'Test',
				AccountId = newAccount.Id,
				Domain__c = 'test.ca'
			);

			Test.startTest();

			insert newContact;

			Test.stopTest();
		} catch(Exception ex){
			System.assert(ex.getMessage().contains('The domain is currently associated with another account.'));
		}
	}

	/*
	 * @description Creating a new contact to an existing domain url with matching account.
	 */
	private testmethod static void assignDomainToContactAccountExistingDomain_Test() {
		List<Contact> contactList = new List<Contact>();

		Account newAccount = new Account(
			Name = 'Traction Test'
		);

		insert newAccount;

		Domain__c newDomain = new Domain__c(
			Name = 'Traction Test Domain',
			Domain_Name_URL__c = 'test.ca',
			Account__c = newAccount.Id
		);

		insert newDomain;

		Contact newContact = new Contact(
			Salutation = 'Mr.',
			FirstName = 'T1',
			LastName = 'Test',
			AccountId = newAccount.Id,
			Domain__c = 'test.ca'
		);

		Test.startTest();

		insert newContact;

		Test.stopTest();

		contactList = [
			SELECT Id, Domain_Lookup__c
			FROM Contact
		];

		System.assertEquals(1, contactList.size());
		System.assertEquals(newDomain.Id, contactList[0].Domain_Lookup__c);
	}
	
}