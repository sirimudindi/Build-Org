@isTest
private class LeadActivityTest {
  //  public static Boolean didRun = false;
    /*
    * Test method for this class and TaskUpdateOpportunity and EventUpdateOpportunity
    */
    public static testMethod void testCountTask() {
        //Setup
        Account a = new Account(name='Test');
        insert a;

        Lead lead = new Lead(FirstName='John', LastName='Doe', Status='Open', Company='Company ABC');
        insert lead;

        //Insert our first task
        Task t = new Task(subject='Test Activity', whoId = lead.id, status = 'Completed');
        insert t;
        
        //Verify count
        lead = [SELECT ID, activity_count__c FROM Lead WHERE ID = :lead.id];
        System.assertEquals(1, lead.activity_count__c);

        //Disconnect task from the lead
        t.whoid = null;
        update t;
        
        //Verify count = 0
        lead = [SELECT ID, activity_count__c FROM Lead WHERE ID = :lead.id];
//        lead = [SELECT ID, activity_count__c, (SELECT ID FROM Tasks WHERE Status = 'Completed'), (SELECT ID FROM Events) FROM Lead WHERE ID = :lead.id];
        System.assertEquals(0, lead.activity_count__c);

//        didRun = false; //Reset
        
        //Add an event
        Event e = new Event(subject='Test Event', whoId = lead.id, startDateTime = System.Now(), endDateTime = System.now());
        insert e;

        //Verify count = 1
        lead = [SELECT ID, activity_count__c FROM Lead WHERE ID = :lead.id];
        System.assertEquals(1, lead.activity_count__c);

        //Relink the task to the lead
//        didRun = false; //Reset
        t.whoId = lead.id;
        update t;

        //Verify count = 2
        lead = [SELECT ID, activity_count__c FROM Lead WHERE ID = :lead.id];
        System.assertEquals(2, lead.activity_count__c);

        //Disconnect the event from the lead
//        didRun = false; //Reset
        e.whoId = null;
        update e;

        //Verify count is back down to 1
        lead = [SELECT ID, activity_count__c FROM Lead WHERE ID = :lead.id];
        System.assertEquals(1, lead.activity_count__c);

        //Delete the task
//        didRun = false; //reset
        delete t;
        
        //Verify count is back down to 0
        lead = [SELECT ID, activity_count__c FROM Lead WHERE ID = :lead.id];
        System.assertEquals(0, lead.activity_count__c);

    }
}