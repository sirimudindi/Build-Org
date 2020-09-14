/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_ffrr_RevenueRecognitionTra81Trigger on ffrr__RevenueRecognitionTransactionLine__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(ffrr__RevenueRecognitionTransactionLine__c.SObjectType);
}