/**
 * Created by sdoucette on 12/7/2017.
 */

@isTest
public with sharing class trac_CasePopulatePlanTypeTest {
	private static Contact contact;
	private static Lead lead;

	private static void setup(){
		trac_TriggerHandlerBase.blockTrigger = true;
		trac_TestUtils.setupCollaboratorPackage();

		contact = new Contact(LastName = 'Test Contact', Org_Product_Name__c = 'Org Prod', ProductName__c = 'Prod');
		insert contact;

		lead = new Lead(LastName = 'Test Lead', Company = 'Test Company', Org_Product_Name__c = 'Org Prod', ProductName__c = 'Prod');
		insert lead;
		trac_TriggerHandlerBase.blockTrigger = false;
	}

	@IsTest
	private static void triggerHandler() {
		Exception resultException;

		Test.startTest();

		try {
			trac_TriggerHandlerBase triggerHandlerBase = new trac_TriggerHandlerBase();
			triggerHandlerBase.handleBeforeInsert();
			triggerHandlerBase.handleBeforeUpdate();
			triggerHandlerBase.handleBeforeDelete();

			triggerHandlerBase.handleAfterInsert();
			triggerHandlerBase.handleAfterUpdate();
			triggerHandlerBase.handleAfterDelete();
			triggerHandlerBase.handleAfterUndelete();
		} catch(Exception e) {
			resultException = e;
		}

		Test.stopTest();

		System.assertEquals(null, resultException);
	}

	@isTest
	public static void insertWithContactTest(){
		setup();

		// Test Org Product stamp
		Case testCase1 = new Case(ContactId = contact.Id);
		insert testCase1;

		Case testResult = [SELECT Plan_Type__c FROM Case WHERE Id = :testCase1.Id];
		System.assertEquals(contact.Org_Product_Name__c, testResult.Plan_Type__c);

		// Test Product Name stamp
		contact.Org_Product_Name__c = null;
		update contact;

		Case testCase2 = new Case(ContactId = contact.Id);
		insert testCase2;

		testResult = [SELECT Plan_Type__c FROM Case WHERE Id = :testCase2.Id];
		System.assertEquals(contact.ProductName__c, testResult.Plan_Type__c);

		// Test Free Stamp
		contact.ProductName__c = null;
		update contact;

		Case testCase3 = new Case(ContactId = contact.Id);
		insert testCase3;

		testResult = [SELECT Plan_Type__c FROM Case WHERE Id = :testCase3.Id];
		System.assertEquals(trac_CasePopulatePlanType.PLAN_TYPE_FREE, testResult.Plan_Type__c);
	}

	@isTest
	public static void insertWithLeadTest(){
		setup();

		// Test Org Product stamp
		Case testCase1 = new Case(Lead__c = lead.Id);
		insert testCase1;

		Case testResult = [SELECT Plan_Type__c FROM Case WHERE Id = :testCase1.Id];
		System.assertEquals(lead.Org_Product_Name__c, testResult.Plan_Type__c);

		// Test Product Name stamp
		lead.Org_Product_Name__c = null;
		update lead;

		Case testCase2 = new Case(Lead__c = lead.Id);
		insert testCase2;

		testResult = [SELECT Plan_Type__c FROM Case WHERE Id = :testCase2.Id];
		System.assertEquals(lead.ProductName__c, testResult.Plan_Type__c);

		// Test Free Stamp
		lead.ProductName__c = null;
		update lead;

		Case testCase3 = new Case(Lead__c = lead.Id);
		insert testCase3;

		testResult = [SELECT Plan_Type__c FROM Case WHERE Id = :testCase3.Id];
		System.assertEquals(trac_CasePopulatePlanType.PLAN_TYPE_FREE, testResult.Plan_Type__c);
	}

	@isTest
	public static void insertAndUpdateWithContactAndLeadTest(){
		setup();

		// We expect contact to win every time
		// Test Org Product stamp
		Case testCase1 = new Case(ContactId = contact.Id, Lead__c = lead.Id);
		insert testCase1;

		Case testResult = [SELECT Plan_Type__c FROM Case WHERE Id = :testCase1.Id];
		System.assertEquals(contact.Org_Product_Name__c, testResult.Plan_Type__c);

		// Test Product Name stamp
		contact.Org_Product_Name__c = null;
		update contact;

		Case testCase2 = new Case(ContactId = contact.Id, Lead__c = lead.Id);
		insert testCase2;

		testResult = [SELECT Plan_Type__c FROM Case WHERE Id = :testCase2.Id];
		System.assertEquals(contact.ProductName__c, testResult.Plan_Type__c);

		// Test Free Stamp
		contact.ProductName__c = null;
		update contact;

		Case testCase3 = new Case(ContactId = contact.Id, Lead__c = lead.Id);
		insert testCase3;

		testResult = [SELECT Plan_Type__c FROM Case WHERE Id = :testCase3.Id];
		System.assertEquals(trac_CasePopulatePlanType.PLAN_TYPE_FREE, testResult.Plan_Type__c);

		// Test losing contact
		testCase3.ContactId = null;
		update testCase3;

		testResult = [SELECT Plan_Type__c FROM Case WHERE Id = :testCase3.Id];
		System.assertEquals(lead.Org_Product_Name__c, testResult.Plan_Type__c);
	}

	@isTest
	public static void coverHandler(){
		setup();

		// Cover trac_TriggerHandlerBase for easy deployment
		Case c = new Case();
		insert c;
		delete c;
		undelete c;
		trac_TriggerHandlerBase.blockTrigger = true;
		delete c;
	}
}