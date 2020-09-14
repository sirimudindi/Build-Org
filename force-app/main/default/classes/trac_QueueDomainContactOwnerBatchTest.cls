/**
 * Created by akong on 1/4/2019.
 */
@IsTest
private class trac_QueueDomainContactOwnerBatchTest {
    private static List<Account> accounts = new List<Account>();
    private static List<Domain__c> domains = new List<Domain__c>();
    private static List<Contact> contacts = new List<Contact>();
    private static User standardUser1;
    private static Id currentUserId = UserInfo.getUserId();

    private static void setupData() {
        // create user
        String orgId = UserInfo.getOrganizationId();
        standardUser1 = trac_TestUtils.createUser('user1@testtesttest.'+orgId+'.com', 'user1', 'Testy', 'Tester1');

        // create account data
        accounts.add( trac_TestUtils.createAccount());
        accounts[0].Name = 'Test Account 0';
        accounts[0].OwnerId = standardUser1.Id;
        insert accounts;

        // create domain data
        domains.add( trac_TestUtils.createDomain('testtesttest.com', standardUser1.id));
        domains.add( trac_TestUtils.createDomain('toasttoasttoast.com', standardUser1.id));
        domains.add( trac_TestUtils.createDomain('breadbreadbread.com', standardUser1.id));
        domains.add( trac_TestUtils.createDomain('testtesttest2.com', standardUser1.id));
        domains.add( trac_TestUtils.createDomain('toasttoasttoast2.com', standardUser1.id));
        domains.add( trac_TestUtils.createDomain('breadbreadbread2.com', standardUser1.id));
        domains[0].Account__c = accounts[0].Id;
        domains[1].Account__c = accounts[0].Id;
        domains[2].Account__c = accounts[0].Id;
        domains[3].Account__c = accounts[0].Id;
        domains[4].Account__c = accounts[0].Id;
        domains[5].Account__c = accounts[0].Id;
        insert domains;
    }

    private static void setupContactData() {
        // create contact data
        contacts.add( trac_TestUtils.createContact('tester', 'testy01@' + domains[0].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy02@' + domains[0].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy03@' + domains[1].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy04@' + domains[1].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy05@' + domains[2].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy06@' + domains[2].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy07@' + domains[3].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy08@' + domains[3].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy09@' + domains[4].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy10@' + domains[4].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy11@' + domains[5].Name, accounts[0]));
        contacts.add( trac_TestUtils.createContact('tester', 'testy12@' + domains[5].Name, accounts[0]));
        for (Contact c : contacts) {
            c.OwnerId = standardUser1.Id;
        }
        insert contacts;
    }

    @IsTest
    static void testDomainContactBatch() {
        setupData();
        setupContactData();

        Test.startTest();

        // change account owner to currentUserId
        accounts[0].OwnerId = currentUserId;
        update accounts[0];

        Test.stopTest();

        // all contacts should now be owned by currentUserId
        List<Contact> qryContacts = [SELECT Id, OwnerId FROM Contact];
        for (Contact c : qryContacts) {
            if (trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_queueDomainOwnerChange')) {
                System.assertNotEquals(currentUserId, c.OwnerId); // because of killswitch
            } else {
                System.assertEquals(currentUserId, c.OwnerId);
            }
        }

        // all queue records with source type domain + target type contact should be deleted
        List<Queue_Owner_Change__c> remainingQueues = [SELECT Id, Source_Type__c, Target_Type__c
                                                        FROM Queue_Owner_Change__c
                                                        WHERE Source_Type__c = :trac_Constants.QOC_SOURCE_TYPE_DOMAIN
                                                        AND Target_Type__c = :trac_Constants.QOC_TARGET_TYPE_CONTACT];
        System.assert(remainingQueues.isEmpty(), 'All domain-to-contact queue records should have been deleted, but were not!');
    }

    @IsTest
    static void testDomainContactIndicator() {
        setupData();
        setupContactData();

        Test.startTest();

        // change account owner to currentUserId
        accounts[0].OwnerId = currentUserId;
        update accounts[0];

        Test.stopTest();

        // all contacts should now be owned by currentUserId
        List<Domain__c> qryDomain = [SELECT Id, OwnerId, SyncOwnerContactIndicatorJob__c, Account__r.SyncOwnerQueueJob__c ,Account__r.SyncOwnerIndicatorJob__c FROM Domain__c];

        for (Domain__c dom : qryDomain) {
            System.assertEquals(dom.Account__r.SyncOwnerQueueJob__c, false);
            System.assertEquals(dom.Account__r.SyncOwnerIndicatorJob__c, false);
            System.assertEquals(dom.SyncOwnerContactIndicatorJob__c, false);
        }
    }
}