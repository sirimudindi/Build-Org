/**
 * Test class for trac_CaseEntitlementsAssociation
 *
 * @author Steve Doucette
 * @company Traction on Demand
 * @version 1.0
 * @date 2018/10/01
**/
@isTest
public with sharing class trac_CaseEntitlementsAssociationTest {

	private static final String NAME_TEST = 'Test';
	private static final String EMAIL_TEST = 'Test@smartsheet.test.com';

	private static final Date TODAY = Date.today();

	private static Account account;
	private static Contract contract;
	private static Entitlement entitlement;

	static {
		User u = trac_TestUtils.createUser(EMAIL_TEST, NAME_TEST, NAME_TEST, NAME_TEST);

		account = trac_TestUtils.createAccount();
		insert account;

		trac_TestUtils.StandardPricebookPackage spp = trac_TestUtils.createStandardPricebookPackage();

		contract = trac_TestUtils.createContract(account.Id, 1);
		insert contract;

		Asset asset = trac_TestUtils.createAsset(spp.prod.Id, contract.Id, account.Id);
		insert asset;

		SlaProcess sla = [
				SELECT Id
				FROM SlaProcess
				WHERE IsActive = TRUE
				LIMIT 1
		];

		entitlement = trac_TestUtils.createEntitlement(account);
		entitlement.Name = trac_TestUtils.DEFAULT_ENTITLEMENT_NAME;
		entitlement.SlaProcessId = sla.Id;
		entitlement.StartDate = TODAY.addDays(-1);
		entitlement.EndDate = TODAY.addYears(1);
		insert entitlement;

		EntitlementTemplate template;
		System.runAs(u) {
			template = new EntitlementTemplate(Name = NAME_TEST, SlaProcessId = sla.Id);
			insert template;
		}

		insert new ProductEntitlementTemplate(EntitlementTemplateId = template.Id, Product2Id = spp.prod.Id);
	}

	@isTest
	public static void testCaseForContact() {
		account.Name = trac_Constants.THIS_MONTH_ACCOUNT_NAME;
		update account;

		Contact con = trac_TestUtils.createContact(NAME_TEST, EMAIL_TEST, account);
		con.Plan__c = contract.Id;
		con.PaymentProfileId__c = '1234';
		con.Organization_Roles__c = 'Example Organization Role';
		insert con;

		Test.startTest();
		Case c = trac_TestUtils.createCase(trac_Constants.CASE_STATUS_CLOSED, trac_Constants.CASE_ORIGIN_PHONE, EMAIL_TEST, NAME_TEST);
		c.ContactId = con.Id;
		insert c;

		Contact otherContact = trac_TestUtils.createContact(NAME_TEST, EMAIL_TEST, account);
		otherContact.Plan__c = contract.Id;
		insert otherContact;

		c.ContactId = otherContact.Id;
		update c;
		Test.stopTest();

		Case result = [
				SELECT EntitlementId
				FROM Case
				WHERE Id = :c.Id
		];
		System.assertEquals(entitlement.Id, result.EntitlementId);
	}

	@isTest
	public static void testCaseForLead() {
		account.Name = trac_Constants.THIS_MONTH_ACCOUNT_NAME;
		update account;

		Lead l = trac_TestUtils.createLead(NAME_TEST, EMAIL_TEST, NAME_TEST);
		l.Plan__c = contract.Id;
		l.PaymentProfileId__c = '1234';
		insert l;

		Test.startTest();
		Case c = trac_TestUtils.createCase(trac_Constants.CASE_STATUS_CLOSED, trac_Constants.CASE_ORIGIN_PHONE, EMAIL_TEST, NAME_TEST);
		c.Lead__c = l.Id;
		insert c;

		Lead otherLead = trac_TestUtils.createLead(NAME_TEST, EMAIL_TEST, NAME_TEST);
		otherLead.Plan__c = contract.Id;
		insert otherLead;

		c.Lead__c = otherLead.Id;
		update c;
		Test.stopTest();

		Case result = [
				SELECT EntitlementId
				FROM Case
				WHERE Id = :c.Id
		];
		System.assertEquals(entitlement.Id, result.EntitlementId);
	}

	@IsTest
	static void testCollaboratorFlowThisMonthExists() {
		Account acc = trac_TestUtils.createAccount();
		acc.Name = trac_Constants.THIS_MONTH_ACCOUNT_NAME;
		insert acc;

		Lead collaborator = trac_TestUtils.createLead('Test Name', 'Test Company', 'Test Domain');
		insert collaborator;

		Entitlement e = trac_TestUtils.createEntitlement(acc);
		e.Name = trac_TestUtils.DEFAULT_ENTITLEMENT_NAME;
		e.AccountId = acc.Id;
		insert e;

		Test.startTest();
		Case c = new Case(Lead__c = collaborator.Id);
		insert c;
		Test.stopTest();

		// Check that case has the default entitlement and that this months account has been created
		Case result = [
				SELECT Id, EntitlementId
				FROM Case
				WHERE Id = :c.Id
		];
		List<Account> collaboratorAccounts = [
				SELECT Id
				FROM Account
				WHERE Name = :trac_Constants.THIS_MONTH_ACCOUNT_NAME
		];
	}

	@IsTest
	static void testCollaboratorFlowOnlyLastMonthExists() {
		// Check that no account for this month exists yet
		List<Account> collaboratorAccounts = [
				SELECT Id
				FROM Account
				WHERE Name = :trac_Constants.THIS_MONTH_ACCOUNT_NAME
		];
		System.assertEquals(0, collaboratorAccounts.size());

		// Create last months account to be copied through trigger
		Account acc = trac_TestUtils.createAccount();
		acc.Name = trac_Constants.LAST_MONTH_ACCOUNT_NAME;
		insert acc;

		Lead collaborator = trac_TestUtils.createLead('Test Name', 'Test Company', 'Test Domain');
		insert collaborator;

		Entitlement e = trac_TestUtils.createEntitlement(acc);
		e.Name = trac_TestUtils.DEFAULT_ENTITLEMENT_NAME;
		e.AccountId = acc.Id;
		insert e;

		Test.startTest();
		Case c = new Case(Lead__c = collaborator.Id);
		insert c;
		Test.stopTest();

		// Check that case has the default entitlement and that this months account has been created
		Case result = [
				SELECT Id, EntitlementId
				FROM Case
				WHERE Id = :c.Id
		];
		collaboratorAccounts = [
				SELECT Id
				FROM Account
				WHERE Name = :trac_Constants.THIS_MONTH_ACCOUNT_NAME
		];
	}

	@IsTest
	static void testCollaboratorFlowNoCollaboratorAccounts() {
		Lead collaborator = trac_TestUtils.createLead('Test Name', 'Test Company', 'Test Domain');
		insert collaborator;
		try {
			Test.startTest();
			Case c = new Case(Lead__c = collaborator.Id);
			trac_CaseNewCollaborator.execute(new List<Case>{
					c
			});
			Test.stopTest();
		} catch (trac_CaseNewCollaborator.NoAccountsFoundException e) {
			System.assert(true);
		} catch (Exception ex) {
			System.assert(false, 'Expected No Accounts Found Exception to be thrown.');
		}
	}
}