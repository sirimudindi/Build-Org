@isTest()
private class AccountActivityTest {
    /*
    * Test method for this class and TaskUpdateOpportunity and EventUpdateOpportunity
    */
//    public static testMethod void testCountTask() {
        //Setup     
//        Account account = new Account(name='Test');
//        insert account;

        //Insert tasks
//        List<Task> tasks = new List<Task>();
//        Integer taskCount = 1000;
//        for (Integer i = 0; i < taskCount; i++) {
//            Task t = new Task(subject='Test Activity' + i, whatId = account.id, status = 'Completed');
//            tasks.add(t);
//        }
//        insert tasks;

        //Verify count
    //    account = [SELECT ID, activity_count__c FROM Account WHERE ID = :account.id];
    //    System.assertEquals(taskCount, account.activity_count__c);
        //Disconnect task from the lead
       // for (Task t : tasks) {
         //   t.whatId = null;
        //}
 //       delete tasks;
        
        //Verify count = 0
    //    account = [SELECT ID, activity_count__c FROM Account WHERE ID = :account.id];
    //    System.assertEquals(0, account.activity_count__c);

        //Add an event
        /*
        Event e = new Event(subject='Test Event', whatId = account.id, startDateTime = DateTime.valueOf('2014-04-26 14:45:05'), endDateTime = DateTime.valueOf('2014-04-26 14:45:05'));
        insert e;

        //Verify count = 1
        account = [SELECT ID, activity_count__c FROM Account WHERE ID = :account.id];
        System.assertEquals(1, account.activity_count__c);
*/
        /*
        //Relink the task to the lead
        t.whatId = account.id;
        update t;

        //Verify count = 2
        account = [SELECT ID, activity_count__c FROM Account WHERE ID = :account.id];
        System.assertEquals(1, account.activity_count__c);

        //Delete the task
        delete t;
        
        //Verify count is back down to 0
        account = [SELECT ID, activity_count__c FROM Account WHERE ID = :account.id];
        System.assertEquals(0, account.activity_count__c);
*/
//    }
}