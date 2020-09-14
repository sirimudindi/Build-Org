/**
 * @description Domain class for handling trigger functionality on knowledge feedbacks
 * @author  hpurvis, Traction on Demand
 * @date    2020-01-07
 */
public with sharing class trac_KnowledgeFeedback extends trac_TriggerHandlerBase {

    private List<Knowledge_Feedback__c> newFeedbackList = (List<Knowledge_Feedback__c>) newRecordsList;
    private Map<Id, Knowledge_Feedback__c> oldFeedbackMap = (Map<Id, Knowledge_Feedback__c>) oldRecordsMap;

    public override void handleBeforeInsert() {
        trac_KnowledgeFeedbackHandler handler = new trac_KnowledgeFeedbackHandler();
        handler.stampBaseArticleId(newFeedbackList);
    }
}