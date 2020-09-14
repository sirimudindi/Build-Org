/**
 * @author Steve Doucette, Traction on Demand 
 * @date 2018-08-14
 */
@IsTest
public with sharing class trac_CaseNewCollaboratorTest {
    private static final String NAME_TEST = 'Test';
    private static final String EMAIL_TEST = 'Test@smartsheet.test.com';
    private static final Date TODAY = Date.today();
    private static Account account;
    private static Contract contract;
    private static Entitlement entitlement;
    private static final Integer NUM_OF_CASES = 3;

    @TestSetup
    private static void insertTestData() {
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

    @IsTest
    public static void testCaseForContact() {
        account = getAccount();
        account.Name = trac_Constants.THIS_MONTH_ACCOUNT_NAME;
        update account;
        Account acc = trac_TestUtils.createAccount();
        acc.Name = trac_Constants.LAST_MONTH_ACCOUNT_NAME;
        insert acc;
        Contact con = trac_TestUtils.createContact(NAME_TEST, EMAIL_TEST, account);
        con.Organization_Roles__c = 'test;test2;test3;test;;';
        con.Plan__c = getContract().Id;
        con.PaymentProfileId__c = '1234';
        insert con;
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < NUM_OF_CASES; i++) {
            Case c = trac_TestUtils.createCase(trac_Constants.CASE_STATUS_CLOSED, trac_Constants.CASE_ORIGIN_PHONE, EMAIL_TEST, NAME_TEST);
            c.ContactId = con.Id;
            cases.add(c);
        }

        Test.startTest();
        insert cases;
        Test.stopTest();

        List<Case> rst = [SELECT Id, EntitlementId FROM Case];
        for (Case c : rst){
            system.assertEquals(getEntitlement().Id , c.EntitlementId,'Entitlement Id should be the same');
        }
    }

    @IsTest
    public static void testCaseForLead() {
        account = getAccount();
        account.Name = trac_Constants.THIS_MONTH_ACCOUNT_NAME;
        update account;
        Lead l = trac_TestUtils.createLead(NAME_TEST, EMAIL_TEST, NAME_TEST);
        l.Plan__c = getContract().Id;
        l.PaymentProfileId__c = '1234';
        l.Organization_Roles__c = 'test; test1;1; ; test ; ;';
        insert l;
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < NUM_OF_CASES; i++) {
            Case c = trac_TestUtils.createCase(trac_Constants.CASE_STATUS_CLOSED, trac_Constants.CASE_ORIGIN_PHONE, EMAIL_TEST, NAME_TEST);
            c.Lead__c = l.Id;
            cases.add(c);
        }

        Test.startTest();
        insert cases;
        Test.stopTest();

        List<Case> rst = [SELECT Id, EntitlementId FROM Case];
        for (Case c : rst){
            system.assertEquals(getEntitlement().Id , c.EntitlementId,'Entitlement Id should be the same');
        }
    }

    @IsTest
    public static void testCaseForContactLastMonth() {
        account = getAccount();
        account.Name = trac_Constants.LAST_MONTH_ACCOUNT_NAME;
        update account;
        Contact con = trac_TestUtils.createContact(NAME_TEST, EMAIL_TEST, account);
        con.Organization_Roles__c = 'test;test2;test3;test;;';
        con.Plan__c = getContract().Id;
        con.PaymentProfileId__c = '1234';
        insert con;
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < NUM_OF_CASES; i++) {
            Case c = trac_TestUtils.createCase(trac_Constants.CASE_STATUS_CLOSED, trac_Constants.CASE_ORIGIN_PHONE, EMAIL_TEST, NAME_TEST);
            c.ContactId = con.Id;
            cases.add(c);
        }

        Test.startTest();
        insert cases;
        Test.stopTest();

        List<Case> rst = [SELECT Id, EntitlementId FROM Case];
        for (Case c : rst){
            system.assertNotEquals(getEntitlement().Id , c.EntitlementId,'Entitlement Id should be the same');
        }
    }

    @IsTest
    public static void testCaseForContactNoAccountsFoundException() {
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < NUM_OF_CASES; i++) {
            Case c = trac_TestUtils.createCase(trac_Constants.CASE_STATUS_CLOSED, trac_Constants.CASE_ORIGIN_PHONE, EMAIL_TEST, NAME_TEST);
            cases.add(c);
        }

        Test.startTest();
        try {
            insert cases;
        } catch (Exception ex) {
            System.assert(ex!=null);
        }
        Test.stopTest();

        List<Case> rst = [SELECT Id, EntitlementId FROM Case];
        for (Case c : rst){
            system.assertEquals(getEntitlement().Id , c.EntitlementId,'Entitlement Id should be the same');
        }
    }

    @IsTest
    public static void testCaseForContactNoLastMonthFoundError() {
        Account acc = trac_TestUtils.createAccount();
        acc.Name = trac_Constants.LAST_MONTH_ACCOUNT_NAME;
        insert acc;

        Contact con = trac_TestUtils.createContact(NAME_TEST, EMAIL_TEST, getAccount());
        con.Organization_Roles__c = 'test;test2;test3;test;;';
        con.Plan__c = getContract().Id;
        con.PaymentProfileId__c = '1234';
        insert con;
        List<Case> cases = new List<Case>();
        for (Integer i = 0; i < NUM_OF_CASES; i++) {
            Case c = trac_TestUtils.createCase(trac_Constants.CASE_STATUS_CLOSED, trac_Constants.CASE_ORIGIN_PHONE, EMAIL_TEST, NAME_TEST);
            c.ContactId = con.Id;
            cases.add(c);
        }

        Test.startTest();
        try {
            insert cases;
        } catch (Exception ex) {
            System.assert(ex!=null);
        }
        Test.stopTest();

        List<Case> rst = [SELECT Id, EntitlementId FROM Case];
        for (Case c : rst){
            system.assertEquals(getEntitlement().Id , c.EntitlementId,'Entitlement Id should be the same');
        }
    }

    private static Account getAccount() {
        return [SELECT Id, Name  FROM Account LIMIT 1];
    }

    private static Contract getContract() {
        return [SELECT Id FROM Contract LIMIT 1];
    }

    private static Entitlement getEntitlement() {
        return [SELECT Id FROM Entitlement LIMIT 1];
    }
}