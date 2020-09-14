/**
 * @description Domain class for handling trigger functionality on knowledge article versions
 * @author  hpurvis, Traction on Demand
 * @date    2020-01-07
 */
public with sharing class trac_KnowledgeArticleVersion extends trac_TriggerHandlerBase {

    private List<Knowledge__kav> newKnowledgeArticleList = (List<Knowledge__kav>) newRecordsList;
    private Map<Id, Knowledge__kav> oldKnowledgeArticleMap = (Map<Id, Knowledge__kav>) oldRecordsMap;

    public override void handleBeforeUpdate() {
        trac_KnowledgeArticleHandler handler = new trac_KnowledgeArticleHandler();
        handler.syncJunctionRecordsOnKnowledgeUpdates(newKnowledgeArticleList);
    }

    public override void handleBeforeDelete() {
        trac_KnowledgeArticleHandler handler = new trac_KnowledgeArticleHandler();
        handler.downversionFeedbackOnDraftDelete(oldKnowledgeArticleMap);
    }
}