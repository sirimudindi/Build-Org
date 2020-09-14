public with sharing class LeadActivityCount {

    public static Boolean didRun = false;
    public static String leadPrefix =  Lead.sObjectType.getDescribe().getKeyPrefix();

    /*
    * Takes a set of lead IDs, queries those leads, and updates the activity count if appropriate
    */
    public static void updateLeadCounts(Set<ID> leadIds) {
 //   Taking this out for now...not sure if we need it. But, leaving it in comments, just in case. :)
 //			if (didRun == false) { //We only want this operation to run once per transaction.
 //           didRun = true;

            //Get all leads from DB, including the tasks child relationships
			List<Lead> leads = [SELECT ID, activity_count__c, (SELECT ID FROM Tasks WHERE Status = 'Completed'), (SELECT ID FROM Events) FROM Lead WHERE ID IN :leadIds];
			List<Lead> updateLeads = new List<Lead>();

			for (Lead l : leads) {
                Integer count = l.tasks.size() + l.events.size();
                if (l.activity_count__c != count) {
                    l.activity_count__c = count;
                    updateLeads.add(l); //we're only doing updates to leads that have changed...no need to modify the others
                }
            }

            //Update the appropriate leads
            try {
                update updateLeads;
            } catch (Exception e) {
                //This is controversial. Anything could happen when updating the lead..validation rule, security, etc. The key is we don't
                //want the event update to fail...so we put a try catch around the lead update to make sure we don't stop that from happening.
            }
//        }
    }
    
    
}