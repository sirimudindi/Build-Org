/**
 * Created by akong on 1/4/2019.
 */
@IsTest
private class trac_QueueDomainLeadOwnerBatchTest {
    private static List<Account> accounts = new List<Account>();
    private static List<Domain__c> domains = new List<Domain__c>();
    private static List<Contact> contacts = new List<Contact>();
    private static List<Lead> leads = new List<Lead>();
    private static List<Queue_Owner_Change__c> queues = new List<Queue_Owner_Change__c>();
    private static User standardUser1;
    private static User adminUser;
    private static Id currentUserId = UserInfo.getUserId();

    private static void setupData() {
        // create user
        String orgId = UserInfo.getOrganizationId();
        standardUser1 = trac_TestUtils.createUser('user1@testtesttest.'+orgId+'.com', 'user1', 'Testy', 'Tester1');
        adminUser = trac_TestUtils.createUser('admin1@testtesttest.'+orgId+'.com', 'admin1', 'Ad', 'Admin', 'System Administrator');

        //insert records as SysAdmin to avoid MIXED_DML_OPERATION
        System.runAs(adminUser) {
            // create account data
            accounts.add(trac_TestUtils.createAccount());
            accounts[0].Name = 'Test Account 0';
            accounts[0].OwnerId = standardUser1.Id;
            insert accounts;

            // create domain data
            domains.add(trac_TestUtils.createDomain('testtesttest.com', standardUser1.id));
            domains.add(trac_TestUtils.createDomain('toasttoasttoast.com', standardUser1.id));
            domains.add(trac_TestUtils.createDomain('breadbreadbread.com', standardUser1.id));
            domains.add(trac_TestUtils.createDomain('testtesttest2.com', standardUser1.id));
            domains.add(trac_TestUtils.createDomain('toasttoasttoast2.com', standardUser1.id));
            domains.add(trac_TestUtils.createDomain('breadbreadbread2.com', standardUser1.id));
            for (Domain__c d : domains){
                d.Account__c = accounts[0].Id;
            }
            insert domains;
        }
    }

    private static void setupLeadData() {
        // create lead data
        leads.add( trac_TestUtils.createLead('tester01', 'testco01', domains[0].Name) );
        leads.add( trac_TestUtils.createLead('tester02', 'testco02', domains[0].Name) );
        leads.add( trac_TestUtils.createLead('tester03', 'testco03', domains[1].Name) );
        leads.add( trac_TestUtils.createLead('tester04', 'testco04', domains[1].Name) );
        leads.add( trac_TestUtils.createLead('tester05', 'testco05', domains[2].Name) );
        leads.add( trac_TestUtils.createLead('tester06', 'testco06', domains[2].Name) );
        leads.add( trac_TestUtils.createLead('tester07', 'testco07', domains[3].Name) );
        leads.add( trac_TestUtils.createLead('tester08', 'testco08', domains[3].Name) );
        leads.add( trac_TestUtils.createLead('tester09', 'testco09', domains[4].Name) );
        leads.add( trac_TestUtils.createLead('tester10', 'testco10', domains[4].Name) );
        leads.add( trac_TestUtils.createLead('tester11', 'testco11', domains[5].Name) );
        leads.add( trac_TestUtils.createLead('tester12', 'testco12', domains[5].Name) );
        for (Lead l : leads) {
            l.OwnerId = standardUser1.Id;
        }
        insert leads;
    }

    @IsTest
    static void testDomainLeadBatch() {
        setupData();
        setupLeadData();

        Test.startTest();

        // change account owner to currentUserId
        accounts[0].OwnerId = currentUserId;

        //update account record as SysAdmin to avoid MIXED_DML_OPERATION
        System.runAs(adminUser) {
            update accounts[0];
        }

        /*// there should now be account-type qoc records
        List<Queue_Owner_Change__c> qocs = [SELECT Id, Name, Source_Type__c, Source_Id__c, Target_Type__c, New_Owner_Id__c FROM Queue_Owner_Change__c ORDER BY CreatedDate ASC];
        System.debug('qocs: ' + qocs);*/

        Test.stopTest();

        /*qocs = [SELECT Id, Name, Source_Type__c, Source_Id__c, Target_Type__c, New_Owner_Id__c FROM Queue_Owner_Change__c ORDER BY CreatedDate ASC];
        System.debug('qocs 2: ' + qocs);*/

        /*List<AsyncApexJob> jobs = [SELECT Id, ApexClass.Name, Status, Createddate FROM AsyncApexJob ORDER BY CreatedDate DESC];
        System.debug('jobs: ' + jobs);*/

        // all domains should now be owned by currentUserId
        /*List<Domain__c> qryDoms = [SELECT Id, OwnerId FROM Domain__c WHERE Id IN :domains];
        for (Domain__c d : qryDoms) {
            if (trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_queueDomainOwnerChange')) {
                System.assertNotEquals(currentUserId, d.OwnerId); // because of killswitch
            } else {
                System.assertEquals(currentUserId, d.OwnerId);
            }
        }*/

//        // all leads should now be owned by currentUserId
//        List<Lead> qryLeads = [SELECT Id, OwnerId FROM Lead WHERE Id IN :leads];
//        for (Lead l : qryLeads) {
//            if (trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_syncDomainAccountOwner') ||
//                    trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_queueDomainOwnerChange') ||
//                    trac_KillSwitchUtils.isDisabled('trac_LeadSyncOwner_syncLeadDomainOwner')) {
//                System.assertNotEquals(currentUserId, l.OwnerId); // because of killswitch
//            } else {
//                System.assertEquals(currentUserId, l.OwnerId);
//            }
//        }

        // all queue records with source type domain + target type lead should be deleted
        List<Queue_Owner_Change__c> remainingQueues = [SELECT Id, Source_Type__c, Target_Type__c
        FROM Queue_Owner_Change__c
        WHERE Source_Type__c = :trac_Constants.QOC_SOURCE_TYPE_DOMAIN
        AND Target_Type__c = :trac_Constants.QOC_TARGET_TYPE_LEAD];
        System.assert(remainingQueues.isEmpty(), 'All domain-to-lead queue records should have been deleted, but were not!');
    }

    @IsTest
    static void testDomainContactIndicator() {
        setupData();
        setupLeadData();

        Test.startTest();
        // change account owner to currentUserId
        accounts[0].OwnerId = currentUserId;
        update accounts[0];
        Test.stopTest();

        // all contacts should now be owned by currentUserId
        List<Domain__c> qryDomain = [SELECT Id, OwnerId, SyncOwnerLeadIndicatorJob__c, Account__r.SyncOwnerIndicatorJob__c, Account__r.SyncOwnerQueueJob__c FROM Domain__c];
        for (Domain__c dom : qryDomain) {
            System.assertEquals(dom.Account__r.SyncOwnerIndicatorJob__c, false, 'domain Account SyncOwnerIndicatorJob should be false');
            System.assertEquals(dom.Account__r.SyncOwnerQueueJob__c, false, 'domain Account SyncOwnerQueueJob__c should be false');
            System.assertEquals(dom.SyncOwnerLeadIndicatorJob__c, false, 'domain SyncOwnerLeadIndicatorJob__c should be false');
        }
    }

    @IsTest
    static void testTrac_QueueDomainLeadOwnerBatchNotEmpty() {
        setupData();
        setupLeadData();
        List<Queue_Owner_Change__c> retQueues = createQueueOwnerChanges(domains,currentUserId);
        insert retQueues;

        Test.startTest();
        // change account owner to currentUserId
        accounts[0].OwnerId = currentUserId;
        update accounts[0];
        Test.stopTest();

        // all contacts should now be owned by currentUserId
        List<Domain__c> qryDomain = [SELECT Id, OwnerId, SyncOwnerLeadIndicatorJob__c, Account__r.SyncOwnerIndicatorJob__c, Account__r.SyncOwnerQueueJob__c FROM Domain__c];
        for (Domain__c dom : qryDomain) {
            System.assertEquals(dom.Account__r.SyncOwnerIndicatorJob__c, false, 'domain Account SyncOwnerIndicatorJob should be false');
            System.assertEquals(dom.Account__r.SyncOwnerQueueJob__c, false, 'domain Account SyncOwnerQueueJob__c should be false');
            System.assertEquals(dom.SyncOwnerLeadIndicatorJob__c, false, 'domain SyncOwnerLeadIndicatorJob__c should be false');
        }
    }

    @IsTest
    static void trac_QueueAccountOwnerBatchIdBlank() {
        setupData();
        setupLeadData();
        List<Queue_Owner_Change__c> retQueues = createQueueOwnerChangesEmpty(domains,currentUserId);
        insert retQueues;

        Test.startTest();
        // change account owner to currentUserId
        accounts[0].OwnerId = currentUserId;
        update accounts[0];
        Test.stopTest();

        // all contacts should now be owned by currentUserId
        List<Domain__c> qryDomain = [SELECT Id, OwnerId, SyncOwnerLeadIndicatorJob__c, Account__r.SyncOwnerIndicatorJob__c, Account__r.SyncOwnerQueueJob__c FROM Domain__c];
        for (Domain__c dom : qryDomain) {
            System.assertEquals(dom.Account__r.SyncOwnerIndicatorJob__c, false, 'domain Account SyncOwnerIndicatorJob should be false');
            System.assertEquals(dom.Account__r.SyncOwnerQueueJob__c, false, 'domain Account SyncOwnerQueueJob__c should be false');
            System.assertEquals(dom.SyncOwnerLeadIndicatorJob__c, false, 'domain SyncOwnerLeadIndicatorJob__c should be false');
        }
    }

    private static List<Queue_Owner_Change__c> createQueueOwnerChanges(List<Domain__c> domains, Id newOwnerId) {
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

    private static List<Queue_Owner_Change__c> createQueueOwnerChangesEmpty(List<Domain__c> domains, Id newOwnerId) {
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
}