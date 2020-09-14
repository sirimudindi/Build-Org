/**
 * @author  Alex Kong, Traction on Demand
 * @date    2018-12-04
 */
@IsTest
private class trac_DomainSyncOwnerTest {
    private static User standardUser1;
    private static User standardUser2;
    private static List<Account> accounts = new List<Account>();
    private static List<Domain__c> domains = new List<Domain__c>();
    private static Id currentUserId;

    private static void setupData() {
        // create user
        currentUserId = UserInfo.getUserId();
        String orgId = UserInfo.getOrganizationId();
        standardUser1 = trac_TestUtils.createUser('user1@testtesttest.'+orgId+'.com', 'user1', 'Testy', 'Tester1');
        standardUser2 = trac_TestUtils.createUser('user2@testtesttest.'+orgId+'.com', 'user2', 'Testy', 'Tester2');

        // create account data
        accounts.add( trac_TestUtils.createAccount());
        accounts[0].Name = 'Test Account 1';
        accounts[0].OwnerId = currentUserId;
        accounts.add( trac_TestUtils.createAccount());
        accounts[1].Name = 'Test Account 2';
        accounts[1].OwnerId = currentUserId;
        insert accounts;

        // create domain data
        domains.add( trac_TestUtils.createDomain('testtesttest.com', standardUser1.Id));
        domains.add( trac_TestUtils.createDomain('toasttoasttoast.com', standardUser2.Id));
    }

    @IsTest
    static void testSyncDomainAccountOwnerOnInsert() {
        setupData();

        Test.startTest();

        domains[0].Account__c = accounts[0].Id;
        domains[1].Account__c = accounts[1].Id;
        insert domains;

        Test.stopTest();

        domains = [SELECT Id, Account__r.OwnerId, OwnerId FROM Domain__c];

        for (Domain__c dm : domains) {
            if (!trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_syncDomainAccountOwner') || Test.isRunningTest()) {
                System.assertEquals(dm.Account__r.OwnerId, dm.OwnerId);
                System.assertEquals(currentUserId, dm.OwnerId);
            } else {
                System.assertNotEquals(dm.Account__r.OwnerId, dm.OwnerId);
            }
        }
    }

    @IsTest
    static void testSyncDomainAccountOwnerOnUpdate() {
        setupData();

        domains[0].OwnerId = standardUser1.Id;
        domains[1].OwnerId = standardUser2.Id;
        insert domains;

        Test.startTest();

        domains[0].Account__c = accounts[0].Id;
        domains[1].Account__c = accounts[1].Id;
        update domains;

        Test.stopTest();

        domains = [SELECT Id, Account__r.OwnerId, OwnerId FROM Domain__c];

        for (Domain__c dm : domains) {
            if (!trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_syncDomainAccountOwner') || Test.isRunningTest()) {
                System.assertEquals(dm.Account__r.OwnerId, dm.OwnerId);
                System.assertEquals(currentUserId, dm.OwnerId);
            } else {
                System.assertNotEquals(dm.Account__r.OwnerId, dm.OwnerId);
            }
        }
    }

    @isTest
    static void testQueueDomainOwnerChange() {
        setupData();

        domains[0].OwnerId = standardUser1.Id;
        domains[1].OwnerId = standardUser1.Id;
        insert domains;

        Test.startTest();

        domains[0].OwnerId = currentUserId;
        domains[1].OwnerId = currentUserId;
        update domains;

        List<Queue_Owner_Change__c> queues = [SELECT Id, Name, OwnerId, New_Owner_Id__c
        FROM Queue_Owner_Change__c
        WHERE Source_Type__c = :trac_Constants.QOC_SOURCE_TYPE_DOMAIN];

        Test.stopTest();

        if (!trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_queueDomainOwnerChange') || Test.isRunningTest()) {
            System.assertEquals(4, queues.size()); // will be two records (1 contact, 1 lead) per domain
            System.assertEquals(String.valueOf(currentUserId), queues[0].New_Owner_Id__c);
            System.assertEquals(String.valueOf(currentUserId), queues[1].New_Owner_Id__c);
        } else {
            System.assertEquals(0, queues.size()); // will be zero records because of killswitch
        }
    }

    @IsTest
    static void testBlockedOwnerIdChange() {
        setupData();
        domains[0].Account__c = accounts[0].Id;
        insert domains;

        String orgId = UserInfo.getOrganizationId();
        User adminUser2 = trac_TestUtils.createUser('admin2@testtesttest.'+orgId+'.com', 'admn2', 'TestAdmin', 'TesterAdmin2', 'System Administrator');

        // domains[0] owner should be currentUserId (same as account owner)
        Id domainId = domains[0].Id;
        List<Domain__c> dms = [SELECT Id, OwnerId FROM Domain__c WHERE Id = :domainId];
        if (!trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_syncDomainAccountOwner') || Test.isRunningTest()) {
            System.assertEquals(currentUserId, dms[0].OwnerId);
        } else {
            System.assertEquals(standardUser1.Id, dms[0].OwnerId); // because of killswitch
        }

        Test.startTest();

        // force change the owner ID
        domains[0].OwnerId = adminUser2.Id;
        update domains[0];

        Test.stopTest();

        // domains[0].OwnerId should still be currentUserId
        dms = [SELECT Id, OwnerId FROM Domain__c WHERE Id = :domainId];
        if (!trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_syncDomainAccountOwner') || Test.isRunningTest()) {
            System.assertEquals(currentUserId, dms[0].OwnerId);
        } else {
            System.assertEquals(domains[0].OwnerId, dms[0].OwnerId); // because of killswitch
        }
    }

    @IsTest
    static void testStrategicAccountOnInsert() {
        setupData();

        // change account type
        accounts[0].Territory__c = 'W - Los Angeles - 1'; // that should make the account type 'Strategic Account'
        accounts[0].Business_Development_Rep__c = standardUser2.Id;
        update accounts[0];

        accounts = [SELECT Id, Account_Type__c, Business_Development_Rep__c, OwnerId FROM Account WHERE Id = :accounts[0].Id];
        System.assertEquals(trac_Constants.ACCOUNT_TYPE_STRATEGIC_ACCOUNT, accounts[0].Account_Type__c);

        Test.startTest();
        domains[0].Account__c = accounts[0].Id;
        insert domains;
        Test.stopTest();

        List<Domain__c> dms = [SELECT Id, OwnerId FROM Domain__c WHERE Id = :domains[0].Id];
        if (!trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_syncDomainAccountOwner') || Test.isRunningTest()) {
            System.assertNotEquals(accounts[0].OwnerId, dms[0].OwnerId);
            System.assertEquals(accounts[0].Business_Development_Rep__c, dms[0].OwnerId);
        } else {
            System.assertEquals(domains[0].OwnerId, dms[0].OwnerId);
        }
    }

    @IsTest
    static void testStrategicAccountOnUpdate() {
        setupData();
        domains[0].OwnerId = standardUser1.Id;
        insert domains;

        List<Domain__c> dms = [SELECT Id, OwnerId FROM Domain__c WHERE Id = :domains[0].Id];
        System.assertEquals(standardUser1.Id, dms[0].OwnerId);

        // change account type
        accounts[0].Territory__c = trac_Constants.ACCOUNT_TERRITORY_SEFL; // that should make the account type 'Strategic Account'
        accounts[0].Business_Development_Rep__c = currentUserId;
        update accounts[0];

        accounts = [SELECT Id, Account_Type__c, Business_Development_Rep__c, OwnerId FROM Account WHERE Id = :accounts[0].Id];
        System.assertEquals(trac_Constants.ACCOUNT_TYPE_STRATEGIC_ACCOUNT, accounts[0].Account_Type__c);

        Test.startTest();
        domains[0].Account__c = accounts[0].Id;
        update domains;
        Test.stopTest();

        dms = [SELECT Id, OwnerId FROM Domain__c WHERE Id = :domains[0].Id];
        if (!trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_syncDomainAccountOwner') || Test.isRunningTest()) {
            System.assertEquals(accounts[0].Business_Development_Rep__c, dms[0].OwnerId);
        } else {
            System.assertEquals(domains[0].OwnerId, dms[0].OwnerId);
        }
    }
}