@isTest(seeAllData=false)
public with sharing class trac_IntegrationLeadProcessingTest {

    static User marketoUser = getMarketoIntegrationUser();

    public static testMethod void lead_trac_IntegrationLeadProcessing_leadDomainAssignmentOnBeforeInsert_TEST() {
        
        Lead lead1;
        System.runAs(marketoUser) {
            lead1 = trac_TestUtils.createLead('LastNameTest1', 'testCompany1', 'traction.com');
            insert lead1;
        }

        Lead leadQueryTest = [SELECT Id, Domain__c, Domain_Lookup__c, OwnerId FROM Lead];
        Domain__c domainQueryTest = [SELECT Id, Name, Domain_Name_URL__c, OwnerId FROM Domain__c];

        
        System.assertEquals(lead1.Domain__c, domainQueryTest.Domain_Name_URL__c);
        System.assertEquals(lead1.Domain__c, domainQueryTest.Name);
        System.assertEquals(domainQueryTest.Id, leadQueryTest.Domain_Lookup__c);
        System.assertEquals([ SELECT Id FROM User WHERE Name LIKE '%Andrew%Imhoff%' ].Id, domainQueryTest.OwnerId);

        ////////////////////////////////////////////////////
        // Reset dispatcher to mimic separate code execution
        ////////////////////////////////////////////////////
        trac_TestUtils.resetCodeExecution();

        Lead lead2 = trac_TestUtils.createLead('LastNameTest2', 'testCompany2', 'traction.com');
        insert lead2;

        leadQueryTest = [SELECT Id, Domain__c, Domain_Lookup__c, OwnerId FROM Lead WHERE Company = 'testCompany2' LIMIT 1];
        System.assertEquals(lead2.Domain__c, domainQueryTest.Domain_Name_URL__c);
        System.assertEquals(lead2.Domain__c, domainQueryTest.Name);
        System.assertEquals(domainQueryTest.Id, leadQueryTest.Domain_Lookup__c);
        
        /**
            Dec 14th, 2014 - Client requested to turn off lead.Owner reassignment.
            System.assertEquals(marketoUser.Id, leadQueryTest.OwnerId);
        **/

        ////////////////////////////////////////////////////
        // Reset dispatcher to mimic separate code execution
        ////////////////////////////////////////////////////
        trac_TestUtils.resetCodeExecution();

        domainQueryTest.OwnerId = UserInfo.getUserId();
        update domainQueryTest;

        Lead lead3 = trac_TestUtils.createLead('LastNameTest3', 'testCompany3', 'traction.com');
        insert lead3;

        leadQueryTest = [SELECT Id, Domain__c, Domain_Lookup__c, OwnerId FROM Lead WHERE Company = 'testCompany2' LIMIT 1];
        
        /**
            Dec 14th, 2014 - Client requested to turn off lead.Owner reassignment.
            System.assertEquals(marketoUser.Id, leadQueryTest.OwnerId);
        **/
        leadQueryTest = [SELECT Id, Domain__c, Domain_Lookup__c, OwnerId FROM Lead WHERE Company = 'testCompany3' LIMIT 1];
        
        System.assertEquals(UserInfo.getUserId(), leadQueryTest.OwnerId);


    }

    public static testMethod void lead_trac_IntegrationLeadProcessing_leadPaymentProfileCreationOnInsert_TEST() {
        Lead lead1 = trac_TestUtils.createLead('LastNameTest1', 'testCompany1', 'traction.com');
        lead1.paymentProfileID__c = '1';
        lead1.parentPaymentProfileID__c = '2';
        insert lead1;
        System.debug([SELECT Id, PPID__c, PPPID__c FROM Payment_Profile__c]);        
        Domain__c domainQueryTest = [SELECT Id FROM Domain__c];
        Lead leadQueryTest = [SELECT Domain_Lookup__c FROM Lead];

        System.assertEquals(domainQueryTest.Id, leadQueryTest.Domain_Lookup__c);
    }

    public static testMethod void lead_trac_IntegrationLeadProcessing_leadDomainBeforeUpdate_No_PPID_TEST() {
        Lead lead1 = trac_TestUtils.createLead('LastNameTest1', 'testCompany1', 'traction.com');
        insert lead1;

        System.assertEquals([SELECT Id FROM Domain__c WHERE Domain_Name_URL__c = 'traction.com'].Id, [SELECT Domain_Lookup__c FROM Lead].Domain_Lookup__c);

        ////////////////////////////////////////////////////
        // Reset dispatcher to mimic separate code execution
        ////////////////////////////////////////////////////
        trac_TestUtils.resetCodeExecution();

        lead1.Domain__c = 'tractionondemand.com';
        update lead1;

        System.assertEquals(0, [SELECT Id FROM Payment_Profile__c].size());
        System.assertEquals(2, [SELECT Id FROM Domain__c].size());
        System.assertEquals(1, [SELECT Id FROM Lead].size());

        System.assertEquals([SELECT Id FROM Domain__c WHERE Domain_Name_URL__c = 'tractionondemand.com'].Id, [SELECT Domain_Lookup__c FROM Lead].Domain_Lookup__c);

    }

    public static testMethod void lead_trac_IntegrationLeadProcessing_leadDomainBeforeUpdate_TEST() {
        Lead lead1 = trac_TestUtils.createLead('LastNameTest1', 'testCompany1', 'traction.com');
        lead1.paymentProfileID__c = '1';
        lead1.parentPaymentProfileID__c = '2';
        insert lead1;

        Domain__c domainQueryTest = [SELECT Id FROM Domain__c];
        Lead leadQueryTest = [SELECT Domain_Lookup__c FROM Lead];

        System.assertEquals(domainQueryTest.Id, leadQueryTest.Domain_Lookup__c);

        ////////////////////////////////////////////////////
        // Reset dispatcher to mimic separate code execution
        ////////////////////////////////////////////////////
        trac_TestUtils.resetCodeExecution();

        lead1.Domain__c = 'tractionondemand.com';
        update lead1;

        domainQueryTest = [SELECT Id FROM Domain__c WHERE Domain_Name_URL__c = 'tractionondemand.com' LIMIT 1];
        leadQueryTest = [SELECT Domain_Lookup__c FROM Lead];

        System.assertEquals(2, [SELECT Id FROM Domain__c].size());        
        System.assertEquals(1, [SELECT Id FROM Lead].size());

        System.assertEquals(domainQueryTest.Id, leadQueryTest.Domain_Lookup__c);
    }

    public static testMethod void lead_trac_IntegrationLeadProcessing_leadDomainBeforeUpdateNotExistingPaymentProfile_TEST() {
        Lead lead1 = trac_TestUtils.createLead('LastNameTest1', 'testCompany1', 'traction.com');
        insert lead1;

        Domain__c domainQueryTest = [SELECT Id FROM Domain__c];
        Lead leadQueryTest = [SELECT Domain_Lookup__c FROM Lead];

        System.assertEquals(domainQueryTest.Id, leadQueryTest.Domain_Lookup__c);

        ////////////////////////////////////////////////////
        // Reset dispatcher to mimic separate code execution
        ////////////////////////////////////////////////////
        trac_TestUtils.resetCodeExecution();

        lead1.Domain__c = 'tractionondemand.com';
        lead1.paymentProfileID__c = '1';
        lead1.parentPaymentProfileID__c = '2';
        update lead1;

        domainQueryTest = [SELECT Id FROM Domain__c WHERE Domain_Name_URL__c = 'tractionondemand.com' LIMIT 1];
        leadQueryTest = [SELECT Domain_Lookup__c FROM Lead];

        System.assertEquals(2, [SELECT Id FROM Domain__c].size());        
        System.assertEquals(1, [SELECT Id FROM Lead].size());


        System.assertEquals(domainQueryTest.Id, leadQueryTest.Domain_Lookup__c);

    }

    public static testMethod void lead_trac_IntegrationLeadProcessing_leadDomainBeforeUpdate_With_AND_Without_ExistingPaymentProfile_TEST() {
        Lead lead1 = trac_TestUtils.createLead('LastNameTest1', 'testCompany1', 'traction.com');

        Lead lead2 = trac_TestUtils.createLead('LastNameTest2', 'testCompany2', 'traction.com');
        lead2.paymentProfileID__c = '3';
        lead2.parentPaymentProfileID__c = '4';
        
        insert new List<Lead>{lead1, lead2};

        ////////////////////////////////////////////////////
        // Reset dispatcher to mimic separate code execution
        ////////////////////////////////////////////////////
        trac_TestUtils.resetCodeExecution();

        lead1.Domain__c = 'tractionondemand.com';
        lead1.paymentProfileID__c = '1';
        lead1.parentPaymentProfileID__c = '2';

        lead2.Domain__c = 'tractionondemand.com';
        update new List<Lead>{lead1, lead2};

        System.assertEquals(2, [SELECT Id FROM Domain__c].size());        
        System.assertEquals(2, [SELECT Id FROM Lead].size());

        Domain__c domainQueryTest = [SELECT Id FROM Domain__c WHERE Domain_Name_URL__c = 'tractionondemand.com' LIMIT 1];

        System.assertEquals(domainQueryTest.Id, [SELECT Domain_Lookup__c FROM Lead WHERE Company = 'testCompany1'].Domain_Lookup__c);
        System.assertEquals(domainQueryTest.Id, [SELECT Domain_Lookup__c FROM Lead WHERE Company = 'testCompany2'].Domain_Lookup__c);

    }

    public static testMethod void lead_trac_IntegrationLeadProcessing_leadParentPaymentProfileIdInserted_TEST() {
        Lead lead1 = trac_TestUtils.createLead('LastNameTest1', 'testCompany1', 'traction.com');
        lead1.paymentProfileID__c = '1';
        insert lead1;

        System.assertEquals([SELECT Id FROM Domain__c WHERE Domain_Name_URL__c = 'traction.com'].Id, [SELECT Domain_Lookup__c FROM Lead].Domain_Lookup__c);

        ////////////////////////////////////////////////////
        // Reset dispatcher to mimic separate code execution
        ////////////////////////////////////////////////////
        trac_TestUtils.resetCodeExecution();

        lead1.parentPaymentProfileID__c = '2';
        update lead1;

    }

    static User getMarketoIntegrationUser() {
        List<User> rUser = [SELECT Id FROM User WHERE Name = 'Marketo Integration'];
        if( rUser.isEmpty() ) {
            User tmp = new User(
                FirstName = 'Marketo',
                LastName = 'Integration',
                Email = 'traction@test.ca',
                UserName = 'traction@test.ca',
                Alias = 'tester',
                TimeZoneSidKey = 'America/Los_Angeles',
                LocaleSidKey = 'en_CA',
                EmailEncodingKey = 'ISO-8859-1',
                ProfileId = [SELECT Id, Name, UserType FROM Profile WHERE Name = 'System Administrator'].Id,
                LanguageLocaleKey = 'en_US'
            );

            insert tmp;
            return tmp;
        }

        return rUser[0];
    }

  
    private static testmethod void test_syncLeadLastActivityDateWithDomains(){
    
        Lead newLead = trac_TestUtils.createLead('test Last name', 'test Company', 'www.test.com');
        insert newLead;

        List<Domain__c> lstDomains = new List<Domain__c>();
        lstDomains = [Select Id,Name,Last_Activity_Date__c From Domain__c Limit 1 ];
        
        //check if domain is created
        System.assert(lstDomains.size()>0);
        System.assert(lstDomains[0].Name == 'www.test.com' );
        System.assert(lstDomains[0].Last_Activity_Date__c == null );

        User newUser = trac_TestUtils.createUser('test@tractioondemand.com.test', 'tst', 'firstName', 'lastName');

        Task newTask = trac_TestUtils.createTask(null, newLead.Id, 'test subject', newUser.Id, 'Call', 'Completed', Date.today());
        insert newTask; 


        //check if domain has Last activity date
        lstDomains = [Select Id,Name,Last_Activity_Date__c From Domain__c Limit 1 ];
        System.assert(lstDomains.size()>0);
        System.assert(lstDomains[0].Name == 'www.test.com' );
        //System.assert(lstDomains[0].Last_Activity_Date__c == newTask.ActivityDate );
    }

}