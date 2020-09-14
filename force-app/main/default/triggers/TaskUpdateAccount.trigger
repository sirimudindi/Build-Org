trigger TaskUpdateAccount on Task (after delete, after insert, after undelete, after update) {
    /*
    Set<ID> accountIds = new Set<ID>();


    //We only care about tasks linked to accounts.
    String prefix =  AccountActivityCount.accountPrefix;

    //Add any account ids coming from the new data
    if (Trigger.new != null) {
        for (Task t : Trigger.new) {
            if (t.accountId != null && String.valueOf(t.accountId).startsWith(prefix) ) {
                accountIds.add(t.accountId);
            }
        }
    }
    //Also add any account ids coming from the old data (deletes, moving an activity from one lead to another)
    if (Trigger.old != null) {
        for (Task t : Trigger.old) {
            if (t.accountId != null && String.valueOf(t.accountId).startsWith(prefix) ) {
                accountIds.add(t.accountId);
            }
        }
    }

    if (accountIds.size() > 0){
        AccountActivityCount.updateAccountCounts(accountIds);
    }
    */
}