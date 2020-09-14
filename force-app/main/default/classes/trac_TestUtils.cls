/**
 * Test utils class
 *
 * @author Sergei Dobrianski
 * @company Traction on Demand
**/
@isTest(seeAllData=false)
public without sharing class trac_TestUtils {

	public static final String DOMIAN_URL_ONE = 'star@destroyer.com';
	public static final String DOMIAN_URL_TWO = 'lonestar@destroyer.com';
	public static final String DOMIAN_URL_THREE = 'death@star.com';

	public static final String PPPID_ONE = '0123456';
	public static final String PPPID_TWO = '1234567';
	public static final String PPPID_THREE = '2345678';

	public static final String DEFAULT_STAGENAME = 'Qualify';
	public static final Date DEFAULT_CLOSEDDATE = Date.today();

	public static final String COMPANY_NAME_ONE = 'HansSolo Smugglers Inc';

	public static final String ACCOUNT_NAME_ONE = 'Smugglers Inc';

	public static final String OPP_NAME_ONE = 'Capture Solo';

	public static final Integer DEFAULT_BONUS_COUNT = 20;

	public static final List<String> VALID_PRODUCTS = new List<String>();

	public static final String MSG_ID = 'GZSTX000000000000000000000000000000000000000000000OGC4PW00orz0nixKQnGU9m0urjMFAQ@sfdc.net';

	static final String DISCOUNT_REASON = 'Faster Sale';

	public static final String TEST_CRONSTRING = '0 0 0 3 9 ? 2022';

	public static final String DEFAULT_ENTITLEMENT_NAME = [
			SELECT Entitlement__c
			FROM Role_Product_Entitlement_Association__mdt
			WHERE DeveloperName = :trac_Constants.DEFAULT_NAME
			LIMIT 1
	].Entitlement__c;

	public static void initValidProducts() {
		for (String val : trac_IntegrationLeadProcessing.validProductSet) {
			VALID_PRODUCTS.add(val);
		}
	}

	public static User marketoUser = getMarketoIntegrationUser();

	public static void initCustSetting_InsightProductName() {
		List<Insight_Product_Name__c> ipn = new List<Insight_Product_Name__c>();
		ipn.add(new Insight_Product_Name__c(Name = 'advanced', ProductName__c = 'advanced'));
		ipn.add(new Insight_Product_Name__c(Name = 'basic', ProductName__c = 'basic'));
		ipn.add(new Insight_Product_Name__c(Name = 'enterprise', ProductName__c = 'enterprise'));
		ipn.add(new Insight_Product_Name__c(Name = 'team', ProductName__c = 'team'));

		insert ipn;

	}

	public static void initCustSetting_InsightFieldMapping() {

		List<Insight_Field_Mapping__c> ifm = new List<Insight_Field_Mapping__c>();
		ifm.add(new Insight_Field_Mapping__c(Name = 'bonusSheetCount', Source_Field__c = 'Bonus_Sheet_Count__c', Target_Field__c = 'Bonus_Sheet_Count__c', Target_Object__c = 'Opportunity', Non_Sales_Assisted__c = true));
		ifm.add(new Insight_Field_Mapping__c(Name = 'oldProductName', Source_Field__c = 'Product__c', Target_Field__c = 'Product__c', Target_Object__c = 'Opportunity', Non_Sales_Assisted__c = false));
		ifm.add(new Insight_Field_Mapping__c(Name = 'parentPaymentProfile', Source_Field__c = 'Parent_Payment_Profile_ID__c', Target_Field__c = 'Parent_Payment_Profile_ID__c', Target_Object__c = 'Opportunity', Non_Sales_Assisted__c = false));
		ifm.add(new Insight_Field_Mapping__c(Name = 'closedDate', Source_Field__c = 'Date_Time_Interface__c', Target_Field__c = 'CloseDate', Target_Object__c = 'Opportunity', Non_Sales_Assisted__c = true));
		ifm.add(new Insight_Field_Mapping__c(Name = 'orgDomain', Source_Field__c = 'Organization_Domain__c', Target_Field__c = 'Organization_Domain__c', Target_Object__c = 'Opportunity', Non_Sales_Assisted__c = false));
		ifm.add(new Insight_Field_Mapping__c(Name = 'oldPaymentTotal', Source_Field__c = 'Old_Payment_Total__c', Target_Field__c = 'Old_Payment_Total__c', Target_Object__c = 'Opportunity', Non_Sales_Assisted__c = false));

		insert ifm;

	}

	//public static void initCustSetting_CompareDate() {
	//    insert new Compare_Date__c( Minus_Days__c = 40 );
	//}

	public static void initCustSetting_Addtional_Sync_Fields() {
		insert new Additional_Sync_FIelds__c(Name = 'oldPaymentTotal', Src__c = 'Old_Payment_Total__c', Target__c = 'Old_Payment_Total__c');
	}

	public static void initCustSetting_InsightDataRecordType() {

		insert new Insight_Data_Record_Type__c(Cancellation__c = 'Loss', Downgrade__c = 'Downgrade', Upgrade__c = 'Upgrade', License_Purchase__c = 'Win');

	}

	public static Lead createLead(String lastName, String companyName, String domainName) {

		return new Lead(LastName = lastName, Company = companyName, Domain__c = domainName);

	}

	public static Lead createLead(String lastName, String companyName, String domainName, String pppId) {

		Lead l = createLead(lastName, companyName, domainName);
		l.parentPaymentProfileID__c = pppId;
		return l;

	}

	public static Insight_Data_Integrator__c createInsightDataIntegrator(String ppid, String type, String domain, String orgName) {
		return new Insight_Data_Integrator__c(Parent_Payment_Profile_ID__c = ppId, Product__c = type, Organization_Domain__c = domain, Organization_Name__c = orgName);
	}

	public static Domain__c createDomainWithAccount(String accountName, String domainName, String domainNameURL) {
		return createDomain(accountName, domainName, domainNameURL, true);
	}

	public static Domain__c createDomain(String accountName, String domainName, String domainNameURL, Boolean linkDomainToAccount) {
		Account newAccount = new Account(
				Name = accountName
		);
		insert newAccount;

		Domain__c newDomain = new Domain__c(
				Name = domainName,
				Domain_Name_URL__c = domainNameURL
		);
		if (linkDomainToAccount) {
			newDomain.Account__c = newAccount.Id;
		}
		insert newDomain;

		return newDomain;
	}

	public static Domain__c createDomain(String accountName, String domainNameURL, String email) {
		return createDomain(accountName, domainNameURL, domainNameURL, true);
	}

	public static Domain__c createDomain(String domainNameURL, Id ownerId) {
		return new Domain__c(Name = domainNameURL, Domain_Name_URL__c = domainNameURL, OwnerId = ownerId);
	}

	public static Domain__c createDomain(String domainNameURL) {
		return new Domain__c(Name = domainNameURL, Domain_Name_URL__c = domainNameURL);
	}

	public static Opportunity createOpp(String name) {
		return new Opportunity(Name = name);
	}

	/**
	 * wrapper method to create Opportunities with required fields
	**/
	public static Opportunity createOpp(String name, String stageName, Date closeDate) {
		Opportunity opp = createOpp(name);
		opp.StageName = stageName;
		opp.CloseDate = closeDate;
		return opp;
	}

	public static Opportunity createOppPipelinePPPID(String name, String stageName, Date closeDate, String pppId) {
		Opportunity opp = createOpp(name, stageName, closeDate);
		opp.Parent_Payment_Profile_ID__c = pppId;
		return opp;
	}

	public static Opportunity createOppPipelineNoPPPID(String name, String stageName, Date closeDate) {
		return createOpp(name, stageName, closeDate);
	}

	public static User createUser(String userName, String userAlias, String userFirstName, String userLastName) {
		return createUser(userName, userAlias, userFirstName, userLastName, 'Standard User');
	}

	public static User createUser(String userName, String userAlias, String userFirstName, String userLastName, String profileName) {
		Id profileId = [
				SELECT id
				FROM Profile
				WHERE name = :profileName
				LIMIT 1
		].id;

		User newUser = new User(
				UserName = userName,
				Email = 'test@tractioondemand.com.test',
				FirstName = userFirstName,
				LastName = userLastName,
				ALias = userAlias,
				TimezoneSIDKey = 'America/Los_Angeles',
				LocaleSIDKey = 'en_US',
				EmailEncodingKey = 'UTF-8',
				LanguageLocaleKey = 'en_US',
				ProfileId = profileId
		);

		insert newUser;

		return newUser;
	}

	public static List<Group> createGroups(Integer num, String groupType, Boolean doInsert) {
		List<Group> newGroups = new List<Group>();

		for (Integer i=0; i<num; i++) {
			newGroups.add(new Group(
				Name = 'Group ' + i,
				Type = groupType
			));
		}

		if (doInsert) {
			insert newGroups;
		}

		return newGroups;
	}

	public static User getMarketoIntegrationUser() {
		List<User> rUser = [
				SELECT Id
				FROM User
				WHERE Name = 'Marketo Integration'
		];
		if (rUser.isEmpty()) {
			User tmp = new User(
					FirstName = 'Marketo',
					LastName = 'Integration',
					Email = 'traction@test.ca',
					UserName = 'traction@test.ca',
					Alias = 'tester',
					TimeZoneSidKey = 'America/Los_Angeles',
					LocaleSidKey = 'en_CA',
					EmailEncodingKey = 'ISO-8859-1',
					ProfileId = [
							SELECT Id, Name, UserType
							FROM Profile
							WHERE Name = 'System Administrator'
					].Id,
					LanguageLocaleKey = 'en_US'
			);

			insert tmp;
			return tmp;
		}

		return rUser[0];
	}

	public static Task createTask(String whatId, String whoId, String subject,
			String assignedTo, String type, String status, Date dueDate) {
		Task t = new Task();
		t.WhatId = whatId;
		t.WhoId = whoid;
		t.Subject = subject;
		t.OwnerId = assignedTo;
		t.Type = type;
		t.Status = status;
		t.ActivityDate = dueDate;

		return t;
	}

	public static Task createTask(String whatId, String whoId, String subject,
			String type, String status, Date dueDate) {
		Task t = new Task();
		t.WhatId = whatId;
		t.WhoId = whoid;
		t.Subject = subject;
		t.Type = type;
		t.Status = status;
		t.ActivityDate = dueDate;

		return t;
	}

	public static void resetCodeExecution() {
		//trac_PipelineOpportunity.pppIdsToExclude = new Set<String>();
		//InsightDataWrapper.resetInsightDataMap();
		trac_Dispatcher.resetProcessCount();
	}

	//////////////////////////////////////////////////////////////////
	// Pipeline test methods
	//////////////////////////////////////////////////////////////////
	/**
	 * This method auto converts a lead via an insight transaction.
	 * Preparing an opportunity ready for an insight expansion transaction.
	**/
	public static void autoLeadConvertViaInsight(String domainUrl, String pppId) {

		initValidProducts();

		trac_TestUtils.resetCodeExecution();

		Lead l = createLead(ACCOUNT_NAME_ONE, COMPANY_NAME_ONE, domainUrl, pppId);
		l.productName__c = VALID_PRODUCTS[0];
		l.Status = 'Accepted';
		insert l;

		//User newUser = trac_TestUtils.createUser('test@tractioondemand.com.test', 'tst', 'firstName', 'lastName');

		trac_TestUtils.resetCodeExecution();

		Task newTask = createTask(null, l.Id, 'test subject', 'Call', 'Completed', Date.today());
		insert newTask;

		trac_TestUtils.resetCodeExecution();

		Insight_Data_Integrator__c idi1 = createInsightDataIntegrator(pppId, VALID_PRODUCTS[0], domainUrl, ACCOUNT_NAME_ONE);
		idi1.Bonus_Sheet_Count__c = 20;
		//idi1.Record_Type__c       = trac_InsightDataIntegrator_Helper.NEW_LICENSE;
		insert idi1;

		trac_TestUtils.resetCodeExecution();

	}

	/**
	 * This method creates a pipeline expansion opp
	 * ready for an expansion transaction.
	**/
	public static void expansionPipelineUseCase(String domainUrl, String pppId) {

		trac_TestUtils.resetCodeExecution();

		winsPipelineUseCase(DOMIAN_URL_ONE, PPPID_ONE);

		trac_TestUtils.resetCodeExecution();

		Opportunity opp1 = queryPipeOppsDefualtFields()[0];
		//opp1.RecordTypeId = trac_PipelineOpportunity.EXPANSION_REC_TYPE;
		//opp1.StageName    = trac_PipelineOpportunity.CLOSED_WON;
		update opp1;

		trac_TestUtils.resetCodeExecution();
	}

	/**
	 * This method creates an the following records:
	 *      Insight_Data_Integrator__c
	 *      Payment_Profile__c
	 *      Domain__c
	 *      Account
	 *      Opportunity
	 *
	 * Use case: Insight data transaction occurs and a pipeline
	 * opportunity is synchronized to the insight record.
	**/
	public static void winsPipelineUseCase(String domainUrl, String pppId) {

		initValidProducts();

		//account created
		Domain__c domain1 = createDomainWithAccount(ACCOUNT_NAME_ONE, COMPANY_NAME_ONE, domainUrl);

		Opportunity opp1 = createOppPipelinePPPID(OPP_NAME_ONE, DEFAULT_STAGENAME, DEFAULT_CLOSEDDATE, pppId);
		opp1.AccountId = domain1.Account__c;
		//opp1.RecordTypeId = trac_PipelineOpportunity.NEW_REC_TYPE;
		insert opp1;

		trac_TestUtils.resetCodeExecution();

		Insight_Data_Integrator__c idi1 = trac_TestUtils.createInsightDataIntegrator(pppId, VALID_PRODUCTS[0], domainUrl, ACCOUNT_NAME_ONE);
		idi1.Bonus_Sheet_Count__c = DEFAULT_BONUS_COUNT;
		//idi1.Record_Type__c       = trac_InsightDataIntegrator_Helper.NEW_LICENSE;
		insert idi1;

		trac_TestUtils.resetCodeExecution();
	}

	public static void winsPipelineUseCase() {
		winsPipelineUseCase(DOMIAN_URL_ONE, PPPID_ONE);
	}

	public static List<Opportunity> queryPipeOppsDefualtFields() {
		return [
				SELECT Id, StageName, Is_Pipeline_Opp__c, Exclude_from_Future_Expansion__c, RecordTypeId, Product__c, Parent_Payment_Profile_ID__c, Current_Month_Opp__c
				FROM Opportunity
		];
	}

	public static Case createCase(String status, String origin, String suppliedEmail, String suppliedName) {
		return new Case(Status = status, Origin = origin, SuppliedEmail = suppliedEmail, SuppliedName = suppliedName);
	}

	public static Contact createContact(String lastName, String email, Account acnt) {
		return new Contact(LastName = lastName, AccountId = acnt.Id, Email = email);
	}

	public static String generateRandomString(Integer len) {
		final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
		String randStr = '';
		while (randStr.length() < len) {
			Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
			randStr += chars.substring(idx, idx + 1);
		}
		return randStr;
	}

	public static Integer getRandomNum(Integer x, Integer y) {
		return Math.floor(Math.random() * ((y - x) + 1) + x).intValue();
	}

	public static String generateFirstHeader() {
		String hdrMsgId = 'Message-ID: <' + MSG_ID + '>';
		// randomize header string and inject header at a random point within
		String header = trac_TestUtils.generateRandomString(300);
		Integer randomInt = trac_TestUtils.getRandomNum(1, 300);
		header = header.substring(0, randomInt) + hdrMsgId + header.substring(randomInt, header.length());
		return header;
	}

	public static String generateSubsequentHeader() {
		String hdrRefs = 'In-Reply-To: <' + MSG_ID + '>';
		// randomize header string and inject header at a random point within
		String header = trac_TestUtils.generateRandomString(300);
		Integer randomInt = trac_TestUtils.getRandomNum(1, 300);
		header = header.substring(0, randomInt) + hdrRefs + header.substring(randomInt, header.length());
		return header;
	}

	public static Product2 createProduct2(String productName) {

		return
				new Product2(
						Name = productName,
						IsActive = true
				);

	}

	public static Asset createAsset(Id productId, Id contractId, Id accountId) {

		return
				new Asset(
						Name = 'Test Product',
						AccountId = accountId,
						Product2Id = productId,
						Plan__c = contractId
				);

	}

	public static PricebookEntry createPricebookEntry(Id productId, Id pricebook2id) {

		return
				new PricebookEntry(
						Product2Id = productId,
						UnitPrice = 1,
						UseStandardPrice = false,
						IsActive = True,
						Pricebook2Id = pricebook2Id
				);

	}

	public static OpportunityLineItem createOpportunityLineItem(Id oppId, Id pbeId) {

		return
				new OpportunityLineItem(
						OpportunityId = oppId,
						PricebookEntryId = pbeId,
						Quantity = 1,
						TotalPrice = 1,
						Discount_Reason__c = DISCOUNT_REASON
				);

	}

	public static Contract createContract(Id accountId, Integer pppId) {

		return
				new Contract(
						AccountId = accountId,
						Name = 'testContract',
						Payment_Profile_ID__c = String.valueOf(pppId)
				);

	}

	public static Account createAccount() {

		return
				new Account(
						Name = 'TestAccount'
				);

	}

	public static Entitlement createEntitlement(Account acc) {
		return new Entitlement(
				Name = 'Test Entitlement',
				AccountId = acc.Id
		);
	}

	/**
	* Creates an AttachedResult for Coveo. Note that the calling method should set Case__c or Knowledge__c lookup.
	*/
	public static CoveoV2__CoveoCaseAttachedResult__c createAttachedResult(Case parent) {
		CoveoV2__CoveoCaseAttachedResult__c ar = new CoveoV2__CoveoCaseAttachedResult__c();
		ar.CoveoV2__case__c = parent.Id;
		ar.CoveoV2__UriHash__c = parent.Id;
		ar.CoveoV2__ResultUrl__c = 'testURL555';
		ar.CoveoV2__Source__c = 'SFDC Production';
		ar.CoveoV2__Title__c = 'Test Title';
		return ar;
	}

	public static List<Queue_Owner_Change__c> createQueueOwnerChanges(List<Account> accounts, Id newOwnerId) {
		List<Queue_Owner_Change__c> retQueue = new List<Queue_Owner_Change__c>();
		if (accounts == null || accounts.isEmpty() || String.isBlank(newOwnerId)) {
			return retQueue;
		}
		for (Account acc : accounts) {
			retQueue.add(
				new Queue_Owner_Change__c(
					Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT,
					Source_Id__c = acc.Id,
					New_Owner_Id__c = newOwnerId
				)
			);
		}
		return retQueue;
	}
	
	public static List<Queue_Owner_Change__c> createQueueOwnerChangesBlankSourceId(List<Account> accounts, Id newOwnerId) {
		List<Queue_Owner_Change__c> retQueue = new List<Queue_Owner_Change__c>();
		if (accounts == null || accounts.isEmpty() || String.isBlank(newOwnerId)) {
			return retQueue;
		}
		for (Account acc : accounts) {
			retQueue.add(
					new Queue_Owner_Change__c(
							Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT,
							Source_Id__c = '',
							New_Owner_Id__c = newOwnerId
					)
			);
		}
		return retQueue;
	}

    public static List<Queue_Owner_Change__c> createQueueOwnerChanges(List<Domain__c> domains, Id newOwnerId) {
        List<Queue_Owner_Change__c> retQueue = new List<Queue_Owner_Change__c>();
        if (domains == null || domains.isEmpty() || String.isBlank(newOwnerId)) {
            return retQueue;
        }
        for (Domain__c dom : domains) {
            retQueue.add(
                    new Queue_Owner_Change__c(
                        Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_DOMAIN,
                        Source_Id__c = dom.Id,
                        Target_Type__c = trac_Constants.QOC_TARGET_TYPE_CONTACT,
                        New_Owner_Id__c = newOwnerId
                    )
            );
            retQueue.add(
                    new Queue_Owner_Change__c(
                        Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_DOMAIN,
                        Source_Id__c = dom.Id,
                        Target_Type__c = trac_Constants.QOC_TARGET_TYPE_LEAD,
                        New_Owner_Id__c = newOwnerId
                    )
            );
        }
        return retQueue;
    }



	public static List<Queue_Owner_Change__c> createQueueOwnerChangesEmpty(List<Domain__c> domains, Id newOwnerId) {
        List<Queue_Owner_Change__c> retQueue = new List<Queue_Owner_Change__c>();
        if (domains == null || domains.isEmpty() || String.isBlank(newOwnerId)) {
            return retQueue;
        }
        for (Domain__c dom : domains) {
            retQueue.add(
                    new Queue_Owner_Change__c(
                        Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT,
                        Source_Id__c = '',
                        Target_Type__c = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT,
                        New_Owner_Id__c = newOwnerId
                    )
            );
            retQueue.add(
                    new Queue_Owner_Change__c(
                        Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_DOMAIN,
                        Source_Id__c = '',
                        Target_Type__c = trac_Constants.QOC_TARGET_TYPE_LEAD,
                        New_Owner_Id__c = newOwnerId
                    )
            );
        }
        return retQueue;

    }


	public class StandardPricebookPackage {
		public Product2 prod;
		public PricebookEntry pbe;
		public Id standardPricebookId;

		public StandardPricebookPackage(Product2 prod, PricebookEntry pbe, Id standardPricebookId) {
			this.prod = prod;
			this.pbe = pbe;
			this.standardPricebookId = standardPricebookId;
		}
	}

	public static StandardPricebookPackage createStandardPricebookPackage() {
		Id standardPricebookId = Test.getStandardPricebookId();

		Product2 prod = new Product2(
				Name = 'Test Standard Product',
				ProductCode = 'TP',
				isActive = true,
				Entitlement_Ranking__c = 99
		);
		insert prod;

		PricebookEntry pbe = new PricebookEntry(
				Pricebook2Id = standardPricebookId,
				Product2Id = prod.Id,
				UnitPrice = 1.00,
				IsActive = true
		);
		insert pbe;

		return new StandardPricebookPackage(prod, pbe, standardPricebookId);
	}

	public class CollaboratorPackage {
		public Account collaboratorAccount;
		public Entitlement entitlement;

		public CollaboratorPackage(Account acc, Entitlement ent) {
			this.collaboratorAccount = acc;
			this.entitlement = ent;
		}
	}

	public static CollaboratorPackage setupCollaboratorPackage() {
		Account account = createAccount();
		account.Name = trac_Constants.THIS_MONTH_ACCOUNT_NAME;
		insert account;

		Entitlement entitlement = createEntitlement(account);
		entitlement.Name = DEFAULT_ENTITLEMENT_NAME;
		insert entitlement;

		return new CollaboratorPackage(account, entitlement);
	}
}