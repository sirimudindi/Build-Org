@isTest(SeeAllData=false)
private class trac_ActivityRelatedListCtlrTest {
	
	private testmethod static void createTaskList() {
		Lead leadResult = new Lead();
		Opportunity oppResult = new Opportunity();
		LeadStatus convertedResult = new LeadStatus();

		Lead newLead = new Lead(
			Salutation = 'Mr.',
			FirstName = 'Test',
			LastName = 'Traction',
			Company = 'Test Company',
			Status = 'New',
			Domain__c = 'test.ca',
			LeadSource = 'External Referral'
		);
        

		insert newlead;

		Task newTask = new Task(
			Subject = 'Test',
			Priority = 'Normal',
			Status = 'Closed',
			WhoId = newlead.Id,
			ActivityDate = Date.today()
		);

		insert newTask;

		convertedResult = [
			SELECT MasterLabel
			FROM LeadStatus
			WHERE IsConverted = true
			LIMIT 1
		];

		Database.LeadConvert lc = new Database.LeadConvert();
		lc.setLeadId(newLead.Id);
		lc.setDoNotCreateOpportunity(false);
		lc.setConvertedStatus(convertedResult.MasterLabel);

		Database.LeadConvertResult lcr = Database.convertLead(lc);

		Domain__c existingDomain = [
			SELECT Id
			FROM Domain__c
			WHERE Domain_Name_URL__c = :newLead.Domain__c
		];

		Lead existingLead = [
			SELECT Id, ConvertedOpportunityId, ConvertedContactId
			FROM Lead
			WHERE Domain_Lookup__c = :existingDomain.Id
			LIMIT 1
		];

		Task newTask2 = new Task(
			Subject = 'Test',
			Priority = 'Normal',
			Status = 'Closed',
			WhatId = existingLead.ConvertedOpportunityId,
			ActivityDate = Date.today()
		);

		insert newTask2;

		Task newTask3 = new Task(
			Subject = 'Test',
			Priority = 'Normal',
			Status = 'Closed',
			WhoId = existingLead.ConvertedContactId,
			ActivityDate = Date.today()
		);

		insert newTask3;

		ApexPages.StandardController sc = new ApexPages.standardController(existingDomain);

		Test.startTest();

		trac_ActivityRelatedListCtlr taskTest = new trac_ActivityRelatedListCtlr(sc);
		List<Task> taskResults = taskTest.getTasks();
		taskTest.beginning();
		taskTest.previous();
		taskTest.next();
		taskTest.end();
		taskTest.getDisablePrevious();
		taskTest.getDisableNext();
		taskTest.getTotal_size();
		taskTest.getPageNumber();
		taskTest.getTotalPages();

		Test.stopTest();
		System.assertEquals('Closed', taskResults[0].Status);
		System.assertEquals('Closed', taskResults[1].Status);

	}

	
}