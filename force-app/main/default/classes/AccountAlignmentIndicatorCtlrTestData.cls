/**
 * Author:
 * Jonatas Barbosa, Traction on Demand
 *
 * Description:
 * Test data for AccountAlignmentIndicatorCtlrTest.
 *
 * Revision History:
 * Jun/24/2020 - Jonatas Barbosa, Traction on Demand - File created
 */
@IsTest
@TestVisible
private class AccountAlignmentIndicatorCtlrTestData {

    @TestVisible
    private static Account getTestAccount() {
        Account testAccount = new Account(Name = 'Example Account');
        insert testAccount;

        return testAccount;
    }

    @TestVisible
    private static Domain__c getTestDomain(String testAccountId) {
        Domain__c testDomain = new Domain__c(
                Account__c = testAccountId,
                Domain_Name_URL__c = 'example.com'
        );
        insert testDomain;

        return testDomain;
    }

    @TestVisible
    private static void insertTestLead(String testDomainId) {
        Lead testLead = new Lead(
                Domain_Lookup__c = testDomainId,
                LastName = 'Example Lead',
                Company = 'Example Company'
        );

        insert testLead;
    }

    @TestVisible
    private static void insertQueueRecords(String testAccountId) {
        List<Queue_Owner_Change__c> queueOwnerChanges = new List<Queue_Owner_Change__c>();

        Queue_Owner_Change__c testQueueOwnerChange = new Queue_Owner_Change__c(
                Source_Type__c = 'Account',
                Target_Type__c = 'Domain',
                New_Owner_Id__c = UserInfo.getUserId(),
                Source_Id__c = testAccountId
        );
        queueOwnerChanges.add(testQueueOwnerChange);

        Queue_Owner_Change__c anotherTestQueueOwnerChange = new Queue_Owner_Change__c(
                Source_Type__c = 'Account',
                Target_Type__c = 'Lead',
                New_Owner_Id__c = UserInfo.getUserId(),
                Source_Id__c = testAccountId
        );
        queueOwnerChanges.add(anotherTestQueueOwnerChange);

        insert queueOwnerChanges;
    }
}