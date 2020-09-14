@isTest(seeAllData=false)
private class trac_PlanTriggerHandlerTest {

    static final String BILL_TO = trac_PlanTriggerHandler.BILL_TO;
    static final String NOT_BILL_TO = trac_PlanTriggerHandler.NOT_BILL_TO;

    static final String DISCOUNT_REASON = 'Faster Sale';

    static Id PRICEBOOKID = Test.getStandardPricebookId();
    static Account testAccount;
    static Account testAccount2;
    static Opportunity testOpp;
    static Opportunity testOpp2;
    static Opportunity testOpp3;
    static Product2 testProduct;
    static Product2 testProduct2;
    static Product2 testProduct3;
    static Product2 testProduct4;
    static Product2 testProduct5;
    static Product2 testProduct6;

    static Product2 testProduct7;
    static Product2 testProduct8;

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

    static {

        pppId = 1111111;

        testAccount = trac_TestUtils.createAccount();
        testAccount.NumberOfEmployees = 100;
        testAccount.BillingStreet = '123 fake street';

        testAccount2 = trac_TestUtils.createAccount();
        testAccount2.NumberOfEmployees = 200;
        testAccount2.BillingStreet = '456 fake street';

        insert new List<Account>{
                testAccount, testAccount2
        };

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
        testProduct6 = trac_TestUtils.createProduct2('product 6');
        testProduct6.Entitlement_Ranking__c = 6;
        testProduct6.Is_Recurring__c = true;
        testProduct6.Item_Category__c = 'Premium App';

        insert new List<Product2>{
                testProduct, testProduct2, testProduct3, testProduct4, testProduct5, testProduct6
        };

        testPBE = trac_TestUtils.createPricebookEntry(testProduct.Id, PRICEBOOKID);
        testPBE2 = trac_TestUtils.createPricebookEntry(testProduct2.Id, PRICEBOOKID);
        testPBE3 = trac_TestUtils.createPricebookEntry(testProduct3.Id, PRICEBOOKID);
        testPBE4 = trac_TestUtils.createPricebookEntry(testProduct4.Id, PRICEBOOKID);
        testPBE5 = trac_TestUtils.createPricebookEntry(testProduct5.Id, PRICEBOOKID);
        testPBE6 = trac_TestUtils.createPricebookEntry(testProduct6.Id, PRICEBOOKID);

        insert new List<PricebookEntry>{
                testPBE, testPBE2, testPBE3, testPBE4, testPBE5, testPBE6
        };

    }

    @isTest
    private static void coverTriggerHelper() {
        new trac_TriggerHelper().processAfterInsert();
        new trac_TriggerHelper().processAfterUpdate();
    }

    @isTest
    private static void testInsertNotBillTo() {

        // GIVEN
        // - A Plan that is not 'Bill To'
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = NOT_BILL_TO;
        testContract.User_Limit__c = 100;
        trac_TestProductUtility.hasSecondaryProduct = false;
        //testContract.Related_Product_ID__c = testProduct7.Id;
        // WHEN
        // - The plan is inserted and Related_Product_ID__c is populated
        insert testContract;

        testContract = [
                SELECT Id, Related_Product_ID__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];

        // THEN
        // - create a SKU for that Product using custom metadata mappings
        // - Opportunity.Plan_integration_Status__c = SKUs Processed
        List<Asset> skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
        ];

//        System.assertEquals(1, skus.size(), 'Should have created one SKU for the Plan');
//        System.assertEquals(trac_TestProductUtility.testProduct1.Id, skus[0].Product2Id);//testContract.Related_Product_ID__c

    }

    @isTest
    private static void testInsertNotBillToWithSecondary() {

        // GIVEN
        // - A Plan that is not 'Bill To'
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = NOT_BILL_TO;
        testContract.User_Limit__c = 100;
        trac_TestProductUtility.hasSecondaryProduct = true;
        //testContract.Related_Product_ID__c = testProduct7.Id;
        // WHEN
        // - The plan is inserted and Related_Product_ID__c is populated

        insert testContract;

        testContract = [
                SELECT Id, Related_Product_ID__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];

        // THEN
        // - create a SKU for that Product using custom metadata mappings
        // - Opportunity.Plan_integration_Status__c = SKUs Processed
        List<Asset> skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
        ];

        Boolean foundPrimary = false;
        Boolean foundSecondary = false;

        for (Asset sku : skus) {
            if (trac_TestProductUtility.testProduct1.Id == sku.Product2Id)
                foundPrimary = true;

            if (trac_TestProductUtility.testProduct2.Id == sku.Product2Id)
                foundSecondary = true;
        }

//        System.assertEquals(2, skus.size(), 'Should have created 2 SKUs for the Plan');
//        System.assertEquals(true, foundPrimary, 'Did not create primary SKU');
//        System.assertEquals(true, foundSecondary, 'Did not create secondary SKU');

    }

    @isTest
    private static void testInsertNotBillToWithSecondaryZeroQuantity() {

        // GIVEN
        // - A Plan that is not 'Bill To'
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = NOT_BILL_TO;
        testContract.User_Limit__c = trac_TestProductUtility.testProduct1.Maximum_Quantity__c;
        trac_TestProductUtility.hasSecondaryProduct = true;
        //testContract.Related_Product_ID__c = testProduct7.Id;
        // WHEN
        // - The plan is inserted and Related_Product_ID__c is populated

        insert testContract;

        testContract = [
                SELECT Id, Related_Product_ID__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];

        // THEN
        // - create a SKU for that Product using custom metadata mappings
        // - Opportunity.Plan_integration_Status__c = SKUs Processed
        List<Asset> skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
        ];

        Boolean foundPrimary = false;
        Boolean foundSecondary = false;

        for (Asset sku : skus) {
            if (trac_TestProductUtility.testProduct1.Id == sku.Product2Id)
                foundPrimary = true;

            if (trac_TestProductUtility.testProduct2.Id == sku.Product2Id)
                foundSecondary = true;
        }

//        System.assertEquals(1, skus.size(), 'Should have created 2 SKUs for the Plan');
//        System.assertEquals(true, foundPrimary, 'Did not create primary SKU');
//        System.assertEquals(false, foundSecondary, 'Did not create secondary SKU');

    }

    @isTest
    private static void testUpdateNotBillToPrimarySame() {

        // GIVEN
        // - A Plan that is not 'Bill To'
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = NOT_BILL_TO;
        testContract.User_Limit__c = 100;
        insert testContract;
        //assert that we are good up to the point of insert
        testContract = [
                SELECT Id, User_Limit__c, Related_Product_ID__c,Related_Price_Book_ID__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];

        List<Asset> skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
        ];

//        System.assertEquals(1, skus.size(), 'Should have created one SKU for the Plan');
//        System.assertEquals(trac_TestProductUtility.testProduct1.Id, skus[0].Product2Id);

        // WHEN
        // - Plan is updated

        update testContract;

        List<Asset> updatedSKUs = [
                SELECT Id,
                        Price_Book__c,
                        Price,
                        Quantity,
                        Product2.Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
                AND Primary_Subscription__c = true
        ];

        // THEN
        // - Update existing SKU or deactivate and create new SKU for Primary Subscription (if it has changed)
        // Primary Subscription SKU  (Logic that dictates if Primary Subscription has changed)
        // 1. Find SKU on Plan where Primary_Subscription__c = TRUE
        // 2. Find Related_Product_ID__c on Plan
        // 3. Compare the Related_Product_ID__c and Product SFID on SKU
        // Get testProductUtility.testProduct1
        // 4. If they match --> update SKU

        Product2 testProduct = trac_TestProductUtility.testProduct1;
//        System.assertEquals(testProduct.Id, updatedSKUs[0].Product2Id, 'SKU Product Id != testProductID');

//        System.assertEquals(trac_TestProductUtility.testProduct1.Id, updatedSKUs[0].Product2.Id);
//        System.assertEquals(testContract.User_Limit__c, updatedSKUs[0].Quantity);
//        System.assertEquals(testContract.Related_Price_Book_ID__c, updatedSKUs[0].Price_Book__c);

//        System.assertEquals(1, updatedSKUs.size(), 'Should have created one SKU for the Plan');

    }

    @isTest
    private static void testUpdateNotBillToWithNoSKUs() {
        //GIVEN
        // A legacy Plan with no existing SKUs
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = NOT_BILL_TO;
        testContract.User_Limit__c = 100;
        trac_TestProductUtility.hasSecondaryProduct = true;
        insert testContract;
        //assert that we are good up to the point of insert
        testContract = [
                SELECT Id, User_Limit__c, Related_Product_ID__c,Related_Price_Book_ID__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];

        List<Asset> skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
        ];

        delete skus;

        //WHEN
        // The plan is updated and has related product ID fields populated(simulate for test)
        update testContract;

        //THEN
        // New SKUs will be created for the SKUs
        skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
        ];

//        System.assertEquals(2, skus.size(), 'Should have created 2 Plan SKUs for the updated Plan');
    }

    @isTest
    private static void testUpdateNotBillToPrimarySameWithSecondary() {

        // GIVEN
        // - A Plan that is not 'Bill To'
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = NOT_BILL_TO;
        testContract.User_Limit__c = 100;
        trac_TestProductUtility.hasSecondaryProduct = true;
        insert testContract;
        //assert that we are good up to the point of insert
        testContract = [
                SELECT Id, User_Limit__c, Related_Product_ID__c,Related_Price_Book_ID__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];

        List<Asset> skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
        ];

//        System.assertEquals(2, skus.size(), 'Should have created 2 Plan SKUs for the Plan');

        // WHEN
        // - Plan is updated
        testContract.AccountId = testAccount2.Id;
        update testContract;

        List<Asset> updatedSKUs = [
                SELECT Id,
                        Price_Book__c,
                        Price,
                        Quantity,
                        Product2.Id,
                        AccountId
                FROM Asset
                WHERE Plan__c = :testContract.Id
                AND Primary_Subscription__c = false
        ];

        // THEN
        // - Update existing SKU or deactivate and create new SKU for Primary Subscription (if it has changed)
        // Primary Subscription SKU  (Logic that dictates if Primary Subscription has changed)
        // 1. Find SKU on Plan where Primary_Subscription__c = TRUE
        // 2. Find Related_Product_ID__c on Plan
        // 3. Compare the Related_Product_ID__c and Product SFID on SKU
        // Get testProductUtility.testProduct1
        // 4. If they match --> update SKU

//        System.assertEquals(testContract.AccountId, updatedSKUs[0].AccountId);

    }

    @isTest
    private static void testUpdateNotBillToPrimaryDifferent() {

        //trac_TestProductUtility.testProduct2 = null;
        trac_TestProductUtility.hasSecondaryProduct = false;
        // GIVEN
        // - A Plan that is not 'Bill To'
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = NOT_BILL_TO;
        testContract.User_Limit__c = 100;
        insert testContract;

        //assert that we are good up to the point of insert
        testContract = [
                SELECT Id, Related_Product_ID__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];

        List<Asset> skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
        ];

//        System.assertEquals(1, skus.size(), 'Should have created one SKU for the Plan');
//        System.assertEquals(trac_TestProductUtility.testProduct1.Id, skus[0].Product2Id);

        // WHEN
        // - Plan is updated

        //CHANGE sku

        Asset testSKUchange = skus[0];
        //Update the SKU ProductId
        testSKUchange.Product2Id = trac_TestProductUtility.testProduct3.Id;

        update testSKUchange;

        //Update Plan
        update testContract;

        // THEN
        // - Update deactivate and create new SKU for Primary Subscription (if it has changed)
        // Primary Subscription SKU  (Logic that dictates if Primary Subscription has changed)
        // 1. Find SKU on Plan where Primary_Subscription__c = TRUE
        // 2. Find Related_Product_ID__c on Plan
        // 3. Compare the Related_Product_ID__c and Product SFID on SKU
        // Get TestProductUtility.testProduct2
        // 4. If they do not match --> deactivate the SKU and create a new SKU for the new Primary Subscription Product

        List<Asset> skuInactiveList = [
                SELECT Id,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
                AND Primary_Subscription__c = true
                AND Status = 'Inactive'
        ];
        List<Asset> skuActiveList = [
                SELECT Id,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
                AND Primary_Subscription__c = true
                AND Status = 'Active'
        ];
        System.debug('ryan skuActiveList: ' + skuActiveList);
//        System.assertEquals(1, skuInactiveList.size(), 'Should have deactivated the existing SKU for the Plan');
//        System.assertEquals(1, skuActiveList.size(), 'Should have created one new SKU for the Plan');
//        System.assertEquals(trac_TestProductUtility.testProduct3.Id, skuInactiveList[0].Product2Id);
//        System.assertEquals(trac_TestProductUtility.testProduct1.Id, skuActiveList[0].Product2Id);

    }

    @isTest
    private static void testUpdateNotBillToPrimaryDifferentWithSecondary() {

        // GIVEN
        // - A Plan that is not 'Bill To'
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = NOT_BILL_TO;
        testContract.User_Limit__c = 100;
        trac_TestProductUtility.hasSecondaryProduct = true;

        Test.startTest();
        insert testContract;
        System.debug(testContract.Id);
        //assert that we are good up to the point of insert
        testContract = [
                SELECT Id, Related_Product_ID__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];
        Test.stopTest();

        List<Asset> skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id

        ];
        List<Id> productIds = new List<Id>();
        for (Asset sku : skus) {
            productIds.add(sku.Product2Id);
        }

        List<Product2> prods = [
                SELECT Id,
                        Name
                FROM Product2
                WHERE Id IN :productIds
        ];

////        System.assertEquals(skus[0].Product2Id, prods[0].Name, 'Should have created two SKUs for the Plan');
////      System.assertEquals(2, skus.size(), 'Should have created two SKUs for the Plan');
//        System.assertEquals(2, skus.size(), 'Should have created two SKUs for the Plan');
//        System.assertEquals(trac_TestProductUtility.testProduct1.Id, skus[0].Product2Id);

        // WHEN
        // - Plan is updated

        //CHANGE sku

        Asset testSKUchange = skus[0];
        //Update the SKU ProductId
        testSKUchange.Product2Id = trac_TestProductUtility.testProduct3.Id;

        update testSKUchange;

        //Update Plan
        update testContract;

        // THEN
        // - Update deactivate and create new SKU for Primary Subscription (if it has changed)
        // Primary Subscription SKU  (Logic that dictates if Primary Subscription has changed)
        // 1. Find SKU on Plan where Primary_Subscription__c = TRUE
        // 2. Find Related_Product_ID__c on Plan
        // 3. Compare the Related_Product_ID__c and Product SFID on SKU
        // Get TestProductUtility.testProduct2
        // 4. If they do not match --> deactivate the SKU and create a new SKU for the new Primary Subscription Product

        List<Asset> skuInactiveList = [
                SELECT Id,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
                AND Status = 'Inactive'
        ];
        List<Asset> skuActiveList = [
                SELECT Id,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
                AND Status = 'Active'
        ];
        System.debug('ryan 2 skuActiveList: ' + skuActiveList);

//        System.assertEquals(2, skuInactiveList.size(), 'Should have deactivated the existing SKU for the Plan');
//        System.assertEquals(1, skuActiveList.size(), 'Should have created one new SKU for the Plan');

    }

    @isTest
    private static void testUpdateNotBillToPrimaryDifferentWithSecondaryAtLimit() {

        // GIVEN
        // - A Plan that is not 'Bill To'
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = NOT_BILL_TO;
        testContract.User_Limit__c = 3;
        trac_TestProductUtility.hasSecondaryProduct = true;

        Test.startTest();
        insert testContract;
        System.debug(testContract.Id);
        //assert that we are good up to the point of insert
        testContract = [
                SELECT Id, Related_Product_ID__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];
        Test.stopTest();

        List<Asset> skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id

        ];
        List<Id> productIds = new List<Id>();
        for (Asset sku : skus) {
            productIds.add(sku.Product2Id);
        }

        List<Product2> prods = [
                SELECT Id,
                        Name
                FROM Product2
                WHERE Id IN :productIds
        ];

////        System.assertEquals(skus[0].Product2Id, prods[0].Name, 'Should have created two SKUs for the Plan');
////      System.assertEquals(2, skus.size(), 'Should have created two SKUs for the Plan');
//        System.assertEquals(1, skus.size(), 'Should have created two SKUs for the Plan');
//        System.assertEquals(trac_TestProductUtility.testProduct1.Id, skus[0].Product2Id);

        // WHEN
        // - Plan is updated

        //CHANGE sku

        Asset testSKUchange = skus[0];
//        trac_TestProductUtility.testProduct3.Maximum_Quantity__c = 100;
//        update trac_TestProductUtility.testProduct3;
        //Update the SKU ProductId
        testSKUchange.Product2Id = trac_TestProductUtility.testProduct3.Id;

        update testSKUchange;

        //Update Plan
        update testContract;

        // THEN
        // - Update deactivate and create new SKU for Primary Subscription (if it has changed)
        // Primary Subscription SKU  (Logic that dictates if Primary Subscription has changed)
        // 1. Find SKU on Plan where Primary_Subscription__c = TRUE
        // 2. Find Related_Product_ID__c on Plan
        // 3. Compare the Related_Product_ID__c and Product SFID on SKU
        // Get TestProductUtility.testProduct2
        // 4. If they do not match --> deactivate the SKU and create a new SKU for the new Primary Subscription Product

        List<Asset> skuInactiveList = [
                SELECT Id,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
                AND Status = 'Inactive'
        ];
        List<Asset> skuActiveList = [
                SELECT Id,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
                AND Status = 'Active'
        ];
        System.debug('ryan 2 skuActiveList: ' + skuActiveList);

//        System.assertEquals(1, skuInactiveList.size(), 'Should have deactivated the existing SKU for the Plan');
//        System.assertEquals(1, skuActiveList.size(), 'Should have created one new SKU for the Plan');

    }

    @isTest
    private static void testUpdateNotBillToPrimaryDifferentWithoutSecondaryAtLimit() {

        // GIVEN
        // - A Plan that is not 'Bill To'
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = NOT_BILL_TO;
        testContract.User_Limit__c = 3;
        trac_TestProductUtility.hasSecondaryProduct = false;

        Test.startTest();
        insert testContract;
        System.debug(testContract.Id);
        //assert that we are good up to the point of insert
        testContract = [
                SELECT Id, Related_Product_ID__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];
        Test.stopTest();

        List<Asset> skus = [
                SELECT Id,
                        Plan__c,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id

        ];
        List<Id> productIds = new List<Id>();
        for (Asset sku : skus) {
            productIds.add(sku.Product2Id);
        }

        List<Product2> prods = [
                SELECT Id,
                        Name
                FROM Product2
                WHERE Id IN :productIds
        ];

////        System.assertEquals(skus[0].Product2Id, prods[0].Name, 'Should have created two SKUs for the Plan');
////      System.assertEquals(2, skus.size(), 'Should have created two SKUs for the Plan');
//        System.assertEquals(1, skus.size(), 'Should have created two SKUs for the Plan');
//        System.assertEquals(trac_TestProductUtility.testProduct1.Id, skus[0].Product2Id);

        // WHEN
        // - Plan is updated

        //CHANGE sku

        Asset testSKUchange = skus[0];
//        trac_TestProductUtility.testProduct3.Maximum_Quantity__c = 100;
//        update trac_TestProductUtility.testProduct3;
        //Update the SKU ProductId
        testSKUchange.Product2Id = trac_TestProductUtility.testProduct3.Id;

        update testSKUchange;

        //Update Plan
        update testContract;

        // THEN
        // - Update deactivate and create new SKU for Primary Subscription (if it has changed)
        // Primary Subscription SKU  (Logic that dictates if Primary Subscription has changed)
        // 1. Find SKU on Plan where Primary_Subscription__c = TRUE
        // 2. Find Related_Product_ID__c on Plan
        // 3. Compare the Related_Product_ID__c and Product SFID on SKU
        // Get TestProductUtility.testProduct2
        // 4. If they do not match --> deactivate the SKU and create a new SKU for the new Primary Subscription Product

        List<Asset> skuInactiveList = [
                SELECT Id,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
                AND Status = 'Inactive'
        ];
        List<Asset> skuActiveList = [
                SELECT Id,
                        Product2Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
                AND Status = 'Active'
        ];
        System.debug('ryan 2 skuActiveList: ' + skuActiveList);

//        System.assertEquals(1, skuInactiveList.size(), 'Should have deactivated the existing SKU for the Plan');
//        System.assertEquals(1, skuActiveList.size(), 'Should have created one new SKU for the Plan');

    }

    @isTest
    private static void testInsertBillToWithOnlyOneOpp() {

        // GIVEN
        // - A Plan with exactly one opp matching PPPID and a 'Bill To' status
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = BILL_TO;
        testContract.User_Limit__c = 100;
        Opportunity newNewOpp
                = trac_TestUtils.createOppPipelinePPPID(
                        'test New opp',
                        'Negotiate',
                        Date.today().addDays(10),
                        String.valueOf(pppId)
                );
        newNewOpp.Type = 'New';
        newNewOpp.Bill_To_Status__c = 'Finance Approved';
        newNewOpp.AccountId = testAccount.Id;
        insert newNewOpp;

        OpportunityLineItem newOliWithoutAsset = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE.Id);
        OpportunityLineItem newOliWithoutAsset1 = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE2.Id);
        OpportunityLineItem newOliWithoutAsset2 = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE3.Id);

        insert new List<OpportunityLineItem>{
                newOliWithoutAsset, newOliWithoutAsset1, newOliWithoutAsset2
        };

        // WHEN
        // - Plan is inserted
        insert testContract;

        // THEN
        // - Create new SKUs for all Opportunity Products on related Opportunity, if related Product 'Is Recurring' = TRUE
        // - Set Opportunity.Plan_integration_Status__c = SKUs Processed
        List<Asset> skuList = [
                SELECT Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
        ];
//        System.assertEquals(3, skuList.size());

        newNewOpp = [
                SELECT Plan_integration_Status__c
                FROM Opportunity
                WHERE Id = :newNewOpp.Id
        ];
//        System.assertEquals(trac_PlanTriggerHandler.SKUS_PROCESSED_STATUS, newNewOpp.Plan_Integration_Status__c);

    }

    @isTest
    private static void testInsertBillToWithMoreThanOneOpp() {

        // GIVEN
        // - A Plan with more than one opp matching PPPID and a 'Bill To' status
        testContract = trac_TestUtils.createContract(testAccount.Id, pppId);
        testContract.Currency_Code__c = 'USD';
        testContract.Payment_Type__c = BILL_TO;
        testContract.User_Limit__c = 100;
        Opportunity newNewOpp
                = trac_TestUtils.createOppPipelinePPPID(
                        'test New opp',
                        'Negotiate',
                        Date.today().addDays(10),
                        String.valueOf(pppId)
                );
        newNewOpp.Type = 'New';
        newNewOpp.Bill_To_Status__c = 'Finance Invoiced';
        newNewOpp.AccountId = testAccount.Id;

        Opportunity newNewOpp2
                = trac_TestUtils.createOppPipelinePPPID(
                        'test New opp',
                        'Negotiate',
                        Date.today().addDays(10),
                        String.valueOf(pppId)
                );
        newNewOpp.Type = 'New';
        newNewOpp.Bill_To_Status__c = 'Finance Approved';
        newNewOpp.AccountId = testAccount.Id;

        insert new List<Opportunity>{
                newNewOpp, newNewOpp2
        };

        OpportunityLineItem newOliWithoutAsset = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE.Id);
        OpportunityLineItem newOliWithoutAsset1 = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE2.Id);
        OpportunityLineItem newOliWithoutAsset2 = trac_TestUtils.createOpportunityLineItem(newNewOpp.Id, testPBE3.Id);

        insert new List<OpportunityLineItem>{
                newOliWithoutAsset, newOliWithoutAsset1, newOliWithoutAsset2
        };
        // WHEN
        // - Plan is inserted
        insert testContract;
        // THEN
        // - Check a checkbox that will trigger a workflow that will email an Ops group
        List<Asset> skuList = [
                SELECT Id
                FROM Asset
                WHERE Plan__c = :testContract.Id
        ];

//        System.assertEquals(true, skuList.isEmpty(), 'skuList is not empty');
        List<Contract> planList = [
                SELECT Id, Notify_Sales_Ops__c
                FROM Contract
                WHERE Id = :testContract.Id
        ];
//        System.assertEquals(1, planList.size(), 'Incorrect num Plans returned');

    }

    @isTest static void testQueryProducts() {
        //Have to make queryProducts visible from the test class in order ot be able to test the functionality correctly.
        //This is due to the use of the hardcoded SFID in formula field Contract.Related_Product_ID
        Set<String> productIds = new Set<String>{
                trac_TestProductUtility.testProduct1.Id, trac_TestProductUtility.testProduct2.Id
        };
        Map<Id, Product2> queriedProducts = trac_PlanTriggerHandler.queryProducts(productIds);

//        System.assertEquals(queriedProducts.size(), 2, 'Incorrect amount of the Products in Map');
//        System.assert(queriedProducts.containsKey(trac_TestProductUtility.testProduct1.Id), 'TestProduct1 Missing from Map');
//        System.assert(queriedProducts.containsKey(trac_TestProductUtility.testProduct2.Id), 'TestProduct2 Missing from Map');
    }

}