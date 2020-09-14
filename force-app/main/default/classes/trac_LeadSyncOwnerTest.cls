/**
 * Created by akong on 11/24/2018.
 */

@IsTest
private class trac_LeadSyncOwnerTest {

    @IsTest
    private static void syncLeadDomainOwner() {
        List<Lead> testLeads = new List<Lead>();
        Map<Id, Lead> testLeadById = new Map<Id, Lead>();

        Exception resultException;

        Test.startTest();

        try {
            trac_LeadSyncOwner.syncLeadDomainOwner(testLeads, testLeadById);
        } catch(Exception e) {
            resultException = e;
        }

        Test.stopTest();

        System.assertEquals(null, resultException);
    }

//    private static User standardUser1;
//    private static User standardUser2;
//    private static Id currentUserId = UserInfo.getUserId();
//    private static List<Lead> leads = new List<Lead>();
//    private static List<Domain__c> domains = new List<Domain__c>();
//
//    private static void setupData() {
//        // create user
//        String orgId = UserInfo.getOrganizationId();
//        standardUser1 = trac_TestUtils.createUser('user1@testtesttest.'+orgId+'.com', 'user1', 'Testy', 'Tester1');
//        standardUser2 = trac_TestUtils.createUser('user2@testtesttest.'+orgId+'.com', 'user2', 'Testy', 'Tester2');
//
//        // create account data
//        Account account = trac_TestUtils.createAccount();
//        insert account;
//
//        // create domain data
//        domains.add( trac_TestUtils.createDomain('testtesttest.com', standardUser1.id) );
//        domains.add( trac_TestUtils.createDomain('toasttoasttoast.com', standardUser2.id) );
//        insert domains;
//
//        // create lead data
//        leads.add( trac_TestUtils.createLead('Tester1', 'testCo1', 'foofoofoo.com') );
//        leads.add( trac_TestUtils.createLead('Tester2', 'testCo2', 'foofoofoo.com') );
//        leads.add( trac_TestUtils.createLead('Tester3', 'testCo3', 'foofoofoo.com') );
//    }
//
//    @IsTest
//    static void testSyncLeadDomainOwnerOnInsert() {
//
//        setupData();
//
//        leads[0].Domain__c = domains[0].Name;
//        leads[1].Domain__c = domains[0].Name;
//        leads[2].Domain__c = domains[1].Name;
//        leads[0].Domain_Lookup__c = domains[0].Id;
//        leads[1].Domain_Lookup__c = domains[0].Id;
//        leads[2].Domain_Lookup__c = domains[1].Id;
//
//        Test.startTest();
//
//        insert leads;
//
//        Test.stopTest();
//
//        leads = [SELECT Id, Domain_Lookup__c, OwnerId FROM Lead];
//
//        Map<Id,Domain__c> domainMap = new Map<Id,Domain__c>(domains);
//
//        for (Lead ld : leads) {
//            Domain__c dom = domainMap.get(ld.Domain_Lookup__c);
//            if (!trac_KillSwitchUtils.isDisabled('trac_LeadSyncOwner_syncLeadDomainOwner')) {
//                System.assertEquals(dom.OwnerId, ld.OwnerId);
//            } else {
//                System.assertNotEquals(dom.OwnerId, ld.OwnerId);
//            }
//        }
//    }
//
//    @IsTest
//    static void testSyncLeadDomainOwnerOnUpdate() {
//        setupData();
//        insert leads;
//
//        Test.startTest();
//
//        leads[0].Domain__c = domains[0].Name;
//        leads[1].Domain__c = domains[0].Name;
//        leads[2].Domain__c = domains[1].Name;
//        leads[0].Domain_Lookup__c = domains[0].Id;
//        leads[1].Domain_Lookup__c = domains[0].Id;
//        leads[2].Domain_Lookup__c = domains[1].Id;
//        update leads;
//
//        Test.stopTest();
//
//        leads = [SELECT Id, Domain_Lookup__c, OwnerId FROM Lead];
//
//        Map<Id,Domain__c> domainMap = new Map<Id,Domain__c>(domains);
//
//        for (Lead ld : leads) {
//            Domain__c dom = domainMap.get(ld.Domain_Lookup__c);
//            if (!trac_KillSwitchUtils.isDisabled('trac_LeadSyncOwner_syncLeadDomainOwner')) {
//                System.assertEquals(dom.OwnerId, ld.OwnerId);
//            } else {
//                System.assertNotEquals(dom.OwnerId, ld.OwnerId);
//            }
//        }
//    }
//
//    @IsTest
//    static void testBlockedOwnerIdChange() {
//        setupData();
//        //leads[0].Domain_Lookup__c = domains[0].Id;
//        leads[0].Domain__c = 'testtesttest.com';
//        insert leads[0];
//
//        // leads[0] owner should be standardUser1
//        Lead ld = [SELECT Id, OwnerId FROM Lead WHERE Id = :leads[0].Id];
//        if (!trac_KillSwitchUtils.isDisabled('trac_LeadSyncOwner_syncLeadDomainOwner')) {
//            System.assertEquals(standardUser1.Id, ld.OwnerId);
//        } else {
//            System.assertEquals(currentUserId, ld.OwnerId);
//        }
//
//        Test.startTest();
//
//        // force change the owner ID
//        leads[0].OwnerId = standardUser2.Id;
//        update leads[0];
//
//        Test.stopTest();
//
//        // leads[0].OwnerId should still be standardUser1
//        ld = [SELECT Id, OwnerId FROM Lead WHERE Id = :leads[0].Id];
//        if (!trac_KillSwitchUtils.isDisabled('trac_LeadSyncOwner_syncLeadDomainOwner')) {
//            System.assertEquals(standardUser1.Id, ld.OwnerId);
//        } else {
//            System.assertEquals(leads[0].OwnerId, ld.OwnerId);
//        }
//    }
//
//    @IsTest
//    static void testUnassignedQueue() {
//        setupData();
//
//        // setup another admin user
//        String orgId = UserInfo.getOrganizationId();
//        User adminUser2 = trac_TestUtils.createUser('admin2@testtesttest.'+orgId+'.com', 'admn2', 'TestAdmin', 'TesterAdmin2', 'System Administrator');
//
//        // setup Unassigned Queue user group
//        Group unassignedQueue = trac_TestUtils.createGroups(1, 'Queue', false)[0];
//        insert unassignedQueue;
//
//        // setup the QueueSObject association
//        QueueSobject mappingObject = new QueueSobject(QueueId = unassignedQueue.Id, SobjectType = 'Lead');
//        System.runAs(new User(Id = UserInfo.getUserId()))
//        {insert mappingObject;} // prevent mixed dml op
//
//        // setup Lead_Owner_Queue_Mapping__mdt custom metadata type and override it in main class
//        Lead_Owner_Queue_Mapping__mdt ownerQueueMapping = new Lead_Owner_Queue_Mapping__mdt();
//        ownerQueueMapping.DeveloperName = trac_LeadSyncOwner.LEAD_UNASSIGNED_QUEUE_MDT;
//        ownerQueueMapping.Owner_Id__c = String.valueOf(standardUser2.Id);
//        ownerQueueMapping.Group_Id__c = String.valueOf(unassignedQueue.Id);
//        trac_LeadSyncOwner.ownerQueueMap = ownerQueueMapping;
//
//        // finish inserting the lead
//        leads[0].Domain__c = 'testtesttest.com';
//        insert leads[0];
//
//        // leads[0] owner should be standardUser1 due to domain owner
//        Lead ld = [SELECT Id, OwnerId FROM Lead WHERE Id = :leads[0].Id];
//        if (!trac_KillSwitchUtils.isDisabled('trac_LeadSyncOwner_syncLeadDomainOwner')) {
//            System.assertEquals(standardUser1.Id, ld.OwnerId);
//        } else {
//            System.assertEquals(currentUserId, ld.OwnerId);
//        }
//
//        Test.startTest();
//
//        // force change the owner ID to standardUser2
//        leads[0].OwnerId = adminUser2.Id;
//        update leads[0];
//
//        Test.stopTest();
//
//        // leads[0].OwnerId should now be the unassigned queue due to the custom metadata logic
//        ld = [SELECT Id, OwnerId FROM Lead WHERE Id = :leads[0].Id];
//        if (!trac_KillSwitchUtils.isDisabled('trac_LeadSyncOwner_syncLeadDomainOwner')) {
//            System.assertEquals(unassignedQueue.Id, ld.OwnerId);
//        } else {
//            System.assertEquals(leads[0].OwnerId, ld.OwnerId);
//        }
//    }
}