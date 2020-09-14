/**
 * @description Trigger for knowledge feedback
 * @author  hpurvis, Traction on Demand
 * @date    2020-01-07
 */
trigger trac_KnowledgeFeedbackTrigger on Knowledge_Feedback__c (before insert) {
    trac_TriggerHandlerBase.triggerHandler(new trac_KnowledgeFeedback());
}