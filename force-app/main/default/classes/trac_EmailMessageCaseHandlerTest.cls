/**
 * trac_EmailMessageCaseHandlerTest.cls
 * @description Class tests trac_EmailMessage.trigger, trac_EmailMessageDispatcher.cls, & trac_EmailMessageCaseHandler.cls
 * @author      Mike Fransblow
 * @company     Traction On Demand
 * @date        Nov 7 2016
 */
@isTest(SeeAllData=false)
public class trac_EmailMessageCaseHandlerTest {

	static{
		trac_TestUtils.setupCollaboratorPackage();
	}

	private static final Id ORG_ID = UserInfo.getOrganizationId() ;
	private static final List<trac_outbound_email_mapping__mdt> E2C_ROUTING_ADDRESSES = [SELECT inbound__c 
																						 FROM trac_outbound_email_mapping__mdt 
																						 WHERE org_id__c = :ORG_ID 
																						 AND inbound__c != null
																						 AND For_Test__c = true ];	
	private static final List<String> FROM_FILTER = new List<String>{'service@paypal.com'};

	static {
		insert new Service_Settings__c( numberOfDaysToSearchForDuplicates__c = 30 );
	}
	
	// This test is the normal E2C scenario where a Case is atached to an existing EmailMessage
	// it should be unaltered
	@isTest
	static void checkNoDuplicates(){
			
		Test.startTest();			

			System.assert(E2C_ROUTING_ADDRESSES.size() >= 1,'Could not retrieve Email-To_case routing addresses from custom metadata');
		
			String serviceAddress = E2C_ROUTING_ADDRESSES[0].Inbound__c;

			Case c = trac_TestUtils.createCase('new','Email','foo@bar.com','Foo Bar');
			c.Subject='Test regular E2C';
			insert c;

			// This is a normal E2C scenario, no re-parenting should occur
			EmailMessage em = new EmailMessage(ToAddress=serviceAddress,FromAddress='foo@bar.com',Subject=c.Subject,ParentId=c.Id);
			insert em;	

//			System.assertEquals(c.Id,[SELECT Id FROM Case WHERE Id = :c.Id].Id);

		Test.stopTest();
	
	}
	
	// This test simulates a customer who has emailed a non-E2C routable email address initially
	// Subsequently the support agent replies and cc's an E2C routable address, which should trigger additional Cases to be inserted.
	// trac_EmailMessage trigger and supporting classes should detect the subsequent EmailMessages and re-parent these to the original Case,
	// and delete the duplicate Cases.
	@isTest
	static void checkDuplicates(){
			
		Test.startTest();

			System.assert(E2C_ROUTING_ADDRESSES.size() >= 1,'Could not retrieve Email-To_case routing addresses from custom metadata');
		
			String serviceAddress = E2C_ROUTING_ADDRESSES[0].Inbound__c;

			Case parentCase = trac_TestUtils.createCase('new','Email','foo@bar.com','Parent Case');
			insert parentCase;

			Case[] multipleCases = new Case[] {
				new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' )
				,new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' )
				,new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' )
				,new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' )
			};
			insert multipleCases;

			EmailMessage[] emailsWithDupes = new EmailMessage[] {
				 new EmailMessage(ToAddress='foo@bar.com',FromAddress='non-support-address@smartsheet.com',CcAddress=serviceAddress,Subject='Email From Agent CCing Support',ParentId=parentCase.Id,Incoming=true,Headers=trac_TestUtils.generateFirstHeader())
				,new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 1',HtmlBody='how now brown cow html 1',TextBody='how now brown cow text 1',ParentId=multipleCases[0].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())
				,new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 2',HtmlBody='how now brown cow html 2',TextBody='how now brown cow text 2',ParentId=multipleCases[1].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())
				,new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 3',HtmlBody='how now brown cow html 3',TextBody='how now brown cow text 3',ParentId=multipleCases[2].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())
				,new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 4',HtmlBody='how now brown cow html 4',TextBody='how now brown cow text 4',ParentId=multipleCases[3].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())	
			};
			insert emailsWithDupes;
			
		Test.stopTest();
	
		// make sure cases were marked Closed - Duplicate
		// note that there should only be 4
		List<Case> closedDupeCases = [SELECT Id, Status FROM Case WHERE Id IN :multipleCases AND Status = 'Closed - Duplicate'];
//		system.assertEquals(4,closedDupeCases.size());

		// there should be a total of 4 cloned email msgs plus the original inbound -> 5 total email msgs with the same parent case id
		List<EmailMessage> clonedEmailMessages = [SELECT Id, ParentID, Incoming, HtmlBody, TextBody, ToAddress, FromAddress, Subject, MessageDate, Status, CcAddress FROM EmailMessage WHERE ParentId = :parentCase.Id];
//		System.assertEquals(5,clonedEmailMessages.size());

	}


	// This test simulates an EmailMessage that is addressed from a filtered address.
	// The associated Case should not be re-parented
	@isTest
	static void checkFiltered(){

		System.assert(E2C_ROUTING_ADDRESSES.size() >= 1,'Could not retrieve Email-To_case routing addresses from custom metadata');
		
		String serviceAddress = E2C_ROUTING_ADDRESSES[0].Inbound__c;

		Test.startTest();

			Case parentCase = trac_TestUtils.createCase('new','Email','foo@bar.com','Parent Case');
			insert parentCase;

			Case[] multipleCases = new Case[] {
				new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' )
				,new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' )
				,new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Paypal' )
				,new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Paypal' )
				,new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Paypal' )
			};
			insert multipleCases;

			EmailMessage[] emailsUnFiltered = new EmailMessage[] {
				 new EmailMessage(ToAddress='foo@bar.com',FromAddress='non-support-address@smartsheet.com',CcAddress=serviceAddress,Subject='Email From Agent CCing Support',ParentId=parentCase.Id,Incoming=true,Headers=trac_TestUtils.generateFirstHeader())
				,new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 1',HtmlBody='how now brown cow html 1',TextBody='how now brown cow text 1',ParentId=multipleCases[0].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())
				,new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 2',HtmlBody='how now brown cow html 2',TextBody='how now brown cow text 2',ParentId=multipleCases[1].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())
				,new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress=FROM_FILTER[0],CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 3',HtmlBody='how now brown cow html 3',TextBody='how now brown cow text 3',ParentId=multipleCases[2].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())
				,new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress=FROM_FILTER[0],CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 4',HtmlBody='how now brown cow html 4',TextBody='how now brown cow text 4',ParentId=multipleCases[3].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())
				,new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress=FROM_FILTER[0],CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 5',HtmlBody='how now brown cow html 5',TextBody='how now brown cow text 5',ParentId=multipleCases[4].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())
			};
			insert emailsUnFiltered;
			
		Test.stopTest();

		// make sure cases were marked Closed - Duplicate
		List<Case> closedDupeCases = [SELECT Id, Status FROM Case WHERE Id IN :multipleCases AND Status = 'Closed - Duplicate'];
//		system.assertEquals(2,closedDupeCases.size());

		// there should now be a total of 2 cloned email msgs plus the original inbound -> 3 total email msgs with the same parent case id
		List<EmailMessage> clonedEmailMessages = [SELECT Id, ParentID, Incoming, HtmlBody, TextBody, ToAddress, FromAddress, Subject, MessageDate, Status, CcAddress FROM EmailMessage WHERE ParentId = :parentCase.Id];
//		System.assertEquals(3,clonedEmailMessages.size());

	}

	// This test simulates an customer sending an EmailMessage that is addressed to a E2C routable email address,
	// then replying to that same E2C routable address before a support rep has a chance to reply.
	@isTest
	static void checkCustomerReplyToSelf(){

		Test.startTest();
		
			System.assert(E2C_ROUTING_ADDRESSES.size() >= 1,'Could not retrieve Email-To_case routing addresses from custom metadata');
		
			String serviceAddress = E2C_ROUTING_ADDRESSES[0].Inbound__c;

			Case parentCase = trac_TestUtils.createCase('new','Email','foo@bar.com','Parent Case');
			insert parentCase;
			
			Case c = trac_TestUtils.createCase('new','Email','foo@bar.com','Foo Bar');
			insert c;

			// This is a normal E2C scenario, no re-parenting should occur
			EmailMessage em = new EmailMessage(ToAddress=serviceAddress,FromAddress='foo@bar.com',Subject='Email from Customer to Support',Headers=trac_TestUtils.generateFirstHeader(),Incoming=true,ParentId=parentCase.Id);

			// This is the second email sent by the same customer
			EmailMessage em2 = new EmailMessage(ToAddress=serviceAddress,FromAddress='foo@bar.com',Subject='re: Email from Customer to Support',Headers=trac_TestUtils.generateSubsequentHeader(),Incoming=true,ParentId=c.Id);

			List<EmailMessage> ems = new List<EmailMessage>{em,em2};
			insert ems;

			// make sure cases were marked Closed - Duplicate
			List<Case> closedDupeCases = [SELECT Id, Status FROM Case WHERE Id = :c.Id AND Status = 'Closed - Duplicate'];
//			system.assertEquals(1,closedDupeCases.size());

			// there should be a total of 1 cloned email msg plus the orignal inbound -> 2 total emal msgs with the same parent case id
			List<EmailMessage> clonedEmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :parentCase.Id];
//			System.assertEquals(2,clonedEmailMessages.size());
			
		Test.stopTest();

	}

	// This test simulates a customer who has emailed a non-E2C routable email address initially
	// Subsequently the support agent replies and cc's MULTIPLE E2C routable addresses, which should trigger additional Cases to be inserted.
	// trac_EmailMessage trigger and supporting classes should detect the subsequent EmailMessages and re-parent these to the original Case,
	// and delete the duplicate Cases.
	@isTest
	static void checkMultipleCCToServiceAddress(){
			
		Test.startTest();
		
			System.assert(E2C_ROUTING_ADDRESSES.size() >= 2,'Could not retrieve 2 or more Email-To_case routing addresses from custom metadata');

			String multipleServiceAddress = E2C_ROUTING_ADDRESSES[0].Inbound__c + '; ' + E2C_ROUTING_ADDRESSES[1].Inbound__c;

			Case parentCase = trac_TestUtils.createCase('new','Email','foo@bar.com','Parent Case');
			insert parentCase;

			Case[] multipleCases = new Case[] {
				new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' ),
				new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' ),
				new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' ),
				new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' )
			};
			insert multipleCases;

			EmailMessage[] emailsWithDupes = new EmailMessage[] {
				new EmailMessage(ToAddress='foo@bar.com',FromAddress='non-support-address@smartsheet.com',CcAddress=multipleServiceAddress,Subject='Email From Agent CCing Support',ParentId=parentCase.Id,Incoming=true,Headers=trac_TestUtils.generateFirstHeader()),	
				new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=multipleServiceAddress,Subject='re: Email From Agent CCing Support 1',ParentId=multipleCases[0].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader()),
				new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=multipleServiceAddress,Subject='re: Email From Agent CCing Support 2',ParentId=multipleCases[1].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader()),
				new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=multipleServiceAddress,Subject='re: Email From Agent CCing Support 3',ParentId=multipleCases[2].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader()),
				new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=multipleServiceAddress,Subject='re: Email From Agent CCing Support 4',ParentId=multipleCases[3].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())	
			};
			insert emailsWithDupes;

			// make sure cases were marked Closed - Duplicate
			List<Case> closedDupeCases = [SELECT Id, Status FROM Case WHERE Id IN :multipleCases AND Status = 'Closed - Duplicate'];
//			system.assertEquals(4,closedDupeCases.size());

			// there should be a total of 4 cloned email msgs plus the orignal outbound -> 5 total emal msgs with the same parent case id
			List<EmailMessage> clonedEmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :parentCase.Id];
//			System.assertEquals(5,clonedEmailMessages.size());

		Test.stopTest();
	
	}

	// This test simulates a customer who has emailed a non-E2C routable email address initially
	// Subsequently the support agent replies and cc's MULTIPLE NON-E2C routable addresses, which should trigger additional Cases to be inserted.
	// trac_EmailMessage trigger and supporting classes should detect the subsequent EmailMessages and re-parent these to the original Case,
	// and delete the duplicate Cases.
	@isTest
	static void checkMultipleCCToNonServiceAddress(){
			
		Test.startTest();

			System.assert(E2C_ROUTING_ADDRESSES.size() >= 1,'Could not retrieve Email-To_case routing addresses from custom metadata');
		
			String serviceAddress = E2C_ROUTING_ADDRESSES[0].Inbound__c + '; foo2@bar.com' ;

			Case parentCase = trac_TestUtils.createCase('new','Email','foo@bar.com','Parent Case');
			insert parentCase;

			Case[] multipleCases = new Case[] {
				new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' ),
				new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' ),
				new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' ),
				new Case( Status='new', Origin='email', SuppliedEmail='foo@bar.com', SuppliedName='Foo Bar' )
			};
			insert multipleCases;

			EmailMessage[] emailsWithDupes = new EmailMessage[] {
				new EmailMessage(ToAddress='foo@bar.com',FromAddress='non-support-address@smartsheet.com',CcAddress=serviceAddress,Subject='Email From Agent CCing Support',ParentId=parentCase.Id,Incoming=true,Headers=trac_TestUtils.generateFirstHeader()),	
				new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 1',ParentId=multipleCases[0].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader()),
				new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 2',ParentId=multipleCases[1].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader()),
				new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 3',ParentId=multipleCases[2].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader()),
				new EmailMessage(ToAddress='non-support-address@smartsheet.com',FromAddress='foo@bar.com',CcAddress=serviceAddress,Subject='re: Email From Agent CCing Support 4',ParentId=multipleCases[3].Id,Incoming=true,Headers=trac_TestUtils.generateSubsequentHeader())	
			};
			insert emailsWithDupes;

			// make sure cases were marked Closed - Duplicate
			List<Case> closedDupeCases = [SELECT Id, Status FROM Case WHERE Id IN :multipleCases AND Status = 'Closed - Duplicate'];
//			system.assertEquals(4,closedDupeCases.size());

			// there should be a total of 4 cloned email msgs plus the orignal outbound -> 5 total email msgs with the same parent case id
			List<EmailMessage> clonedEmailMessages = [SELECT Id FROM EmailMessage WHERE ParentId = :parentCase.Id];
//			System.assertEquals(5,clonedEmailMessages.size());

		Test.stopTest();
	
	}

}