/**
 * @description Scheduled job to re calculate the feedback given on each version of a knowledge article.
 * @author  Heather Purvis, Traction on Demand
 * @date    2019-12-17
 */
public without sharing class trac_KnowledgeFeedbackCounter implements Database.Batchable<sObject>, Schedulable {

    @TestVisible private static final Traction_Setting__mdt SETTINGS = [
            SELECT  DeveloperName,
                    Batch_Size__c
            FROM Traction_Setting__mdt
            WHERE DeveloperName = 'Knowledge_Feedback_Count'
    ];

    private static final List<String> positiveFeedback = new List<String>{
            'Helpful'
    };

    private static final Integer MAX_BATCH_SIZE = 70;

    public void execute(SchedulableContext sc) {
        // Enforce batch size
        Integer batchSize = Integer.valueOf(SETTINGS.Batch_Size__c);
        if (batchSize > MAX_BATCH_SIZE) {
            batchSize = MAX_BATCH_SIZE;
        } else if (batchSize < 1) {
            batchSize = 1;
        }
        Database.executeBatch(new trac_KnowledgeFeedbackCounter(), batchSize);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Find all published knowledge articles with feedback. "Online" will be the latest version.
        return Database.getQueryLocator('SELECT Id, PublishStatus, KnowledgeArticleId'
                + ' FROM Knowledge__kav '
                + ' WHERE PublishStatus = \'Online\''
                + ' AND (Id IN ('
                +               ' SELECT    Knowledge_Article__c '
                +               ' FROM      Knowledge_Feedback__c '
                +               ' WHERE     Feedback_Category__c != null'
                + '               ))'
                + ' ORDER BY CreatedDate DESC'
        );
    }

    public void execute(Database.BatchableContext bc, List<Knowledge__kav> knowledgeArticles) {
        // Loop through all feedback and count positive and negative
        Map<Id, Knowledge__kav> knowledgeList = new Map<Id, Knowledge__kav>(knowledgeArticles);
        Map<Id, Knowledge__kav> draftKnowledgeArticles = new Map<Id, Knowledge__kav>();

        for(Knowledge_Feedback__c feedback : [  SELECT  Knowledge_Article__c,
                                                        Feedback_Category__c,
                                                        Knowledge_Article__r.Title,
                                                        Knowledge_Article__r.Id
                                                FROM    Knowledge_Feedback__c
                                                WHERE   Knowledge_Article__c IN :knowledgeArticles
                                                AND     Feedback_Category__c != null]) {
            try {
                Knowledge__kav knowledge = knowledgeList.get(feedback.Knowledge_Article__c);
                Knowledge__kav draftKnowledgeArticle;

                if (draftKnowledgeArticles.get(feedback.Knowledge_Article__c) != null) {
                    draftKnowledgeArticle = draftKnowledgeArticles.get(feedback.Knowledge_Article__c);
                } else {
                    // Creates a draft article from the online version and returns the new draft master version ID of the article
                    String draftId = KbManagement.PublishingService.editOnlineArticle(knowledge.KnowledgeArticleId, false); //unpublish=false
                    draftKnowledgeArticle = new Knowledge__kav(Id = draftId);
                    draftKnowledgeArticle.Positive_Feedback_Counter__c = 0;
                    draftKnowledgeArticle.Negative_Feedback_Counter__c = 0;
                }

                if (positiveFeedback.contains(feedback.Feedback_Category__c)) {
                    draftKnowledgeArticle.Positive_Feedback_Counter__c += 1;
                } else {
                    draftKnowledgeArticle.Negative_Feedback_Counter__c += 1;
                }
                draftKnowledgeArticles.put(knowledge.Id, draftKnowledgeArticle);
            } catch (Exception e) {
                System.debug('Unable to create draft of article: ' + feedback.Knowledge_Article__r.Id + ': ' + feedback.Knowledge_Article__r.Title + '. Exception: ' + e.getMessage());
            }
        }

        update draftKnowledgeArticles.values();

        for(Knowledge__kav knowledge : knowledgeArticles) {
            //changes PublishStatus from ‘Draft’ to ‘Online’
            try {
                KbManagement.PublishingService.publishArticle(knowledge.KnowledgeArticleId, false); //flagAsNew=false
            } catch (Exception e) {
                // If draft already exists then cannot do this.
                System.debug('Unable to publish article: ' + knowledge.Id + ': ' + knowledge.Title + '. Exception: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}