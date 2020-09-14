//Test class for BillingEventNoDelete Trigger
@isTest
public class BillingEventNoDeleteTest {
    @isTest static void BillingEventDeleteTest() {
        pse__Billing_Event__c be = new pse__Billing_Event__c(pse__Invoiced__c=TRUE);
        insert be;
        
        Test.startTest();
        Database.DeleteResult result = Database.delete(be, false);
        Test.stopTest();
        
        System.assert(!result.isSuccess());
    }
}