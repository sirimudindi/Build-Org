/**
 * @author Ryan Draper - Traction
 */
@isTest
public with sharing class trac_OpportunityPlanHandlerTest {

	static final String OPP_CLOSED_STATUS = trac_OpportunityPlanHandler.OPP_CLOSED_STATUS;
	static final String INACTIVE_STATUS = trac_OpportunityPlanHandler.INACTIVE_STATUS;
	static final String OPP_FINANCE_REVIEWED = trac_OpportunityPlanHandler.OPP_FINANCE_REVIEVED_STATUS;

	static Id PRICEBOOKID = Test.getStandardPricebookId();
	static Account testAccount;
	static Opportunity testOpp;
	static Opportunity testOpp2;
	static Opportunity testOpp3;
	static Product2 testProduct;
	static Product2 testProduct2;
	static Product2 testProduct3;
	static Product2 testProduct4;
	static Product2 testProduct5;
	static Product2 testProduct6;
	static PricebookEntry testPBE;
	static PricebookEntry testPBE2;
	static PricebookEntry testPBE3;
	static PricebookEntry testPBE4;
	static PricebookEntry testPBE5;
	static PricebookEntry testPBE6;
	static OpportunityLineItem testOLI;
	static OpportunityLineItem testOLI2;
	static OpportunityLineItem testOLI3;
	static Contract testContract;
	static Integer pppId;
	static String TEST_USER_EMAIL = 'DwightShrute@gmail.com';
	static String TEST_USER_NAME = 'DG';
	static User newUser = trac_TestUtils.createUser(TEST_USER_EMAIL, TEST_USER_NAME, TEST_USER_NAME, TEST_USER_NAME);

	static {
		trac_TriggerHandlerBase.blockTrigger = true;

		pppId = 1111111;
		testAccount = trac_TestUtils.createAccount();
		testAccount.NumberOfEmployees = 100;
		testAccount.BillingStreet = '123 fake street';
		testAccount.BillingCity = 'Seattle';
		testAccount.BillingState = 'Washington';
		testAccount.BillingPostalCode = '90210';
		testAccount.Industry = 'Agriculture';
		insert testAccount;

		testProduct = trac_TestUtils.createProduct2('product 1');
		testProduct.Entitlement_Ranking__c = 1;
		testProduct.Is_Recurring__c = true;
		testProduct.Primary_Subscription__c = true;
		testProduct.Item_Category__c = 'Subscription';
		testProduct2 = trac_TestUtils.createProduct2('product 2');
		testProduct2.Entitlement_Ranking__c = 2;
		testProduct2.Is_Recurring__c = true;
		testProduct2.Item_Category__c = 'Connector';
		testProduct3 = trac_TestUtils.createProduct2('product 3');
		testProduct3.Entitlement_Ranking__c = 3;
		testProduct3.Is_Recurring__c = true;
		testProduct3.Item_Category__c = 'Premium App';
		testProduct4 = trac_TestUtils.createProduct2('product 4');
		testProduct4.Entitlement_Ranking__c = 4;
		testProduct4.Is_Recurring__c = true;
		testProduct4.Item_Category__c = 'Subscription';
		testProduct5 = trac_TestUtils.createProduct2('product 5');
		testProduct5.Entitlement_Ranking__c = 5;
		testProduct5.Is_Recurring__c = true;
		testProduct5.Item_Category__c = 'Connector';
		testProduct5.Primary_Subscription__c = true;
		testProduct6 = trac_TestUtils.createProduct2('product 6');
		testProduct6.Entitlement_Ranking__c = 6;
		testProduct6.Is_Recurring__c = true;
		testProduct6.Item_Category__c = 'Premium App';
		testProduct6.Licensing__c = true;

		insert new List<Product2>{
				testProduct, testProduct2, testProduct3, testProduct4, testProduct5, testProduct6
		};

		testPBE = trac_TestUtils.createPricebookEntry(testProduct.Id, PRICEBOOKID);
		testPBE.UnitPrice = 150;
		testPBE2 = trac_TestUtils.createPricebookEntry(testProduct2.Id, PRICEBOOKID);
		testPBE2.UnitPrice = 200;
		testPBE3 = trac_TestUtils.createPricebookEntry(testProduct3.Id, PRICEBOOKID);
		testPBE3.UnitPrice = 300;
		testPBE4 = trac_TestUtils.createPricebookEntry(testProduct4.Id, PRICEBOOKID);
		testPBE4.UnitPrice = 400;
		testPBE5 = trac_TestUtils.createPricebookEntry(testProduct5.Id, PRICEBOOKID);
		testPBE5.UnitPrice = 500;
		testPBE6 = trac_TestUtils.createPricebookEntry(testProduct6.Id, PRICEBOOKID);
		testPBE6.UnitPrice = 600;
		insert new List<PricebookEntry>{
				testPBE, testPBE2, testPBE3, testPBE4, testPBE5, testPBE6
		};

		trac_TestUtils.setupCollaboratorPackage();
		trac_TriggerHandlerBase.blockTrigger = false;
	}

	static testMethod void testRenewalOppUpdateAssets() {
		Test.startTest();
		//GIVEN
		//an existing contract with Assets
		testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
		testContract.Currency_Code__c = 'USD';
		testContract.Primary_System_Admin__c = 'admin@testtest.com';
		insert testContract;

		Asset asset1 = trac_TestUtils.createAsset(testProduct.Id, testContract.Id, testAccount.Id);
		asset1.Product2Id = null;//should get linked back to the product by the trigger
		//Asset asset2 = trac_TestUtils.createAsset( testProduct2.Id, testContract.Id, testAccount.Id );//should get created by the trigger
		Asset asset3 = trac_TestUtils.createAsset(testProduct3.Id, testContract.Id, testAccount.Id);
		insert new List<Asset>{
				asset1, /*asset2,*/ asset3
		};

		//a new Opportunity of Type 'Renewal' with Opportunity Line Items matching the existing assets
		// (users are creating the Opp from the Contract in a flow)
		Opportunity newRenewalOpp
				= trac_TestUtils.createOppPipelinePPPID(
						'test renewal opp',
						'Negotiate',
						Date.today().addDays(10),
						String.valueOf(pppId)
				);
		newRenewalOpp.ContractId = testContract.Id;
		newRenewalOpp.RecordTypeId = trac_OpportunityPlanHandler.renewalRTId;
		newRenewalOpp.Bill_To_Status__c = 'Finance Approved';
		newRenewalOpp.AccountId = testAccount.Id;
		newRenewalOpp.Old_Payment_Total__c = 1000;
		insert newRenewalOpp;

		//Product_Is_Recurring__c should only be true on one of the line items
		OpportunityLineItem newOliWithAsset = trac_TestUtils.createOpportunityLineItem(newRenewalOpp.Id, testPBE.Id);
		newOliWithAsset.TotalPrice = testPBE.UnitPrice * 1;
		newOliWithAsset.Related_SKU__c = asset1.Id;

		Datetime dt = Datetime.now();
		Date testDate = Date.newinstance(dT.year(), dT.month(), dT.day());

		newOliWithAsset.Rev_Rec_Start_Date__c = testDate;
		OpportunityLineItem newOliWithoutAsset = trac_TestUtils.createOpportunityLineItem(newRenewalOpp.Id, testPBE2.Id);
		insert new List<OpportunityLineItem>{
				newOliWithAsset, newOliWithoutAsset
		};

		//WHEN
		//opp goes to finance approved
		newRenewalOpp.Bill_To_Status__c = OPP_FINANCE_REVIEWED;
		newRenewalOpp.SysAdmin_Email_Address__c = 'test@test.com';
		newRenewalOpp.ARR_Variance_Override__c = 100.00;
		newRenewalOpp.Previous_License_ARR__c = 75.00;
		newRenewalOpp.Billing_Contact_Name__c = 'billname testtest';
		newRenewalOpp.Billing_Contact_Email__c = 'billcontact@testtest.com';
		newRenewalOpp.Billing_Street__c = '123 Fake Street';
		newRenewalOpp.Billing_City__c = 'Beverly Hills';
		newRenewalOpp.Billing_Country__c = 'United States';
		update newRenewalOpp;

		newRenewalOpp.StageName = 'Closed Won';
		newRenewalOpp.Finance_Reviewed_By__c = newUser.Id;
		newRenewalOpp.Bill_To_Status__c = OPP_CLOSED_STATUS;
		update newRenewalOpp;

		Test.stopTest();

		//THEN
		//make sure that the Assets were updated/inserted/de-activated
		List<Asset> requeriedAssets = [
				SELECT Product2Id, Price, Quantity, Rev_Rec_Start_Date__c, Rev_Rec_End_Date__c, Netsuite_SO_ID__c,
						Netsuite_Line_Item_ID__c, Discount__c, Price_Book__c, Plan__c, Name, Status
				FROM Asset
				WHERE Plan__c = :testContract.Id
		];

		//might need to loop to find the right assets to inspect
		Boolean foundUpdatedAsset = false;
		Boolean foundInsertedAsset = false;
		Boolean foundDeActivatedAsset = false;

		Set<Id> newOliIds = new Set<Id>{
				newOliWithAsset.Id, newOliWithoutAsset.Id
		};

		List<OpportunityLineItem> requeriedOLIs = [
				SELECT Id, Product2Id, Related_SKU__c, Rev_Rec_Start_Date__c
				FROM OpportunityLineItem
				WHERE Id in :newOliIds
		];

		for (Asset asset : requeriedAssets) {

			if (requeriedOLIs[0].Rev_Rec_Start_Date__c == asset.Rev_Rec_Start_Date__c)
				foundUpdatedAsset = true;

			if (requeriedOLIs[1].Related_SKU__c == asset.Id)
				foundInsertedAsset = true;

			if (asset.Status == INACTIVE_STATUS)
				foundDeActivatedAsset = true;

		}

		System.assertEquals(true, foundUpdatedAsset, 'Asset Rev_Rec_Start_Date__c field should have been updated');
		//test scenario where we create a new Asset since related sku not populated
		System.assertEquals(true, foundInsertedAsset, 'Asset should have been inserted');
		//test scenario where we de-activate an Asset since none of the new OLIs look up to it
		System.assertEquals(true, foundDeActivatedAsset, 'Asset should have been de-activated');

		newRenewalOpp = [
				SELECT Id, Plan_Integration_Status__c
				FROM Opportunity
				WHERE Id = :newRenewalOpp.Id
				LIMIT 1
		];
		System.assertEquals(trac_OpportunityPlanHandler.SKUS_PROCESSED_STATUS, newRenewalOpp.Plan_Integration_Status__c);
	}

	static testMethod void testPrimaryExpansionOppLineItems() {
		Test.startTest();
		//GIVEN
		//  An Opp with a Primary OLI with Product X
		//  A Contract with a Primary Asset with Product X
		testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
		testContract.Payment_Type__c = trac_PlanTriggerHandler.BILL_TO;
		testContract.Currency_Code__c = 'USD';
		testContract.Primary_System_Admin__c = 'admin@testtest.com';
		insert testContract;

		Opportunity newExpansionOpp
				= trac_TestUtils.createOppPipelinePPPID(
						'test expansion opp',
						'Negotiate',
						Date.today().addDays(10),
						String.valueOf(pppId)
				);

		newExpansionOpp.RecordTypeId = trac_OpportunityPlanHandler.expansionRTId;
		newExpansionOpp.Bill_To_Status__c = 'Finance Approved';
		newExpansionOpp.AccountId = testAccount.Id;
		newExpansionOpp.ContractId = testContract.Id;
		newExpansionOpp.Old_Payment_Total__c = 1000;
		insert newExpansionOpp;

		Asset asset1 = trac_TestUtils.createAsset(testProduct.Id, testContract.Id, testAccount.Id);
		asset1.Netsuite_Line_Item_ID__c = '1';
		Asset asset2 = trac_TestUtils.createAsset(testProduct6.Id, testContract.Id, testAccount.Id);
		asset2.Netsuite_Line_Item_ID__c = '2';

		insert new List<Asset>{
				asset1, asset2
		};

		OpportunityLineItem matchingOLI1 = trac_TestUtils.createOpportunityLineItem(newExpansionOpp.Id, testPBE.Id);
		matchingOLI1.TotalPrice = testPBE.UnitPrice * 1;
		insert matchingOLI1;

		//WHEN
		//  the primary Asset has had it's Product changed before the Opp goes to OPP_CLOSED_STATUS
		asset1.Product2Id = testProduct5.Id;
		update asset1;

		newExpansionOpp.Bill_To_Status__c = OPP_FINANCE_REVIEWED;
		newExpansionOpp.PO_Required__c = 'No';
		newExpansionOpp.SysAdmin_Email_Address__c = testContract.Primary_System_Admin__c;
		newExpansionOpp.ARR_Variance_Override__c = 100.00;
		newExpansionOpp.Previous_License_ARR__c = 75.00;
		newExpansionOpp.Billing_Contact_Name__c = 'billname testtest';
		newExpansionOpp.Billing_Contact_Email__c = 'billcontact@testtest.com';
		newExpansionOpp.Billing_Street__c = '123 Fake Street';
		newExpansionOpp.Billing_City__c = 'Beverly Hills';
		newExpansionOpp.Billing_Country__c = 'United States';
		update newExpansionOpp;

		newExpansionOpp.StageName = 'Closed Won';
		newExpansionOpp.Finance_Reviewed_By__c = newUser.Id;
		newExpansionOpp.Bill_To_Status__c = OPP_CLOSED_STATUS;
		update newExpansionOpp;

		Test.stopTest();

		//THEN
		//  the old Primary Asset should become de-activated
		//  a new Primary Asset should be created

		List<Asset> requeriedAssets = [
				SELECT Product2Id, Price, Quantity, Rev_Rec_Start_Date__c, Rev_Rec_End_Date__c, Netsuite_SO_ID__c,
						Netsuite_Line_Item_ID__c, Discount__c, Price_Book__c, Plan__c, Name, Status, Product2.Primary_Subscription__c
				FROM Asset
				WHERE Plan__c = :testContract.Id
		];

		Boolean foundDeActivatedAsset = false;
		Boolean foundNewPrimaryAsset = false;

		Asset newPrimarySKU = null;
		for (Asset sku : requeriedAssets) {
			if (sku.Status == INACTIVE_STATUS && sku.Id == asset1.Id)
				foundDeActivatedAsset = true;

			if (sku.Status != INACTIVE_STATUS && sku.Id != asset1.Id && sku.Product2.Primary_Subscription__c) {
				foundNewPrimaryAsset = true;
				newPrimarySKU = sku;
			}
		}

		System.assertEquals(true, foundDeActivatedAsset);
		System.assertEquals(true, foundNewPrimaryAsset);

		List<OpportunityLineItem> requeriedOLIs = [
				SELECT Id, Product2Id, Related_SKU__c, Rev_Rec_Start_Date__c
				FROM OpportunityLineItem
				WHERE Id = :matchingOLI1.Id
		];

		System.assertEquals(newPrimarySKU.Id, requeriedOLIs[0].Related_SKU__c);

	}

	static testMethod void testExpansionOppLineItems() {
		Test.startTest();
		//GIVEN
		//an existing contract with Assets
		//an existing opp with opp line items that look up to the Assets
		//a new Opportunity of Type 'Expansion' with OLIs matching some but not all of the assets, but one OLI not matching any Assets
		//(users are creating the Opp from the Contract in a flow)

		testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
		testContract.Payment_Type__c = trac_PlanTriggerHandler.BILL_TO;
		testContract.Currency_Code__c = 'USD';
		testContract.Primary_System_Admin__c = 'admin@testtest.com';
		insert testContract;

		Asset asset1 = trac_TestUtils.createAsset(testProduct.Id, testContract.Id, testAccount.Id);
		asset1.Quantity = 150;
		//Per_Unit_Price__c is Price / Quantity : 15000 / 150 = 100
		asset1.Price = 15000;
		Asset asset2 = trac_TestUtils.createAsset(testProduct2.Id, testContract.Id, testAccount.Id);
		asset2.Quantity = 200;
		asset2.Price = 20000;
		Asset asset3 = trac_TestUtils.createAsset(testProduct3.Id, testContract.Id, testAccount.Id);
		asset3.Price = 30000;
		insert new List<Asset>{
				asset1, asset2, asset3
		};

		//a new Opportunity of Type 'Expansion' with Opportunity Line Items matching the existing assets
		// (users are creating the Opp from the Contract in a flow)
		Opportunity newExpansionOpp
				= trac_TestUtils.createOppPipelinePPPID(
						'test expansion opp',
						'Negotiate',
						Date.today().addDays(10),
						String.valueOf(pppId)
				);
		//newExpansionOpp.ContractId = testContract.Id;
		newExpansionOpp.RecordTypeId = trac_OpportunityPlanHandler.expansionRTId;
		newExpansionOpp.Bill_To_Status__c = 'Finance Approved';
		newExpansionOpp.AccountId = testAccount.Id;
		newExpansionOpp.ContractId = testContract.Id;
		newExpansionOpp.Old_Payment_Total__c = 1000;
		insert newExpansionOpp;

		OpportunityLineItem matchingOLI1 = trac_TestUtils.createOpportunityLineItem(newExpansionOpp.Id, testPBE.Id);
		matchingOLI1.Quantity = 150;
		matchingOLI1.TotalPrice = null;
		matchingOLI1.UnitPrice = 100;
		OpportunityLineItem matchingOLI2 = trac_TestUtils.createOpportunityLineItem(newExpansionOpp.Id, testPBE2.Id);
		matchingOLI2.Quantity = 200;
		matchingOLI2.TotalPrice = null;
		matchingOLI2.UnitPrice = 100;
		OpportunityLineItem nonMatchingOLI2 = trac_TestUtils.createOpportunityLineItem(newExpansionOpp.Id, testPBE4.Id);
		nonMatchingOLI2.Quantity = 200;
		nonMatchingOLI2.TotalPrice = null;
		nonMatchingOLI2.UnitPrice = 200;
		insert new List<OpportunityLineItem>{
				matchingOLI1, matchingOLI2, nonMatchingOLI2
		};
		Test.stopTest();

		//WHEN
		//opp goes to finance approved
		newExpansionOpp.Reason_Won_Details__c = 'Closed Won';

		newExpansionOpp.Bill_To_Status__c = OPP_FINANCE_REVIEWED;

		newExpansionOpp.PO_Required__c = 'NO';
		newExpansionOpp.SysAdmin_Email_Address__c = testContract.Primary_System_Admin__c;
		newExpansionOpp.ARR_Variance_Override__c = 100.00;
		newExpansionOpp.Previous_License_ARR__c = 75.00;
		newExpansionOpp.Billing_Contact_Name__c = 'billname testtest';
		newExpansionOpp.Billing_Contact_Email__c = 'billcontact@testtest.com';
		newExpansionOpp.Billing_Street__c = '123 Fake Street';
		newExpansionOpp.Billing_City__c = 'Beverly Hills';
		newExpansionOpp.Billing_Country__c = 'United States';
		update newExpansionOpp;

		newExpansionOpp.StageName = 'Closed Won';
		newExpansionOpp.Finance_Reviewed_By__c = newUser.Id;
		newExpansionOpp.Bill_To_Status__c = OPP_CLOSED_STATUS;
		update newExpansionOpp;

		//THEN
		//make sure that the Assets were created for the OLI that did not already have an Asset
		//make sure other assets were updated
		//make sure OLIs were linked back to their SKUs through the related to SKU
		List<Asset> requeriedAssets = [
				SELECT Product2Id, Price, Quantity, Rev_Rec_Start_Date__c, Rev_Rec_End_Date__c, Netsuite_SO_ID__c,
						Netsuite_Line_Item_ID__c, Discount__c, Price_Book__c, Plan__c, Name, Status
				FROM Asset
				WHERE Plan__c = :testContract.Id
		];

		//might need to loop to find the right assets to inspect
		Boolean foundUpdatedAsset1 = false;
		Boolean foundUpdatedAsset2 = false;
		Boolean foundNewAssetForOLI3 = false;

		Set<Id> newOliIds = new Set<Id>{
				matchingOLI1.Id, matchingOLI2.Id, nonMatchingOLI2.Id
		};

		List<OpportunityLineItem> requeriedOLIs = [
				SELECT Id, Product2Id, Related_SKU__c, Rev_Rec_Start_Date__c, Quantity
				FROM OpportunityLineItem
				WHERE Id in :newOliIds
		];

		for (Asset asset : requeriedAssets) {

			if (asset.Quantity == 300)
				foundUpdatedAsset1 = true;

			if (asset.Quantity == 400)
				foundUpdatedAsset2 = true;

			if (asset.Product2Id == testProduct4.Id)
				foundNewAssetForOLI3 = true;

		}

		System.assertEquals(true, foundUpdatedAsset1, 'Asset Quantity should have been updated to 300');
		//test scenario where we create a new Asset since related sku not populated
		System.assertEquals(true, foundUpdatedAsset2, 'Asset Quantity should have been updated to 400');
		//test scenario where we de-activate an Asset since none of the new OLIs look up to it
		System.assertEquals(true, foundNewAssetForOLI3, 'Asset should have been de-activated');

		System.assertEquals(false, requeriedOLIs[0].Related_SKU__c == null, 'Related_SKU__c should be populated on OLI for Expansion');
		System.assertEquals(false, requeriedOLIs[1].Related_SKU__c == null, 'Related_SKU__c should be populated on OLI for Expansion');
		System.assertEquals(false, requeriedOLIs[2].Related_SKU__c == null, 'Related_SKU__c should be populated on OLI for Expansion');

		newExpansionOpp = [
				SELECT Id, Plan_Integration_Status__c
				FROM Opportunity
				WHERE Id = :newExpansionOpp.Id
				LIMIT 1
		];
		System.assertEquals(trac_OpportunityPlanHandler.SKUS_PROCESSED_STATUS, newExpansionOpp.Plan_Integration_Status__c);

	}

	static testMethod void testNewOppTypeCreateSKUs() {
		Test.startTest();

		//GIVEN
		//  An Opp with Opp Line Items, a Contract and no SKUs

		testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
		testContract.Payment_Type__c = trac_PlanTriggerHandler.BILL_TO;
		insert testContract;

		Opportunity newNewOpp
				= trac_TestUtils.createOppPipelinePPPID(
						'test New opp',
						'Negotiate',
						Date.today().addDays(10),
						String.valueOf(pppId)
				);
		//newNewOpp.ContractId = testContract.Id;
		newNewOpp.RecordTypeId = trac_OpportunityPlanHandler.newRTId;
		newNewOpp.Bill_To_Status__c = 'Finance Approved';
		newNewOpp.AccountId = testAccount.Id;
		insert newNewOpp;

		OpportunityLineItem newOliWithoutAsset = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE.Id);
		newOliWithoutAsset.TotalPrice = testPBE.UnitPrice * 1;
		OpportunityLineItem newOliWithoutAsset1 = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE2.Id);
		newOliWithoutAsset1.TotalPrice = testPBE2.UnitPrice * 1;
		OpportunityLineItem newOliWithoutAsset2 = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE3.Id);
		newOliWithoutAsset2.TotalPrice = testPBE3.UnitPrice * 1;

		insert new List<OpportunityLineItem>{
				newOliWithoutAsset, newOliWithoutAsset1, newOliWithoutAsset2
		};
		Test.stopTest();

		//WHEN
		//  The Opp goes to OPP_CLOSED_STATUS
		newNewOpp.Bill_To_Status__c = OPP_FINANCE_REVIEWED;
		newNewOpp.SysAdmin_Email_Address__c = 'test@test.com';
		newNewOpp.PO_Required__c = 'NO';
		update newNewOpp;

		newNewOpp.StageName = 'Closed Won';
		newNewOpp.Finance_Reviewed_By__c = newUser.Id;
		newNewOpp.Bill_To_Status__c = OPP_CLOSED_STATUS;
		update newNewOpp;

		//THEN
		//  SKUs should be created for all Opp Line Items that are 'recurring'
		//  The Opp Line Items should be updated with 'related sku' lookup
		Map<Id, Asset> createdSKUsMap = new Map<Id, Asset>([
				SELECT Id, Product2Id, Price, Quantity, Rev_Rec_Start_Date__c, Rev_Rec_End_Date__c, Netsuite_SO_ID__c,
						Netsuite_Line_Item_ID__c, Discount__c, Price_Book__c, Plan__c, Name, Status
				FROM Asset
				WHERE Plan__c = :testContract.Id
		]);

		System.assertEquals(3, createdSKUsMap.size());

		List<OpportunityLineItem> requeriedOLIs = [
				SELECT Id, Product2Id, Related_SKU__c, Rev_Rec_Start_Date__c, Quantity
				FROM OpportunityLineItem
				WHERE OpportunityId = :newNewOpp.Id
		];

		System.assertEquals(true, createdSKUsMap.containsKey(requeriedOLIs[0].Related_SKU__c));
		System.assertEquals(true, createdSKUsMap.containsKey(requeriedOLIs[1].Related_SKU__c));
		System.assertEquals(true, createdSKUsMap.containsKey(requeriedOLIs[2].Related_SKU__c));

		//  Opp should be updated on the Plan_Integration_Status__c field
		newNewOpp = [
				SELECT Id, Plan_Integration_Status__c, ContractId
				FROM Opportunity
				WHERE Id = :newNewOpp.Id
				LIMIT 1
		];
		System.assertEquals(trac_OpportunityPlanHandler.SKUS_PROCESSED_STATUS, newNewOpp.Plan_Integration_Status__c);
		System.assertEquals(testContract.Id, newNewOpp.ContractId);

	}

	static testMethod void testValidatePPPIdsSuccess() {
		Test.startTest();

		Opportunity newNewOpp
				= trac_TestUtils.createOppPipelinePPPID(
						'test New opp',
						'Negotiate',
						Date.today().addDays(10),
						String.valueOf(pppId)
				);
		newNewOpp.RecordTypeId = trac_OpportunityPlanHandler.newRTId;
		newNewOpp.Bill_To_Status__c = 'Finance Approved';
		newNewOpp.AccountId = testAccount.Id;
		insert newNewOpp;

		OpportunityLineItem newOliWithoutAsset = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE.Id);
		newOliWithoutAsset.TotalPrice = testPBE.UnitPrice * 1;
		OpportunityLineItem newOliWithoutAsset1 = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE2.Id);
		newOliWithoutAsset1.TotalPrice = testPBE2.UnitPrice * 1;
		OpportunityLineItem newOliWithoutAsset2 = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE3.Id);
		newOliWithoutAsset2.TotalPrice = testPBE3.UnitPrice * 1;

		insert new List<OpportunityLineItem>{
				newOliWithoutAsset, newOliWithoutAsset1, newOliWithoutAsset2
		};

		newNewOpp.Bill_To_Status__c = OPP_FINANCE_REVIEWED;
		newNewOpp.SysAdmin_Email_Address__c = 'test@test.com';

		update newNewOpp;

		Boolean successfulDML = true;

		newNewOpp.StageName = 'Closed Won';
		newNewOpp.Finance_Reviewed_By__c = newUser.Id;
		newNewOpp.Bill_To_Status__c = OPP_CLOSED_STATUS;
		update newNewOpp;

		try {
			update newNewOpp;
		} catch (Exception ex) {
			System.debug(ex);
			successfulDML = false;
		}
		Test.stopTest();

		System.assertEquals(true, successfulDML, 'Opportunity should have passed fat finger PPPID validation');

		newNewOpp = [
				SELECT Plan_Integration_Status__c
				FROM Opportunity
				WHERE Id = :newNewOpp.Id
				Limit 1
		];
		System.assertEquals(
				trac_OpportunityPlanHandler.PENDING_INTEGRATION_STATUS,
				newNewOpp.Plan_Integration_Status__c,
				'Opportunity should be marked pending integration'
		);

	}

	static testMethod void testValidatePPPIdsFailure() {

		testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
		insert testContract;
		Test.setCreatedDate(testContract.Id, Datetime.newInstance(2017, 05, 01));

		Test.startTest();
		Opportunity newNewOpp
				= trac_TestUtils.createOppPipelinePPPID(
						'test New opp',
						'Negotiate',
						Date.today().addDays(10),
						String.valueOf(pppId)
				);
		//newNewOpp.ContractId = testContract.Id;
		newNewOpp.RecordTypeId = trac_OpportunityPlanHandler.newRTId;
		newNewOpp.Bill_To_Status__c = 'Finance Approved';
		newNewOpp.AccountId = testAccount.Id;
		insert newNewOpp;

		newNewOpp.StageName = 'Closed Won';
		newNewOpp.Bill_To_Status__c = OPP_CLOSED_STATUS;

		Boolean successfulDML = true;
		String errorMessage = '';

		try {
			update newNewOpp;
		} catch (Exception ex) {
			successfulDML = false;
			errorMessage = ex.getMessage();
		}
		Test.stopTest();

		System.assertEquals(false, successfulDML, 'Opportunity should have failed fat finger PPPID validation');
		System.assertEquals(true, errorMessage.contains(trac_OpportunityPlanHandler.FAT_FINGER_ERROR_MESSAGE), 'Unexpected error thrown');
	}
}