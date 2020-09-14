/***
* @author: Christian Wico - cwico@tractionondemand.com
* @description: Unit test for trac_LeadConvertCtlr.cls
* @modifiedBy Sergei Dobrianski - sdobrianski@tractionondemand.com
*/
@isTest
private class trac_LeadConvertCtlr_Test {


	@isTest static void testConvertHandleException() {
		Test.startTest();
		Domain__c d = trac_TestUtils.createDomainWithAccount('Test Account','tractionondemand.com', 'www.tractionondemand.com');

		Lead l = trac_TestUtils.createLead('Unit', 'Test', null);
		insert l;
        

		l.Domain_Lookup__c = d.Id;
		update l;

		PageReference pageRef = Page.trac_LeadConvert;

		Test.setCurrentPage(pageRef);
		
		ApexPages.StandardController sc = new ApexPages.StandardController(l);
		ApexPages.currentPage().getParameters().put('Id', l.Id);

		trac_LeadConvertCtlr ctlr = new trac_LeadConvertCtlr(sc);
		ctlr.accountName = 'Unit Test';

		delete l; // should throw an exception

		Exception ex = null;
		try {
			PageReference pr = ctlr.convertLead();
		}
		catch (Exception e) {
			ex = e;
			System.debug('Should throw exception: ' + e);
		}

		// assert that exception exist
		System.assert(ex != null);
		Test.stopTest();
	}
	
	@isTest static void testConvert() {
		Lead l = trac_TestUtils.createLead('Unit', 'Test', 'tractionondemand.com');
		insert l;

		PageReference pageRef = Page.trac_LeadConvert;

		Test.setCurrentPage(pageRef);
		
		ApexPages.StandardController sc = new ApexPages.StandardController(l);
		ApexPages.currentPage().getParameters().put('Id', l.Id);

		trac_LeadConvertCtlr ctlr = new trac_LeadConvertCtlr(sc);
		ctlr.accountName = 'Unit Test';

		PageReference pr = ctlr.convertLead();
		
		System.assert(pr != null);
		
		System.debug(pr.getUrl());
		// assert that it's being redirected to the accountName
		System.assert(pr.getUrl().startsWith('/001'));
		
		Lead convertedLead = [SELECT Id, ConvertedAccountId, ConvertedOpportunityId, ConvertedContactId FROM Lead WHERE IsConverted=true AND Id=:l.Id LIMIT 1];
		
		// asset that an account is created
		System.assert(convertedLead.ConvertedAccountId != null);
		// asset that an opportunity is created
		System.assert(convertedLead.ConvertedOpportunityId != null);
		// asset that a contact is created
		System.assert(convertedLead.ConvertedContactId != null);

		System.assertEquals([SELECT OwnerId FROM Lead WHERE Id = :l.Id].OwnerId, [SELECT OwnerId FROM Opportunity].OwnerId);
	}

	@isTest static void testConvertOnlyReqiredLead() {
		List<Lead> leadsToConvert = new List<Lead>();

		for (Integer i = 0; i < 5; i++) {
			Lead l = trac_TestUtils.createLead('Name', 'Account', 'domain.name', '0123456');
			leadsToConvert.add(l);
		}	

		insert leadsToConvert;

		PageReference pr = Page.trac_LeadConvert;
		Test.setCurrentPage(pr);

		ApexPages.StandardController sc = new ApexPages.StandardController(leadsToConvert[0]);
		ApexPages.currentPage().getParameters().put('Id', leadsToConvert[0].Id);

		trac_LeadConvertCtlr ctrl = new trac_LeadConvertCtlr(sc); 
		ctrl.convertLead();
		List<Lead> convertedLead = [SELECT Id, ConvertedAccountId, ConvertedOpportunityId, ConvertedContactId, parentPaymentProfileID__c 
							  FROM Lead WHERE IsConverted=true AND parentPaymentProfileID__c = '0123456'];
		System.assertEquals(1, convertedLead.size());					  
	}

	@isTest static void testConvertNoOpp() {
		Test.startTest();
		Lead l = trac_TestUtils.createLead('Unit', 'Test', 'tractionondemand.com');
		insert l;

		PageReference pageRef = Page.trac_LeadConvert;

		Test.setCurrentPage(pageRef);
		
		ApexPages.StandardController sc = new ApexPages.StandardController(l);
		ApexPages.currentPage().getParameters().put('Id', l.Id);

		trac_LeadConvertCtlr ctlr = new trac_LeadConvertCtlr(sc);
		ctlr.accountName = 'Unit Test';
		ctlr.dontCreateOpp = true;

		PageReference pr = ctlr.convertLead();
		
		System.assert(pr != null);
		
		Lead convertedLead = [SELECT  ConvertedOpportunityId FROM Lead WHERE IsConverted=true AND Id=:l.Id LIMIT 1];

		// asset that an opportunity is created
		System.assert(convertedLead.ConvertedOpportunityId == null);
		Test.stopTest();
	}

	@isTest static void testConvertDomainWithAccount() {
		Test.startTest();
		Domain__c d = trac_TestUtils.createDomainWithAccount('Test Account','tractionondemand.com', 'www.tractionondemand.com');

		Lead l = trac_TestUtils.createLead('Unit', 'Test', null);
		insert l;

		l.Domain_Lookup__c = d.Id;
		update l;

		PageReference pageRef = Page.trac_LeadConvert;

		Test.setCurrentPage(pageRef);
		
		ApexPages.StandardController sc = new ApexPages.StandardController(l);
		ApexPages.currentPage().getParameters().put('Id', l.Id);

		trac_LeadConvertCtlr ctlr = new trac_LeadConvertCtlr(sc);
		ctlr.accountName = 'Unit Test';
		ctlr.dontCreateOpp = true;

		PageReference pr = ctlr.convertLead();
		
		System.assert(pr != null);
		
		Lead convertedLead = [SELECT  ConvertedAccountId FROM Lead WHERE IsConverted=true AND Id=:l.Id LIMIT 1];

		// assert that the converted account was the domain's account
		System.assert(convertedLead.ConvertedAccountId == d.Account__c);

		Test.stopTest();
	}

	@isTest static void testConvertOwnedByQueue() {
		Test.startTest();
		// insert group		

		User u1 = trac_TestUtils.createUser('testFirstLast@tes.com', 'alia', 'userFirstName', 'LastName');

		System.runAs(u1) {

			Group g = new Group(Name='Test Group Name', Type='Queue');
			insert g;

			// insert queue
			QueuesObject q= new QueuesObject(QueueId=g.id, SobjectType='Lead');
			insert q;
		}

		// get created queue
		QueuesObject qRecord = [SELECT Id, QueueId, Queue.Name, SobjectType FROM QueueSobject WHERE SobjectType = 'Lead' LIMIT 1];

		Domain__c d = trac_TestUtils.createDomainWithAccount('Test Account','tractionondemand.com', 'www.tractionondemand.com');

		Lead l = trac_TestUtils.createLead('Unit', 'Test', null);
		insert l;

		// set the owner of the lead as queue
		l.OwnerId = qRecord.QueueId;
		update l;

		PageReference pageRef = Page.trac_LeadConvert;

		Test.setCurrentPage(pageRef);
		
		ApexPages.StandardController sc = new ApexPages.StandardController(l);
		ApexPages.currentPage().getParameters().put('Id', l.Id);

		trac_LeadConvertCtlr ctlr = new trac_LeadConvertCtlr(sc);
		ctlr.accountName = 'Unit Test';

		PageReference pr = ctlr.convertLead();
		
		Lead convertedLead = [SELECT  ConvertedContactId, ConvertedOpportunityId, ConvertedAccountId FROM Lead WHERE IsConverted=true AND Id=:l.Id LIMIT 1];

		Account a = [SELECT OwnerId FROM Account WHERE Id=:convertedLead.ConvertedAccountId LIMIT 1];
		Contact c = [SELECT OwnerId FROM Contact WHERE Id=:convertedLead.ConvertedContactId LIMIT 1];
		Opportunity o = [SELECT OwnerId FROM Opportunity WHERE Id=:convertedLead.ConvertedOpportunityId LIMIT 1];

		// assert that the owners of the converted records  is the current user
		System.assert(a.OwnerId == UserInfo.getUserId());
		System.assert(c.OwnerId == UserInfo.getUserId());
		System.assert(o.OwnerId == UserInfo.getUserId());
		Test.stopTest();
	}
	

	// test convert lead with status that is not Accepted
	@isTest static void testConvertNotAcceptedStatus() {
		Test.startTest();
		Domain__c d = trac_TestUtils.createDomain('tractionondemand.com');
		insert d;

		Lead l = trac_TestUtils.createLead('Unit', 'Test', null);
		insert l;

		l.Status = 'New';
		l.LeadSource = 'Inbound Call';
		l.Domain_Lookup__c = d.Id;

		update l;

		PageReference pageRef = Page.trac_LeadConvert;

		Test.setCurrentPage(pageRef);
		
		ApexPages.StandardController sc = new ApexPages.StandardController(l);
		ApexPages.currentPage().getParameters().put('Id', l.Id);

		trac_LeadConvertCtlr ctlr = new trac_LeadConvertCtlr(sc);
		ctlr.accountName = 'Unit Test';

		PageReference pr = ctlr.convertLead();
		
		Lead convertedLead = [SELECT Status FROM Lead WHERE IsConverted=true AND Id=:l.Id LIMIT 1];

		Domain__c dom = [SELECT Name, Account__c, Account__r.Name FROM Domain__c  WHERE Id =:d.Id LIMIT 1];
		
		// assert that the converted lead status was changed to Accepted from New
		System.assert(convertedLead.Status == 'Accepted');
		Test.stopTest();
	}

	@isTest static void testConvertDomainWithNoAccount() {
		Test.startTest();
		Domain__c d = trac_TestUtils.createDomain('tractionondemand.com');
		insert d;

		Lead l = trac_TestUtils.createLead('Unit', 'Test', null);
		insert l;

		l.Domain_Lookup__c = d.Id;
		update l;

		PageReference pageRef = Page.trac_LeadConvert;

		Test.setCurrentPage(pageRef);
		
		ApexPages.StandardController sc = new ApexPages.StandardController(l);
		ApexPages.currentPage().getParameters().put('Id', l.Id);

		trac_LeadConvertCtlr ctlr = new trac_LeadConvertCtlr(sc);
		ctlr.accountName = 'Unit Test';

		PageReference pr = ctlr.convertLead();
		
		Lead convertedLead = [SELECT ConvertedAccountId FROM Lead WHERE IsConverted=true AND Id=:l.Id LIMIT 1];

		Domain__c dom = [SELECT Name, Account__c, Account__r.Name FROM Domain__c  WHERE Id =:d.Id LIMIT 1];
		
		System.assertEquals([SELECT Domain_Name_URL__c FROM Domain__c].Domain_Name_URL__c, [SELECT Domain__c FROM Account].Domain__c);

		// assert that thge converted account is assigned to the domain
		System.assert(convertedLead.ConvertedAccountId == dom.Account__c);
		Test.stopTest();
	}


	@isTest static void testConvertNoDomain() {
		Test.startTest();
		Lead l = trac_TestUtils.createLead('Unit', 'Test', null);
		insert l;

		PageReference pageRef = Page.trac_LeadConvert;

		Test.setCurrentPage(pageRef);
		
		ApexPages.StandardController sc = new ApexPages.StandardController(l);
		ApexPages.currentPage().getParameters().put('Id', l.Id);

		trac_LeadConvertCtlr ctlr = new trac_LeadConvertCtlr(sc);

		System.assert(ApexPages.hasMessages());
		Test.stopTest();
	}

	private static testMethod void test_leadConvertWithAttachedLeads(){
        Lead newLead1 = trac_TestUtils.createLead('Last name one', 'test Company', 'www.test.com');
        newLead1.parentPaymentProfileID__c = '777';
        newLead1.Status = 'Accepted';
        newLead1.LeadSource = 'Desk.com';
        insert newLead1;

        trac_TestUtils.resetCodeExecution();
        User newUser = trac_TestUtils.createUser('test@tractioondemand.com.test', 'tst', 'firstName', 'lastName');

        Task newTask = trac_TestUtils.createTask(null, newLead1.Id, 'test subject', newUser.Id, 'Call', 'Completed', Date.today());
        insert newTask; 
        trac_TestUtils.resetCodeExecution();
        update newLead1;

        trac_TestUtils.resetCodeExecution();
        Lead newLead2 = trac_TestUtils.createLead('Last name two', 'test Company', 'www.test.com');
        newLead2.parentPaymentProfileID__c = '777';
        insert newLead2;

        trac_TestUtils.resetCodeExecution();
        Lead newLead3 = trac_TestUtils.createLead('Last name three', 'test Company', 'www.test.com');
        newLead3.parentPaymentProfileID__c = '777';
        insert newLead3;

        newLead1 = [Select Id,LastName,Company, Domain_Lookup__c, Domain__c,Last_Activity_Date__c,LastActivityDate, Qualified_for_Conversion__c From Lead Where Id=: newLead1.Id];

        ApexPages.StandardController sc = new ApexPages.StandardController(newLead1);
        trac_LeadConvertCtlr tl = new trac_LeadConvertCtlr(sc);
        tl.convertLead();

        System.assert(tl.oppId !=null);
        List<OpportunityContactRole> lstOCR = new List<OpportunityContactRole>();
        lstOCR = [Select ContactId From OpportunityContactRole Where OpportunityID =: tl.oppId];
        System.assert(lstOCR.size() == 1);

    }
    

 	@isTest static void convertLeadRemainingLeadOwnerByQueue() {
		Test.startTest();
		// insert group		

		User u1 = trac_TestUtils.createUser('testFirstLast@tes.com', 'alia', 'userFirstName', 'LastName');

		System.runAs(u1) {

			Group g = new Group(Name='Test Group Name', Type='Queue');
			insert g;

			// insert queue
			QueuesObject q= new QueuesObject(QueueId=g.id, SobjectType='Lead');
			insert q;
		}

		// get created queue
		QueuesObject qRecord = [SELECT Id, QueueId, Queue.Name, SobjectType FROM QueueSobject WHERE SobjectType = 'Lead' LIMIT 1];

		Domain__c d = trac_TestUtils.createDomainWithAccount('Test Account','tractionondemand.com', 'www.tractionondemand.com');

		Lead l = trac_TestUtils.createLead('Unit', 'Test', null);
		insert l;

		// set the owner of the lead as queue
		l.OwnerId = qRecord.QueueId;
		l.parentPaymentProfileID__c = '0123456';
		update l;

		lead lead2 = trac_TestUtils.createLead('Unit', 'Test', null);
		lead2.parentPaymentProfileID__c = '0123456';
		lead2.OwnerId = qRecord.QueueId;
		insert lead2;

		System.assertEquals(l.OwnerId, qRecord.QueueId);

		PageReference pageRef = Page.trac_LeadConvert;

		Test.setCurrentPage(pageRef);
		
		ApexPages.StandardController sc = new ApexPages.StandardController(l);
		ApexPages.currentPage().getParameters().put('Id', l.Id);

		trac_LeadConvertCtlr ctlr = new trac_LeadConvertCtlr(sc);
		ctlr.accountName = 'Unit Test';

		PageReference pr = ctlr.convertLead();

		List<Lead> convertedLeads = [SELECT  ConvertedContactId, ConvertedOpportunityId, ConvertedAccountId FROM Lead WHERE IsConverted = true];

		System.assertEquals(1, convertedLeads.size());
		
		Lead convertedLead = [SELECT  ConvertedContactId, ConvertedOpportunityId, ConvertedAccountId FROM Lead WHERE IsConverted=true AND Id=:l.Id LIMIT 1];

		Account a 		= [SELECT OwnerId FROM Account WHERE Id=:convertedLeads[0].ConvertedAccountId LIMIT 1];
		Contact c1 		= [SELECT OwnerId FROM Contact WHERE Id=:convertedLeads[0].ConvertedContactId];
		//Contact c2 		= [SELECT OwnerId FROM Contact WHERE Id=:convertedLeads[1].ConvertedContactId];
		Opportunity o 	= [SELECT OwnerId FROM Opportunity WHERE Id=:convertedLead.ConvertedOpportunityId LIMIT 1];

		// assert that the owners of the converted records  is the current user
		System.assert(a.OwnerId == UserInfo.getUserId());
		System.assert(c1.OwnerId == UserInfo.getUserId());
		//System.assert(c2.OwnerId == UserInfo.getUserId());
		System.assert(o.OwnerId == UserInfo.getUserId());

		System.assertEquals(1, [SELECT Id FROM Opportunity].size());

		Test.stopTest();
	}

	 @isTest static void testInactiveUserLeadConvert() {
		Test.startTest();
		// insert group		

		User u1 = trac_TestUtils.createUser('testFirstLast@tes.com', 'alia', 'userFirstName', 'LastName');

		System.runAs(u1) {

			Group g = new Group(Name='Test Group Name', Type='Queue');
			insert g;

			// insert queue
			QueuesObject q= new QueuesObject(QueueId=g.id, SobjectType='Lead');
			insert q;
		}

		User u2 = trac_TestUtils.createUser('notActive@tes.com', 'alia', 'userFirstName', 'LastName');		

		// get created queue
		QueuesObject qRecord = [SELECT Id, QueueId, Queue.Name, SobjectType FROM QueueSobject WHERE SobjectType = 'Lead' LIMIT 1];

		Domain__c d = trac_TestUtils.createDomainWithAccount('Test Account','tractionondemand.com', 'www.tractionondemand.com');

		Lead l = trac_TestUtils.createLead('Unit', 'Test', null);
		insert l;

		// set the owner of the lead as queue
		l.OwnerId = qRecord.QueueId;
		l.parentPaymentProfileID__c = '0123456';
		update l;

		lead lead2 = trac_TestUtils.createLead('Unit', 'Test', null);
		lead2.parentPaymentProfileID__c = '0123456';
		lead2.OwnerId = u2.Id;
		insert lead2;

		u2.IsActive = false;
		System.runAs(u1) {
		  update u2;
		}		

		System.assertEquals(l.OwnerId, qRecord.QueueId);

		PageReference pageRef = Page.trac_LeadConvert;

		Test.setCurrentPage(pageRef);
		
		ApexPages.StandardController sc = new ApexPages.StandardController(l);
		ApexPages.currentPage().getParameters().put('Id', l.Id);

		trac_LeadConvertCtlr ctlr = new trac_LeadConvertCtlr(sc);
		ctlr.accountName = 'Unit Test';

		PageReference pr = ctlr.convertLead();

		List<Lead> convertedLeads = [SELECT  ConvertedContactId, ConvertedOpportunityId, ConvertedAccountId FROM Lead WHERE IsConverted = true];

		//System.assertEquals(2, convertedLeads.size());
		
		Lead convertedLead = [SELECT  ConvertedContactId, ConvertedOpportunityId, ConvertedAccountId FROM Lead WHERE IsConverted=true AND Id=:l.Id LIMIT 1];

		Account a 		= [SELECT OwnerId FROM Account WHERE Id=:convertedLeads[0].ConvertedAccountId LIMIT 1];
		Contact c1 		= [SELECT OwnerId FROM Contact WHERE Id=:convertedLeads[0].ConvertedContactId];
		//Contact c2 		= [SELECT OwnerId FROM Contact WHERE Id=:convertedLeads[1].ConvertedContactId];
		Opportunity o 	= [SELECT OwnerId FROM Opportunity WHERE Id=:convertedLead.ConvertedOpportunityId LIMIT 1];

		// assert that the owners of the converted records  is the current user
		//System.assert(a.OwnerId == UserInfo.getUserId());
		//System.assert(c1.OwnerId == UserInfo.getUserId());
		//System.assert(c2.OwnerId == UserInfo.getUserId());
		//System.assert(o.OwnerId == UserInfo.getUserId());

		//System.assertEquals(1, [SELECT Id FROM Opportunity].size());

		Test.stopTest();
	}

 	//public static testMethod void lastActivityDate() {
 	//	Lead newLead1 = trac_TestUtils.createLead('Last name one', 'test Company', 'www.test.com');
 	//	insert newLead1;

 	//	User newUser = trac_TestUtils.createUser('test@tractioondemand.com.test', 'tst', 'firstName', 'lastName');

 	//	System.debug('Before Task insert');
 	//	Task newTask = trac_TestUtils.createTask(null, newLead1.Id, 'test subject', newUser.Id, 'Call', 'Completed', Date.today());
  //      insert newTask; 
 	//	System.debug('After Task insert');        
 	//}

	
}