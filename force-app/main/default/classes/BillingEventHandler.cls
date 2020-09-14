public class BillingEventHandler {
    public static void beforeDelete(List<pse__Billing_Event__c> billingEventList){
        Map<Id, pse__Billing_Event__c> currentRecord = new Map<Id, pse__Billing_Event__c>();
        List<Id> listIds = new List<Id>();
        
        for(pse__Billing_Event__c be : billingEventList){
            listIds.add(be.Id);
        }
        
        currentRecord = new Map<Id, pse__Billing_Event__c>([SELECT id
                                                           FROM pse__Billing_Event__c
                                                           WHERE id IN :listIds]);
    }
}