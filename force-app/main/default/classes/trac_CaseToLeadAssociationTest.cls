/**
 *
 * trac_CaseToLeadAssociationTest.cls
 * @description Tests methods in trac_CaseToLeadAssociation.cls
 * @author      Mike Fransblow
 * @company     Traction On Demand
 * @date        Mon May 16 15:53:02 2016
 */

@isTest(SeeAllData=false)
private class trac_CaseToLeadAssociationTest {

	public static final Integer LEADS_TO_CREATE = 10;
	public static final Integer CASES_TO_CREATE = 10;
	public static final Integer CONTACTS_TO_CREATE = 10;

	static {
		trac_TestUtils.setupCollaboratorPackage();
	}

	/*
	  Add 10 Leads, save, add 10 Cases with same email addresses as Leads inserted,
	  ensure Case.Lead__c is populated
	 */
	private static testmethod void testCaseLeadAssociation() {

		// create 10 test Leads which will match against email address in new cases created below
		List<Lead> newLeads = new List<Lead>();
		for (Integer j = 0; j < LEADS_TO_CREATE; j++) {
			Lead ld = trac_TestUtils.createLead('LastNameTest' + j, 'testCompany' + j, 'traction.com' + j);
			ld.Email = 'FOO@BAR.COM' + j;
			newLeads.add(ld);
		}

		Test.startTest();

		insert newLeads;

		System.assert(newLeads.size() == LEADS_TO_CREATE, 'There should have been ' + LEADS_TO_CREATE + ' Leads created');

		// create 10 test Cases with same email address as those created in newLeads
		List<Case> newCases = new List<Case>();
		for (Integer k = 0; k < CASES_TO_CREATE; k++) {
			Case c = trac_TestUtils.createCase('new', 'Email', 'foo@bar.com' + k, 'Foo Bar' + k);
			newCases.add(c);
		}

		insert newCases;

		System.assert(newCases.size() == CASES_TO_CREATE, 'There should have been ' + CASES_TO_CREATE + ' Cases created');

		// get a reference to all newly created Cases
		List<Id> newCaseIds = new List<Id>();
		for (Case caseObj : newCases) {
			newCaseIds.add(caseObj.Id);
		}

		List<Case> updatedCases = [
				Select Id, Lead__c, ContactId
				From Case
				Where Id in :newCaseIds
		];

		// Verify each match on Lead was associated
		for (Case caseObj : updatedCases) {
			System.assert(caseObj.Lead__c != null, 'Case.Lead__c should not be null');
			System.assert(caseObj.ContactId == null, 'Case.ContactId should not be null');
		}

		test.stopTest();

	}

	/*
	  Add 10 Leads all with the same email address, save, add 10 Cases with same email address as Leads inserted,
	  ensure Case.Lead__c is not populated
	 */
	private static testmethod void testCaseMultipleLeadAssociation() {

		// create 10 test Leads which will match against email address in new cases created below
		List<Lead> newLeads = new List<Lead>();
		for (Integer j = 0; j < LEADS_TO_CREATE; j++) {
			Lead ld = trac_TestUtils.createLead('LastNameTest' + j, 'testCompany' + j, 'traction.com' + j);
			ld.Email = 'FOO@BAR.COM';
			newLeads.add(ld);
		}

		Test.startTest();

		insert newLeads;

		System.assert(newLeads.size() == LEADS_TO_CREATE, 'There should have been ' + LEADS_TO_CREATE + ' Leads created');

		// create 10 test Cases with same email address as those created in newLeads
		List<Case> newCases = new List<Case>();
		for (Integer k = 0; k < CASES_TO_CREATE; k++) {
			Case c = trac_TestUtils.createCase('new', 'Email', 'foo@bar.com', 'Foo Bar' + k);
			newCases.add(c);
		}
		insert newCases;

		System.assert(newCases.size() == CASES_TO_CREATE, 'There should have been ' + CASES_TO_CREATE + ' Cases created');

		// get a reference to all newly created Cases
		List<Id> newCaseIds = new List<Id>();
		for (Case caseObj : newCases) {
			newCaseIds.add(caseObj.Id);
		}

		List<Case> updatedCases = [
				Select Id, Lead__c, ContactId
				From Case
				Where Id in :newCaseIds
		];

		// Verify each match on Lead was associated
		for (Case caseObj : updatedCases) {
			System.assert(caseObj.Lead__c == null, 'Case should not have been associated with a Lead');
			System.assert(caseObj.ContactId == null, 'Case should not have been associated with a Contact');
		}

		test.stopTest();

	}

}