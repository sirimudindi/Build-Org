/**
 * @description Trigger for Knowledge__kav
 * @author  hpurvis, Traction on Demand
 * @date    2020-01-07
 */
trigger trac_KnowledgeArticleTrigger on Knowledge__kav (before update, before delete) {
    trac_TriggerHandlerBase.triggerHandler(new trac_KnowledgeArticleVersion());
}