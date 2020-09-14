/**
 * @description Describes functionality of actions to perform on triggers for knowledge feedback
 * @author      hpurvis, Traction on Demand
 * @date        2020-01-07
 */
public with sharing class trac_KnowledgeFeedbackHandler {
    /**
     * @description Stamps the base knowledge article Id on new junction records (called from Before Insert trigger)
     * @author      hpurvis, Traction on Demand
     * @date        2020-01-07
     */
    public void stampBaseArticleId(List<Knowledge_Feedback__c> records) {

        // Create a set of all related KnowledgeArticleVersion Ids
        Set<Id> articleIds = new Set<Id>();
        for (Knowledge_Feedback__c record : records) {
            articleIds.add(record.Knowledge_Article__c);
        }

        if (!articleIds.isEmpty()) {
            // Query to get the Ids of the base knowledge articles
            List<Knowledge__kav> kavs = [
                    SELECT  Id,
                            KnowledgeArticleId
                    FROM    Knowledge__kav
                    WHERE   Id IN :articleIds
            ];

            // Convert to Map for quick lookup
            Map<Id,Knowledge__kav> kavsById = new Map<Id,Knowledge__kav>(kavs);

            // Process Knowledge_Feedback__c records and set custom field with the base article Id
            for (Knowledge_Feedback__c record : records) {
                Knowledge__kav kav = kavsById.get(record.Knowledge_Article__c);
                record.KnowledgeArticleId__c = kav.KnowledgeArticleId;
            }
        }
    }
}