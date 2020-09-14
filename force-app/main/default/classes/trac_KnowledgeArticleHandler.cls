/**
 * @description Describes functionality of actions to perform on triggers for knowledge articles
 * @author  hpurvis, Traction on Demand
 * @date    2020-01-07
 */
public with sharing class trac_KnowledgeArticleHandler {

    /**
     * @description When an article is edited this method updates child junction objects to lookup to the new Article
     *              Version being edited
     * @author      hpurvis, Traction on Demand
     * @date        2020-01-07
     */
    public void syncJunctionRecordsOnKnowledgeUpdates(List<Knowledge__kav> knowledgeArticles) {
        //create a map of KAVs by Base Knowledge Article Id : KA version Id
        Map<Id,Id> kavsByBaseArticleId = new Map<Id,Id>();

        for (Knowledge__kav article : knowledgeArticles) {
            kavsByBaseArticleId.put(article.KnowledgeArticleId, article.Id);
        }

        List<Knowledge_Feedback__c> linkedKnowledgeFeedbacks = new List<Knowledge_Feedback__c>();
        //update all child Knowledge_Feedback__c records on latest version to lookup to the new KAV Id
        for (Knowledge_Feedback__c record : [   SELECT  KnowledgeArticleId__c,Knowledge_Article__c
                                                FROM    Knowledge_Feedback__c
                                                WHERE   KnowledgeArticleId__c IN :kavsByBaseArticleId.keySet()
                                                AND     Knowledge_Article__r.IsLatestVersion = TRUE]) {
            // Link the feedback to new ka version
            record.Knowledge_Article__c = kavsByBaseArticleId.get(record.KnowledgeArticleId__c);
            linkedKnowledgeFeedbacks.add(record);
        }

        if (!linkedKnowledgeFeedbacks.isEmpty()) {
            update linkedKnowledgeFeedbacks;
        }
    }

    /**
     * @description When an draft article with feedback attached is deleted, this method updates
     *              child junction objects to lookup to the old Article Version
     * @author      hpurvis, Traction on Demand
     * @date        2020-01-07
     */
    public void downversionFeedbackOnDraftDelete(Map<Id,Knowledge__kav> knowledgeArticles) {
        //create a map of KAVs by Base Knowledge Article Id : KA version Id
        Map<Id,Id> kavsByBaseArticleId = new Map<Id,Id>();

        for (Knowledge__kav article : knowledgeArticles.values()) {
            kavsByBaseArticleId.put(article.KnowledgeArticleId, article.Id);
        }

        //update all child Knowledge_Feedback__c records on latest version to lookup to the new KAV Id
        List<Knowledge_Feedback__c> knowledgeFeedbacks = [
                SELECT  KnowledgeArticleId__c,
                        Knowledge_Article__c
                FROM    Knowledge_Feedback__c
                WHERE   Knowledge_Article__c IN :knowledgeArticles.keySet()
                AND     Knowledge_Article__r.IsLatestVersion = True
                AND     Knowledge_Article__r.PublishStatus = 'Draft'
        ];

        if (!knowledgeFeedbacks.isEmpty()){
            List<Knowledge__kav> oldKavs = [
                    SELECT  Id,
                            KnowledgeArticleId
                    FROM    Knowledge__kav
                    WHERE   KnowledgeArticleId IN :kavsByBaseArticleId.keySet()
                    AND     PublishStatus = 'Online'
                    AND     IsLatestVersion = True
            ];

            Map<Id,Id> oldKavsByBaseArticleId = new Map<Id,Id>();

            for (Knowledge__kav article : oldKavs) {
                oldKavsByBaseArticleId.put(article.KnowledgeArticleId, article.Id);
            }

            List<Knowledge_Feedback__c> linkedKnowledgeFeedbacks = new List<Knowledge_Feedback__c>();
            for (Knowledge_Feedback__c record : knowledgeFeedbacks) {
                Id oldKavId = oldKavsByBaseArticleId.get(record.KnowledgeArticleId__c);
                record.Knowledge_Article__c = oldKavId;
                linkedKnowledgeFeedbacks.add(record);
            }

            if (!linkedKnowledgeFeedbacks.isEmpty()) {
                update linkedKnowledgeFeedbacks;
            }
        }

    }
}