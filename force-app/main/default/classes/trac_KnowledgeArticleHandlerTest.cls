/**
 * @description Test Class for Knowledge article trigger
 * @author  Heather Purvis, Traction on Demand
 * @date    2020-01-08
 */
@IsTest
private class trac_KnowledgeArticleHandlerTest {
    private static final Integer NUMBER_TO_PUBLISH = Math.min(Integer.valueOf(trac_KnowledgeFeedbackCounter.SETTINGS.Batch_Size__c), 30);
    private static final Integer NUMBER_OF_ARTICLES = NUMBER_TO_PUBLISH + 10;
    private static final String NEGATIVE_FEEDBACK = 'Bad Search Result';
    private static final String POSITIVE_FEEDBACK = 'Helpful';
    private static final String STATUS_APPROVED = 'Approved';
    private static final String STATUS_NEW = 'New';
    private static final Id FAQ_RECORDTYPEID = Knowledge__kav.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Question_Answer_Article').getRecordTypeId();

    @TestSetup
    static void setup() {
        // Create Draft Knowledge articles
        List<Knowledge__kav> knowledgeArticles = new List<Knowledge__kav>();
        for(Integer i = 0; i < NUMBER_OF_ARTICLES; i++) {
            Knowledge__kav ka = new Knowledge__kav();
            ka.RecordTypeId = FAQ_RECORDTYPEID;
            ka.Title = 'trac_KnowledgeFeedbackCounterTest Batch Test ' + i;
            ka.UrlName = 'trac-KnowledgeFeebackCounterTest-Batch-Test-' + i;
            knowledgeArticles.add(ka);
        }
        insert knowledgeArticles;

        // Get Drafts in order to publish
        List<Knowledge__kav> draftKnowledgeArticles = [
                SELECT  Id,
                        KnowledgeArticleId
                FROM    Knowledge__kav
                WHERE   Id IN :knowledgeArticles
        ];

        // Publish a given number of these draft articles
        Integer publishedCount = 0;
        for(Knowledge__kav article : draftKnowledgeArticles) {
            KbManagement.PublishingService.publishArticle(article.KnowledgeArticleId, true);
            publishedCount++;

            if(publishedCount >= NUMBER_TO_PUBLISH) {
                break;
            }
        }

        // Create 1 positive and 2 negative Feedbacks for the articles
        List<Knowledge_Feedback__c> knowledgeFeedback = new List<Knowledge_Feedback__c>();
        for(Knowledge__kav ka : knowledgeArticles) {

            Knowledge_Feedback__c kf_pos = new Knowledge_Feedback__c();
            kf_pos.Knowledge_Article__c = ka.Id;
            kf_pos.Feedback_Category__c = POSITIVE_FEEDBACK;
            kf_pos.Feedback_Status__c = STATUS_APPROVED;
            knowledgeFeedback.add(kf_pos);

            Knowledge_Feedback__c kf_neg = new Knowledge_Feedback__c();
            kf_neg.Knowledge_Article__c = ka.Id;
            kf_neg.Feedback_Category__c = NEGATIVE_FEEDBACK;
            kf_neg.Feedback_Status__c = STATUS_APPROVED;
            knowledgeFeedback.add(kf_neg);

            Knowledge_Feedback__c kf_new = new Knowledge_Feedback__c();
            kf_new.Knowledge_Article__c = ka.Id;
            kf_new.Feedback_Category__c = NEGATIVE_FEEDBACK;
            kf_new.Feedback_Status__c = STATUS_NEW;
            knowledgeFeedback.add(kf_new);
        }
        insert knowledgeFeedback;
    }

    @IsTest
    static void feedbackStaysLinkedAfterRePublish() {
        // Get the KA ID of a published KA with feedback
        List<Knowledge_Feedback__c> kaFeedbacks = [
                SELECT  Id,
                        KnowledgeArticleId__c,
                        Knowledge_Article__c
                FROM    Knowledge_Feedback__c
                LIMIT 1
        ];

        Test.startTest();
        // Create a new draft in order to upversion
        String draftId = KbManagement.PublishingService.editOnlineArticle(kaFeedbacks[0].KnowledgeArticleId__c, false); //unpublish=false

        // Simulate making an edit to draft in order to trigger update - this will happen when the feedback count happens
        Knowledge__kav draftKnowledgeArticle = new Knowledge__kav(Id = draftId);
        draftKnowledgeArticle.Positive_Feedback_Counter__c = 0;
        update draftKnowledgeArticle;

        // Publish this article but do not upversion it
        KbManagement.PublishingService.publishArticle(kaFeedbacks[0].KnowledgeArticleId__c, false);
        Test.stopTest();

        List<Knowledge__kav> onlineKnowledgeArticles = [
                SELECT  Id
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Online'
                AND     KnowledgeArticleId = :kaFeedbacks[0].KnowledgeArticleId__c
        ];

        List<Knowledge_Feedback__c> onlineKaFeedbacks = [
                SELECT  Id,
                        KnowledgeArticleId__c,
                        Knowledge_Article__c
                FROM    Knowledge_Feedback__c
                WHERE   Knowledge_Article__c = :onlineKnowledgeArticles[0].Id
        ];

        System.assertEquals(1, onlineKnowledgeArticles.size(), 'Expected one online version');
        System.assertEquals(3, onlineKaFeedbacks.size(), 'Expected 3 feedbacks linked to new version');
    }

    @IsTest
    static void feedbackStaysLinkedAfterUpversion() {
        // Get the KA ID of a published KA with feedback
        List<Knowledge_Feedback__c> kaFeedbacks = [
                SELECT  Id,
                        KnowledgeArticleId__c,
                        Knowledge_Article__c
                FROM    Knowledge_Feedback__c
                LIMIT 1
        ];

        Test.startTest();
        // Create a new draft in order to upversion
        String draftId = KbManagement.PublishingService.editOnlineArticle(kaFeedbacks[0].KnowledgeArticleId__c, false); //unpublish=false

        // Simulate making an edit to the draft in order to trigger an update - this would happen if a user was creating a new version
        Knowledge__kav draftKnowledgeArticle = new Knowledge__kav(Id = draftId);
        draftKnowledgeArticle.Positive_Feedback_Counter__c = 0;
        update draftKnowledgeArticle;

        // Publish as a new version
        KbManagement.PublishingService.publishArticle(kaFeedbacks[0].KnowledgeArticleId__c, true);
        Test.stopTest();

        List<Knowledge__kav> onlineKnowledgeArticles = [
                SELECT  Id
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Online'
                AND     KnowledgeArticleId = :kaFeedbacks[0].KnowledgeArticleId__c
        ];

        List<Knowledge_Feedback__c> onlineKaFeedbacks = [
                SELECT  Id,
                        KnowledgeArticleId__c,
                        Knowledge_Article__c
                FROM    Knowledge_Feedback__c
                WHERE   Knowledge_Article__c = :onlineKnowledgeArticles[0].Id
        ];

        List<Knowledge__kav> archivedKnowledgeArticles = [
                SELECT  Id
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Archived'
                AND     KnowledgeArticleId = :kaFeedbacks[0].KnowledgeArticleId__c
                AND     IsLatestVersion = False
        ];

        List<Knowledge_Feedback__c> archivedKaFeedbacks = [
                SELECT  Id,
                        KnowledgeArticleId__c,
                        Knowledge_Article__c
                FROM    Knowledge_Feedback__c
                WHERE   Knowledge_Article__c = :archivedKnowledgeArticles[0].Id
        ];

        System.assertEquals(1, onlineKnowledgeArticles.size(), 'Expected one online version');
        System.assertEquals(1, archivedKnowledgeArticles.size(), 'Expected one archived version');
        System.assertEquals(3, onlineKaFeedbacks.size(), 'Expected 3 feedback linked to new version');
        System.assertEquals(0, archivedKaFeedbacks.size(), 'Expected no feedback linked to old version');
    }

    @IsTest
    static void feedbackReLinkedAfterDraftDelete() {
        // Get the KA ID of a published KA with feedback
        List<Knowledge_Feedback__c> kaFeedbacks = [
                SELECT  Id,
                        KnowledgeArticleId__c,
                        Knowledge_Article__c
                FROM    Knowledge_Feedback__c
                LIMIT 1
        ];

        Test.startTest();
        // Create a new draft in order to upversion
        String draftId = KbManagement.PublishingService.editOnlineArticle(kaFeedbacks[0].KnowledgeArticleId__c, false); //unpublish=false

        // Simulate making an edit to the draft in order to trigger an update and link the feedback to it
        Knowledge__kav draftKnowledgeArticle = new Knowledge__kav(Id = draftId);
        draftKnowledgeArticle.Positive_Feedback_Counter__c = 1;
        update draftKnowledgeArticle;

        // Delete Draft article
        KbManagement.PublishingService.deleteDraftArticle(kaFeedbacks[0].KnowledgeArticleId__c);
        Test.stopTest();

        List<Knowledge__kav> onlineKnowledgeArticles = [
                SELECT  Id
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Online'
                AND     KnowledgeArticleId = :kaFeedbacks[0].KnowledgeArticleId__c
        ];

        List<Knowledge_Feedback__c> onlineKaFeedbacks = [
                SELECT  Id,
                        KnowledgeArticleId__c,
                        Knowledge_Article__c
                FROM    Knowledge_Feedback__c
                WHERE   Knowledge_Article__c = :onlineKnowledgeArticles[0].Id
        ];

        List<Knowledge__kav> draftKnowledgeArticles = [
                SELECT  Id
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Draft'
                AND     KnowledgeArticleId = :kaFeedbacks[0].KnowledgeArticleId__c
        ];

        System.assertEquals(1, onlineKnowledgeArticles.size(), 'Expected one online version');
        System.assertEquals(0, draftKnowledgeArticles.size(), 'Expected one archived version');
        System.assertEquals(3, onlineKaFeedbacks.size(), 'Expected no feedback linked to new version');
    }
}