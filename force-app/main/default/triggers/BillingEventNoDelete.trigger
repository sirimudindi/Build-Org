trigger BillingEventNoDelete on pse__Billing_Event__c (before delete) {
    for (pse__Billing_Event__c be : [SELECT Id FROM pse__Billing_Event__c WHERE Id IN :Trigger.old AND pse__Invoiced__c = TRUE]) {
        Trigger.oldMap.get(be.Id).addError('You cannot delete this Billing Event as it has already been invoiced.');
    }
        
}