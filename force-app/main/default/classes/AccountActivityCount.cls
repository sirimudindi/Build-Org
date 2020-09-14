public with sharing class AccountActivityCount {
  /*
    public static String accountPrefix =  Account.sObjectType.getDescribe().getKeyPrefix();

    
    * Takes a set of  account IDs, queries those accounts, and updates the activity count if appropriate
    
    public static void updateAccountCounts(Set<ID> accountIds) {
            List<String> exclusions = new List<String>();
    
            String hubspotId = '00540000002GZye';
            String marketoId = '00540000002HoCG';
            String crusherId = '00540000001UYoJ';
            exclusions.add(hubspotId);
            exclusions.add(marketoId);
            exclusions.add(crusherId);

            //Get all accounts from DB, including the tasks child relationships
           List<Account> accounts = [SELECT ID, activity_count__c FROM Account WHERE ID IN :accountIds];
           List<Task> compTasks = [SELECT ID, AccountID FROM Task WHERE Status = 'Completed' AND AccountID IN :accountIds AND CreatedById NOT IN :exclusions ORDER BY CreatedDate DESC LIMIT 10000];
           List<Event> events = [SELECT ID, AccountID FROM Event WHERE AccountID IN :accountIds AND CreatedById NOT IN :exclusions ORDER BY CreatedDate DESC LIMIT 10000];
            
           List<Account> updateAccounts = new List<Account>();

           for (Account a : accounts) {
                Integer count = 0;

                // find current account in opps
                for ( Task t : compTasks ) {
                    if ( t.accountID == a.id ) {
                        count++;
                    }
                }

                // find current account in contacts
                for ( Event e : events ) {
                    if ( e.accountID == a.id ) {
                        count++;
                    }
                }

                if (a.activity_count__c != count) {
                    a.activity_count__c = count;
                    updateAccounts.add(a); //we're only doing updates to accounts that have changed...no need to modify the others
                }
            }


            //Update the appropriate accounts
            try {
                update updateAccounts;
            } catch (Exception e) {
                //This is controversial. Anything could happen when updating the account..validation rule, security, etc. The key is we don't
                //want the event update to fail...so we put a try catch around the account update to make sure we don't stop that from happening.
            }
    }
    */
}