/**
 * Created by akong on 11/23/2018.
 */

@IsTest
private class trac_ContactSyncOwnerTest {
    private static Id currentUserId = UserInfo.getUserId();
    private static User standardUser1;
    private static User standardUser2;
    private static List<Account> accounts = new List<Account>();
    private static List<Contact> contacts = new List<Contact>();
    private static List<Domain__c> domains = new List<Domain__c>();

    private static void setupData() {
        // create user
        String orgId = UserInfo.getOrganizationId();
        standardUser1 = trac_TestUtils.createUser('user1@testtesttest.'+orgId+'.com', 'user1', 'Testy', 'Tester1');
        standardUser2 = trac_TestUtils.createUser('user2@testtesttest.'+orgId+'.com', 'user2', 'Testy', 'Tester2');

        // create account data
        accounts.add( trac_TestUtils.createAccount() );
        accounts[0].OwnerId = standardUser1.Id;
        accounts.add( trac_TestUtils.createAccount() );
        accounts[1].OwnerId = standardUser2.Id;
        insert accounts;

        // create domain data
        domains.add( trac_TestUtils.createDomain('testtesttest.com', standardUser1.id) );
        domains.add( trac_TestUtils.createDomain('toasttoasttoast.com', standardUser2.id) );
        insert domains;

        // create contact data
        contacts.add( trac_TestUtils.createContact('Tester1', 'test1@testtesttest.com', accounts[0]) );
        contacts.add( trac_TestUtils.createContact('Tester2', 'test2@testtesttest.com', accounts[0]) );
        contacts.add( trac_TestUtils.createContact('Tester3', 'test3@toasttoasttoast.com', accounts[1]) );
    }

    @IsTest
    static void testSyncContactDomainOwnerOnInsert() {
        setupData();
        contacts[0].Domain_Lookup__c = domains[0].Id;
        contacts[1].Domain_Lookup__c = domains[0].Id;
        contacts[2].Domain_Lookup__c = domains[1].Id;

        Test.startTest();

        insert contacts;

        Test.stopTest();

        contacts = [SELECT Id, Domain_Lookup__c, OwnerId FROM Contact];

        Map<Id,Domain__c> domainMap = new Map<Id,Domain__c>(domains);

        for (Contact c : contacts) {
            Domain__c dom = domainMap.get(c.Domain_Lookup__c);
            if (!trac_KillSwitchUtils.isDisabled('trac_ContactSyncOwner_syncContactDomainOwner')) {
                System.assertEquals(dom.OwnerId, c.OwnerId);
            } else {
                System.assertNotEquals(dom.OwnerId, c.OwnerId);
            }
        }
    }

    @IsTest
    static void testSyncContactDomainOwnerOnUpdate() {
        setupData();

        domains.add( trac_TestUtils.createDomain('foofoofoo.com', standardUser1.id) );
        domains.add( trac_TestUtils.createDomain('barbarbar.com', standardUser2.id) );
        upsert domains;

        contacts[0].Email = 'test1@foofoofoo.com';
        contacts[1].Email = 'test2@foofoofoo.com';
        contacts[2].Email = 'test3@barbarbar.com';
        insert contacts;

        Test.startTest();

        contacts[0].Email = 'test1@testtesttest.com';
        contacts[1].Email = 'test2@testtesttest.com';
        contacts[2].Email = 'test3@toasttoasttoast.com';
        contacts[0].Domain_Lookup__c = domains[0].Id;
        contacts[1].Domain_Lookup__c = domains[0].Id;
        contacts[2].Domain_Lookup__c = domains[1].Id;
        update contacts;

        Test.stopTest();

        contacts = [SELECT Id, Domain_Lookup__c, OwnerId FROM Contact];

        Map<Id,Domain__c> domainMap = new Map<Id,Domain__c>(domains);

        for (Contact c : contacts) {
            Domain__c dom = domainMap.get(c.Domain_Lookup__c);
            if (!trac_KillSwitchUtils.isDisabled('trac_ContactSyncOwner_syncContactDomainOwner')) {
                System.assertEquals(dom.OwnerId, c.OwnerId);
            } else {
                System.assertNotEquals(dom.OwnerId, c.OwnerId);
            }
        }
    }

    @IsTest
    static void testBlockedOwnerIdChange() {
        setupData();
        contacts[0].Domain_Lookup__c = domains[0].Id;
        insert contacts[0];

        // contacts[0] owner should be standardUser1
        Contact c = [SELECT Id, OwnerId FROM Contact WHERE Id = :contacts[0].Id];
        if (!trac_KillSwitchUtils.isDisabled('trac_ContactSyncOwner_syncContactDomainOwner')) {
            System.assertEquals(standardUser1.Id, c.OwnerId);
        } else {
            System.assertEquals(currentUserId, c.OwnerId);  // because of killswitch
        }

        Test.startTest();

        // force change the owner ID
        contacts[0].OwnerId = standardUser2.Id;
        update contacts[0];

        Test.stopTest();
        
        // contacts[0].OwnerId should still be standardUser1
        c = [SELECT Id, OwnerId FROM Contact WHERE Id = :contacts[0].Id];
        if (!trac_KillSwitchUtils.isDisabled('trac_ContactSyncOwner_syncContactDomainOwner')) {
            System.assertEquals(standardUser1.Id, c.OwnerId);
        } else {
            System.assertEquals(standardUser2.Id, c.OwnerId);  // because of killswitch
        }
    }
}