/**
 * @description     Tests for the AccountSyncOwner class
 * @author          Alex Kong, Traction on Demand.
 * @modifiedBy      Jonatas Barbosa, Traction on Demand.
 * @modifiedDate    2020-03-07
 */
@IsTest
private class trac_AccountSyncOwnerTest {
    private static User standardUser1;
    private static User standardUser2;
    private static List<Account> accounts = new List<Account>();
    private static Id currentUserId;

    private static void setupData() {
        // create user
        currentUserId = UserInfo.getUserId();
        String orgId = UserInfo.getOrganizationId();
        standardUser1 = trac_TestUtils.createUser('user1@testtesttest.'+orgId+'.com', 'user1', 'Testy', 'Tester1');
        standardUser2 = trac_TestUtils.createUser('user2@testtesttest.'+orgId+'.com', 'user2', 'Testy', 'Tester2');

        // create account data
        accounts.add( trac_TestUtils.createAccount() );
        accounts[0].Name = 'Test Account 1';
        accounts[0].OwnerId = standardUser1.Id;
        accounts.add( trac_TestUtils.createAccount() );
        accounts[1].Name = 'Test Account 2';
        accounts[1].OwnerId = standardUser1.Id;
    }

    @IsTest
    static void testAccountOwnerChange() {
        setupData();
        insert accounts;

        Test.startTest();

        accounts[0].OwnerId = currentUserId;
        accounts[1].OwnerId = currentUserId;
        update accounts;

        List<Queue_Owner_Change__c> queues = [
                SELECT Id, Name, OwnerId, New_Owner_Id__c
                FROM Queue_Owner_Change__c
                WHERE Source_Type__c = :trac_Constants.QOC_SOURCE_TYPE_ACCOUNT
        ];

        Test.stopTest();

        if (trac_KillSwitchUtils.isDisabled('trac_AccountSyncOwner_queueAccountOwnerChange')) {
            System.assertEquals(0, queues.size(), 'The trigger is disabled - no Account records will be created');
        } else {
            System.assertEquals(6, queues.size(), 'Each Account should create three Queue records - Domain, Lead and Contact');
            System.assertEquals(String.valueOf(currentUserId), queues[0].New_Owner_Id__c, 'Queue records should contain the new Owner Id');
            System.assertEquals(String.valueOf(currentUserId), queues[1].New_Owner_Id__c, 'Queue records should contain the new Owner Id');
        }
    }

    @IsTest
    static void testAccountTypeChange() {
        setupData();
        accounts[0].Business_Development_Rep__c = currentUserId;
        accounts[1].Business_Development_Rep__c = currentUserId;
        insert accounts;

        Test.startTest();

        accounts[0].Territory__c = trac_Constants.ACCOUNT_TERRITORY_SEFL;
        accounts[0].OwnerId = currentUserId;
        accounts[1].Territory__c = trac_Constants.ACCOUNT_TERRITORY_WSF1;
        accounts[1].OwnerId = currentUserId;
        update accounts;

        List<Queue_Owner_Change__c> queues = [
                SELECT Id, Name, OwnerId, New_Owner_Id__c
                FROM Queue_Owner_Change__c
                WHERE Source_Type__c = :trac_Constants.QOC_SOURCE_TYPE_ACCOUNT
        ];

        Test.stopTest();

        if (trac_KillSwitchUtils.isDisabled('trac_AccountSyncOwner_queueAccountOwnerChange')) {
            System.assertEquals(0, queues.size(), 'The trigger is disabled - no Account records will be created');
        } else {
            System.assertEquals(6, queues.size(), 'Each Account should create three Queue records - Domain, Lead and Contact');
            System.assertEquals(String.valueOf(currentUserId), queues[0].New_Owner_Id__c, 'Queue records should contain the new Owner Id');
            System.assertEquals(String.valueOf(currentUserId), queues[1].New_Owner_Id__c, 'Queue records should contain the new Owner Id');
        }
    }

    @IsTest
    static void testBusinessDevRepChange() {
        setupData();
        accounts[0].Territory__c = trac_Constants.ACCOUNT_TERRITORY_SEFL;
        accounts[1].Territory__c = trac_Constants.ACCOUNT_TERRITORY_WSF1;
        insert accounts;

        Test.startTest();

        accounts[0].Business_Development_Rep__c = currentUserId;
        accounts[0].OwnerId = currentUserId;
        accounts[1].Business_Development_Rep__c = currentUserId;
        accounts[1].OwnerId = currentUserId;
        update accounts;

        List<Queue_Owner_Change__c> queues = [SELECT Id, Name, OwnerId, New_Owner_Id__c
        FROM Queue_Owner_Change__c
        WHERE Source_Type__c = :trac_Constants.QOC_SOURCE_TYPE_ACCOUNT];

        Test.stopTest();

        if (trac_KillSwitchUtils.isDisabled('trac_AccountSyncOwner_queueAccountOwnerChange')) {
            System.assertEquals(0, queues.size(), 'The trigger is disabled - no Account records will be created');
        } else {
            System.assertEquals(6, queues.size(), 'Each Account should create three Queue records - Domain, Lead and Contact');
            System.assertEquals(String.valueOf(currentUserId), queues[0].New_Owner_Id__c, 'Queue records should contain the new Owner Id');
            System.assertEquals(String.valueOf(currentUserId), queues[1].New_Owner_Id__c, 'Queue records should contain the new Owner Id');
        }
    }
}