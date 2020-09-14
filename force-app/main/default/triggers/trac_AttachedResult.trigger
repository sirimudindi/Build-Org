/**
 * @description Trigger that is fired on creation/update/delete of Coveo AttachedResult object
 * @author      AFee, Traction On Demand
 * @date        22-Jul-2019
 */
trigger trac_AttachedResult on CoveoV2__CoveoCaseAttachedResult__c (after update, after insert, after delete, after undelete) {
    trac_TriggerHandlerBase.triggerHandler(new trac_AttachedResultHandler());
}