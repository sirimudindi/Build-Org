@IsTest
private class trac_ConvertLicensedLeadsTest {

    @TestSetup
    private static void setup() {
        insertBatchSettings();
        insertTestData();
    }

    @IsTest
    private static void schedulableExecute() {
        Exception resultException;

        Test.startTest();

        try {
            trac_ConvertLicensedLeads convertLicensedLeads = new trac_ConvertLicensedLeads();
            convertLicensedLeads.execute(null);
        } catch(Exception e) {
            resultException = e;
        }

        Test.stopTest();

        System.assertEquals(null, resultException);
    }

    @IsTest
    private static void start() {
        Exception resultException;

        Test.startTest();

        try {
            trac_ConvertLicensedLeads convertLicensedLeads = new trac_ConvertLicensedLeads();
            convertLicensedLeads.start(null);
        } catch(Exception e) {
            resultException = e;
        }

        Test.stopTest();

        System.assertEquals(null, resultException);
    }

    @IsTest
    private static void batchableExecute() {
        Exception resultException;

        List<Lead> updatedLeads = getUpdatedLeads();

        Test.startTest();

        try {
            trac_ConvertLicensedLeads convertLicensedLeads = new trac_ConvertLicensedLeads();
            convertLicensedLeads.execute(null, updatedLeads);
        } catch(Exception e) {
            resultException = e;
        }

        Test.stopTest();

        System.assertEquals(null, resultException);
    }

    @IsTest
    private static void batchableExecute_testFlag() {
        Exception resultException;

        List<Lead> updatedLeads = getUpdatedLeads();

        Test.startTest();

        try {
            trac_ConvertLicensedLeads.testFlag = true;
            trac_ConvertLicensedLeads convertLicensedLeads = new trac_ConvertLicensedLeads();
            convertLicensedLeads.execute(null, updatedLeads);
        } catch(Exception e) {
            resultException = e;
        }

        Test.stopTest();

        System.assertEquals(null, resultException);
    }

    @IsTest
    private static void batchableExecute_updateCases() {
        Exception resultException;

        List<Lead> updatedLeads = getUpdatedLeads();

        Test.startTest();

        try {
            trac_ConvertLicensedLeads.caseTestFlag = true;
            trac_ConvertLicensedLeads convertLicensedLeads = new trac_ConvertLicensedLeads();
            convertLicensedLeads.execute(null, updatedLeads);
        } catch(Exception e) {
            resultException = e;
        }

        Test.stopTest();

        System.assertEquals(null, resultException);
    }

    private static void insertBatchSettings() {
        trac_Settings__c batchSettings = new trac_Settings__c(
                Lead_Conversion_Batch_Size__c = 10,
                Lead_Conversion_Error_Email__c = 'mail@example.com'
        );
        insert batchSettings;
    }

    private static void insertTestData() {
        Account testAccount = new Account(
                Name = trac_Constants.THIS_MONTH_ACCOUNT_NAME
        );
        insert testAccount;

        Entitlement testEntitlement = new Entitlement(
                Name = 'Standard User Student',
                AccountId = testAccount.Id
        );
        insert testEntitlement;

        Domain__c testDomain = new Domain__c(
                Domain_Name_URL__c = 'example.com',
                Account__c = testAccount.Id
        );
        insert testDomain;

        Contract testContract = new Contract(
                AccountId = testAccount.Id
        );
        insert testContract;

        List<Lead> testLeads = new List<Lead>();
        for (Integer i = 0; i < 10; i++) {
            testLeads.add(new Lead(
                    Plan__c = testContract.Id,
                    LastName = 'Name ' + i,
                    Company = 'Example Company',
                    Domain_Lookup__c = testDomain.Id
            ));
        }
        insert testLeads;

        List<Case> testCases = new List<Case>();
        for (Integer j = 0; j < 10; j++) {
            testCases.add(new Case(
                    Lead__c = testLeads[j].Id
            ));
        }
        insert testCases;
    }

    private static List<Lead> getUpdatedLeads() {
        List<Lead> updatedLeads = [ SELECT Id, FirstName, LastName, Domain_Lookup__r.Account__c, Domain_Lookup__r.Account__r.OwnerId FROM Lead ];

        return updatedLeads;
    }
}