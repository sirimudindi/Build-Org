trigger EventUpdateLead on Event (after delete, after insert, after undelete, after update) {

    Set<ID> leadIds = new Set<ID>();
    
    //We only care about tasks linked to leads.
    String prefix =  LeadActivityCount.leadPrefix;

    //Add any lead ids coming from the new data
    if (Trigger.new != null) {
        for (Event e : Trigger.new) {
            if (e.whoId != null && String.valueOf(e.whoId).startsWith(prefix) ) {
                leadIds.add(e.whoId);
            }
        }
    }

    //Also add any lead ids coming from the old data (deletes, moving an activity from one lead to another)
    if (Trigger.old != null) {
        for (Event e : Trigger.old) {
            if (e.whoId != null && String.valueOf(e.whoId).startsWith(prefix) ) {
                leadIds.add(e.whoId);
            }
        }
    }

    if (leadIds.size() > 0){
        LeadActivityCount.updateLeadCounts(leadIds);
    }
}