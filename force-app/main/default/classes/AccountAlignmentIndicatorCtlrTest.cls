/**
 * Author:
 * Jonatas Barbosa, Traction on Demand
 *
 * Description:
 * Test class for AccountAlignmentIndicatorCtlr.
 *
 * Revision History:
 * Jun/23/2020 - Jonatas Barbosa, Traction on Demand - File created
 */
@IsTest
private class AccountAlignmentIndicatorCtlrTest {

    @TestSetup
    private static void setup() {
        Account testAccount = AccountAlignmentIndicatorCtlrTestData.getTestAccount();
        Domain__c testDomain = AccountAlignmentIndicatorCtlrTestData.getTestDomain(testAccount.Id);

        AccountAlignmentIndicatorCtlrTestData.insertTestLead(testDomain.Id);
        AccountAlignmentIndicatorCtlrTestData.insertQueueRecords(testAccount.Id);
    }

    @IsTest
    private static void AccountAlignmentIndicatorCtlr_Lead() {
        Lead testLead = [ SELECT Id FROM Lead WHERE LastName = 'Example Lead' ];
        ApexPages.StandardController standardController = new ApexPages.StandardController(testLead);
        Exception resultException;

        Test.startTest();

        AccountAlignmentIndicatorCtlr accountAlignmentIndicatorCtlr;
        try {
            accountAlignmentIndicatorCtlr = new AccountAlignmentIndicatorCtlr(standardController);
        } catch (Exception e) {
            resultException = e;
        }

        Test.stopTest();

        System.assertEquals(null, resultException, 'The AccountAlignmentIndicatorCtlr class should not throw an Exception in this scenario.');
        System.assertEquals(true, accountAlignmentIndicatorCtlr.showMessage, 'The showMessage property should be true since there are Queue records related to the given Lead.');
    }

    @IsTest
    private static void AccountAlignmentIndicatorCtlr_Domain() {
        Domain__c testDomain = [ SELECT Id FROM Domain__c WHERE Domain_Name_URL__c = 'example.com' ];
        ApexPages.StandardController standardController = new ApexPages.StandardController(testDomain);
        Exception resultException;

        Test.startTest();

        AccountAlignmentIndicatorCtlr accountAlignmentIndicatorCtlr;
        try {
            accountAlignmentIndicatorCtlr = new AccountAlignmentIndicatorCtlr(standardController);
        } catch (Exception e) {
            resultException = e;
        }

        Test.stopTest();

        System.assertEquals(null, resultException, 'The AccountAlignmentIndicatorCtlr class should not throw an Exception in this scenario.');
        System.assertEquals(true, accountAlignmentIndicatorCtlr.showMessage, 'The showMessage property should be true since there are Queue records related to the given Domain.');
    }
}