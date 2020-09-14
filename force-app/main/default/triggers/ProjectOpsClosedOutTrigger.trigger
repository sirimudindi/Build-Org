trigger ProjectOpsClosedOutTrigger on pse__Proj__c (before update) {
    if(Trigger.isBefore || Trigger.isUpdate) {
        ProjectOpsClosedOutController.ProjectOpsClosed(trigger.New, trigger.oldMap);
    }
}