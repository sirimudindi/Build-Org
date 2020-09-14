/**
 * Tests for the QueueAccountOwner batch class
 *
 * @group Account Alignment Trigger
 *
 * @author Alex Kong, Traction on Demand
 * @date 2018-12-21
 * @modifiedBy Jonatas Barbosa, Traction on Demand
 * @modifiedDate 2020-01-20
 */
@IsTest
private class trac_QueueAccountOwnerBatchTest {
    private static List<Account> accounts = new List<Account>();
    private static List<Domain__c> domains = new List<Domain__c>();
    private static List<Queue_Owner_Change__c> queues = new List<Queue_Owner_Change__c>();
    private static User standardUser1;
    private static Id currentUserId = UserInfo.getUserId();

    private static void setupData() {
        // create user
        String orgId = UserInfo.getOrganizationId();
        standardUser1 = trac_TestUtils.createUser('user1@testtesttest.'+orgId+'.com', 'user1', 'Testy', 'Tester1');

        // create account data
        accounts.add( trac_TestUtils.createAccount() );
        accounts.add( trac_TestUtils.createAccount() );
        accounts[0].Name = 'Test Account 0';
        accounts[0].OwnerId = standardUser1.Id;
        accounts[1].Name = 'Test Account 1';
        accounts[1].OwnerId = standardUser1.Id;
        insert accounts;

        // create domain data
        domains.add( trac_TestUtils.createDomain('testtesttest.com', standardUser1.id) );
        domains.add( trac_TestUtils.createDomain('toasttoasttoast.com', standardUser1.id) );
        domains.add( trac_TestUtils.createDomain('breadbreadbread.com', standardUser1.id) );
        domains.add( trac_TestUtils.createDomain('testtesttest2.com', standardUser1.id) );
        domains.add( trac_TestUtils.createDomain('toasttoasttoast2.com', standardUser1.id) );
        domains.add( trac_TestUtils.createDomain('breadbreadbread2.com', standardUser1.id) );
        domains[0].Account__c = accounts[0].Id;
        domains[1].Account__c = accounts[0].Id;
        domains[2].Account__c = accounts[0].Id;
        domains[3].Account__c = accounts[1].Id;
        domains[4].Account__c = accounts[1].Id;
        domains[5].Account__c = accounts[1].Id;
        insert domains;
    }

    @IsTest
    static void testBatch() {
        setupData();

        Test.startTest();

        // change account owner to currentUserId
        accounts[0].OwnerId = currentUserId;
        accounts[1].OwnerId = currentUserId;
        update accounts;

        Test.stopTest();

        // domains should now have a new owner
        List<Domain__c> qryDomains = [SELECT Id, OwnerId FROM Domain__c WHERE Id IN :domains];
        for (Domain__c dom : qryDomains) {
            if (trac_KillSwitchUtils.isDisabled('trac_AccountSyncOwner_queueAccountOwnerChange')) {
                System.assertNotEquals(currentUserId, dom.OwnerId); // because of killswitch
            } else {
                System.assertEquals(currentUserId, dom.OwnerId);
            }
        }
    }

    @IsTest
    static void testBatchExcuteEmptyAccountId() {
        setupData();
        List<Queue_Owner_Change__c> retQueues = createQueueOwnerChangesBlankSourceId(accounts,currentUserId);
        insert retQueues;
        trac_QueueAccountOwnerBatch bc = new trac_QueueAccountOwnerBatch();

        Test.startTest();
        Database.executeBatch(bc, 200);
        Test.stopTest();

        List<Queue_Owner_Change__c> queues = [SELECT Id, Source_Id__c FROM Queue_Owner_Change__c];
        for (Queue_Owner_Change__c q : queues){
            System.assertEquals(null, q.Source_Id__c, 'source id should be null');
        }
    }

    @IsTest
    static void testBatchDomainEmpty() {
        setupData();
        delete domains;
        List<Queue_Owner_Change__c> retQueues = createQueueOwnerChanges(accounts,currentUserId);
        insert retQueues;

        trac_QueueAccountOwnerBatch bc = new trac_QueueAccountOwnerBatch();
        Test.startTest();
        Database.executeBatch(bc, 200);
        Test.stopTest();
        List<Domain__c> expectedDomains = [SELECT Id FROM Domain__c];
        System.assertEquals(0, expectedDomains.size(), 'expectedDomains size should be 0');
    }

    private static List<Queue_Owner_Change__c> createQueueOwnerChanges(List<Account> accounts, Id newOwnerId) {
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

    private static List<Queue_Owner_Change__c> createQueueOwnerChangesBlankSourceId(List<Account> accounts, Id newOwnerId) {
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
}