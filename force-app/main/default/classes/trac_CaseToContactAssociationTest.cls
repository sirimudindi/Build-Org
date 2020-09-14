/**
 * trac_CaseToContactAssociationTest.cls
 * @description tests trac_CaseToContactAssociation
 *              Leads with the created Contact
 * @author      Mike Fransblow
 * @company     Traction On Demand
 * @date        Mon Jun  6 10:31:43 2016
 */

@isTest
private class trac_CaseToContactAssociationTest {

	static {
		trac_TestUtils.setupCollaboratorPackage();
	}

	/*
	  Add Lead, add Case to Lead, save, convert Lead to Contact, check that Case is attached to Contact
	 */
	private static testmethod void testCaseToContactAssociation() {

		Test.startTest();

		// Create the lead
		Lead testLead = trac_TestUtils.createLead('TestLead', 'TestCompany', 'traction.com');
		testLead.Email = 'foo@bar.com';
		insert testLead;
		Id leadId = testLead.Id;

		// Create List of cases to insert
		// Note this should trigger the Case To Lead Association such that each Case has custom field Lead__c populated with Lead lookup
		List<Case> casesToAdd = new List<Case>();
		Case testCase1 = trac_TestUtils.createCase('In Progress', 'Phone', 'foo@bar.com', 'Foo Bar1');
		casesToAdd.add(testCase1);
		Case testCase2 = trac_TestUtils.createCase('Closed', 'Phone', 'foo@bar.com', 'Foo Bar2');
		casesToAdd.add(testCase2);
		Case testCase3 = trac_TestUtils.createCase('Closed', 'Phone', 'foo@bar.com', 'Foo Bar3');
		casesToAdd.add(testCase3);

		insert casesToAdd;

		// get a reference to all newly created Cases
		List<Id> newCaseIds = new List<Id>();
		for (Case caseObj : casesToAdd) {
			newCaseIds.add(caseObj.Id);
		}

		List<Lead> leads = [
				Select Id
				From Lead
				Where Id = :leadId
		];
		List<Case> cases = [
				Select Id, Lead__c, ContactId
				From Case
				Where Id IN :newCaseIds
		];

		// Ensure that each case has Lead__c assocation populated to Lead
		for (Case c : cases) {
			System.assertEquals(c.Lead__c, leadId, 'New case Lead__c should be same as Lead Id');
		}

		// Convert the Lead
		Database.LeadConvert lc = new database.LeadConvert();
		lc.setLeadId(leadId);
		lc.setDoNotCreateOpportunity(true);

		LeadStatus convertStatus = [
				Select Id, MasterLabel
				from LeadStatus
				where IsConverted = true
				limit 1
		];
		lc.setConvertedStatus(convertStatus.MasterLabel);

		Database.LeadConvertResult lcr = Database.convertLead(lc);
		System.assert(lcr.isSuccess());

		// Get the updated Lead, Case and converted Contact
		leads = [
				Select Id, FirstName, LastName, ConvertedContactId
				From Lead
				Where Id = :leadId
		];
		List<Contact> contacts = [
				Select Id
				From Contact
				Where Id = :lcr.getContactId()
		];
		List<Case> convertedCases = [
				Select Id, Lead__c, Original_Case_Lead__c, ContactId
				From Case
				Where Id IN :newCaseIds
		];

		// Iterate over the converted Cases and ensure that the contact Id matches the newly created Contact
		String testFNLN = '';
		for (Case c : convertedCases) {
			System.assertEquals(c.ContactId, contacts[0].Id, 'Contact should have been updated with converted Contact\'s Id');
			System.assertEquals(leads[0].ConvertedContactId, c.ContactId, 'Cases should have been updated with Lead\'s ConvertedContactId');
			testFNLN = leads[0].FirstName + ' ' + leads[0].LastName;
			System.assertEquals(testFNLN, c.Original_Case_Lead__c, 'Cases should have Original_Case_Lead__c marked with Lead firstname/lastname');
			System.assertEquals(null, c.Lead__c, 'Case Lead lookup using Lead__c should have been nullified');
		}

		Test.stopTest();

	}

}