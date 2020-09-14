trigger TaskUpdateLead on Task (after delete, after insert, after undelete, after update) {
    
    Set<ID> leadIds = new Set<ID>();
    
    //We only care about tasks linked to leads.
    String prefix =  LeadActivityCount.leadPrefix;

    //Add any lead ids coming from the new data
    if (Trigger.new != null) {
        for (Task t : Trigger.new) {
            if (t.whoId != null && String.valueOf(t.whoId).startsWith(prefix) ) {
                leadIds.add(t.whoId);
            }
        }
    }
    //Also add any lead ids coming from the old data (deletes, moving an activity from one lead to another)
    if (Trigger.old != null) {
        for (Task t : Trigger.old) {
            if (t.whoId != null && String.valueOf(t.whoId).startsWith(prefix) ) {
                leadIds.add(t.whoId);
            }
        }
    }

    if (leadIds.size() > 0){
        LeadActivityCount.updateLeadCounts(leadIds);
    }
}