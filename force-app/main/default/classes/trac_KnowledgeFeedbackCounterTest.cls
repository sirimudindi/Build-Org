/**
 * @description Test class for Knowledge Feedback Counter job
 * @author  Heather Purvis, Traction on Demand
 * @date    2019-12-17
 */
@IsTest
private class trac_KnowledgeFeedbackCounterTest {
    private static final Integer NUMBER_TO_PUBLISH = Math.min(Integer.valueOf(trac_KnowledgeFeedbackCounter.SETTINGS.Batch_Size__c), 30);
    private static final Integer NUMBER_OF_ARTICLES = NUMBER_TO_PUBLISH + 10;
    private static final String NEGATIVE_FEEDBACK = 'Bad Search Result';
    private static final String POSITIVE_FEEDBACK = 'Helpful';
    private static final String STATUS_APPROVED = 'Approved';
    private static final String STATUS_NEW = 'New';
    private static final Id FAQ_RECORDTYPEID = Knowledge__kav.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Question_Answer_Article').getRecordTypeId();

    @TestSetup
    static void testSetup() {
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
    static void testSchedule() {
        String jobId;

        Test.startTest();
        jobId = System.schedule('Test Knowledge Feedback Counter', trac_TestUtils.TEST_CRONSTRING, new trac_KnowledgeFeedbackCounter());
        Test.stopTest();

        System.assert(String.isNotBlank(jobId), 'Something went wrong with scheduling, Job ID is null.');
    }

    @IsTest
    static void testFeedbackCounting() {
        Test.startTest();
        Database.executeBatch(new trac_KnowledgeFeedbackCounter());
        Test.stopTest();

        List<Knowledge__kav> knowledgeArticles = [
                SELECT  Id,
                        Positive_Feedback_Counter__c,
                        Negative_Feedback_Counter__c
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Online'
        ];

        System.assertEquals(1, knowledgeArticles[0].Positive_Feedback_Counter__c, 'Expected one positive feedback');
        System.assertEquals(2, knowledgeArticles[0].Negative_Feedback_Counter__c, 'Expected two negative feedbacks');
    }

    @IsTest
    static void testFeedbackBatching() {
        Test.startTest();
        Database.executeBatch(new trac_KnowledgeFeedbackCounter(), NUMBER_TO_PUBLISH);
        Test.stopTest();

        List<Knowledge__kav> knowledgeArticles = [
                SELECT  Id,
                        Positive_Feedback_Counter__c,
                        Negative_Feedback_Counter__c
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Online'
                AND     Positive_Feedback_Counter__c > 0
        ];

        // Cannot run batches in test. Batch number must be equal to the number of records returned in iterable
        System.assertEquals(NUMBER_TO_PUBLISH, knowledgeArticles.size(), 'Expected ' + NUMBER_TO_PUBLISH + ' knowledge articles to have positive feedback');
    }

    @IsTest
    static void testOpenDraftException() {
        // Create a new draft knowledge article
        Knowledge__kav knowledgeArticle = new Knowledge__kav();
        knowledgeArticle.RecordTypeId = FAQ_RECORDTYPEID;
        knowledgeArticle.Title = 'trac_KnowledgeFeedbackCounterTest Batch Test';
        knowledgeArticle.UrlName = 'trac-KnowledgeFeebackCounterTest-Batch-Test';
        insert knowledgeArticle;

        Knowledge__kav draftKnowledgeArticle = [
                SELECT  Id,
                        KnowledgeArticleId
                FROM    Knowledge__kav
                WHERE   Id = :knowledgeArticle.Id
        ];

        // Publish as a new version
        KbManagement.PublishingService.publishArticle(draftKnowledgeArticle.KnowledgeArticleId, true);

        // Create 1+ and 1- Feedback for the article
        List<Knowledge_Feedback__c> knowledgeFeedback = new List<Knowledge_Feedback__c>();

        Knowledge_Feedback__c kf_pos = new Knowledge_Feedback__c();
        kf_pos.Knowledge_Article__c = knowledgeArticle.Id;
        kf_pos.Feedback_Category__c = POSITIVE_FEEDBACK;
        kf_pos.Feedback_Status__c = STATUS_APPROVED;
        knowledgeFeedback.add(kf_pos);

        Knowledge_Feedback__c kf_neg = new Knowledge_Feedback__c();
        kf_neg.Knowledge_Article__c = knowledgeArticle.Id;
        kf_neg.Feedback_Category__c = NEGATIVE_FEEDBACK;
        kf_neg.Feedback_Status__c = STATUS_APPROVED;
        knowledgeFeedback.add(kf_neg);

        insert knowledgeFeedback;

        knowledgeArticle = [
                SELECT  Id,
                        KnowledgeArticleId
                FROM    Knowledge__kav
                WHERE   Id = :knowledgeArticle.Id
        ];

        // Create new draft for this published article
        KbManagement.PublishingService.editOnlineArticle(knowledgeArticle.KnowledgeArticleId, false); //unpublish=false

        Test.startTest();
        Database.executeBatch(new trac_KnowledgeFeedbackCounter());
        Test.stopTest();

        List<Knowledge__kav> knowledgeArticlesWithCountedFeedback = [
                SELECT  Id,
                        Positive_Feedback_Counter__c,
                        Negative_Feedback_Counter__c
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Online'
                AND     Positive_Feedback_Counter__c > 0
                AND     Negative_Feedback_Counter__c > 0
        ];

        // Cannot update feedback count if a draft is open.
        System.assertEquals(NUMBER_TO_PUBLISH, knowledgeArticlesWithCountedFeedback.size(), 'Expected ' + NUMBER_TO_PUBLISH + ' knowledge ' +
                'articles to have positive feedback as you cannot update an article with a draft');
    }

    @IsTest
    static void testFeedbackLinkedAfterCount() {
        Test.startTest();
        Database.executeBatch(new trac_KnowledgeFeedbackCounter());
        Test.stopTest();

        List<Knowledge__kav> ka = [
                SELECT  Id,
                        KnowledgeArticleId
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Online'
                AND     Positive_Feedback_Counter__c = 1
                ORDER BY CreatedDate Desc
                LIMIT 1
        ];

        List<Knowledge_Feedback__c> kaFeedbacks = [
                SELECT  Id,
                        KnowledgeArticleId__c,
                        Knowledge_Article__c
                FROM    Knowledge_Feedback__c
                WHERE   KnowledgeArticleId__c = :ka[0].KnowledgeArticleId
                OR      Knowledge_Article__c = :ka[0].Id
        ];

        System.assertEquals(3, kaFeedbacks.size(), 'Expected three feedbacks on KA to be linked after feedback count');
        System.assertEquals(ka[0].KnowledgeArticleId, kaFeedbacks[0].KnowledgeArticleId__c, 'Expected correct KA Id to be stamped on feedback');
        System.assertEquals(ka[0].Id, kaFeedbacks[0].Knowledge_Article__c, 'Expected correct KA version to be linked to feedback');
    }

    @IsTest
    static void testRunningBatchTwice() {
        Test.startTest();
        Database.executeBatch(new trac_KnowledgeFeedbackCounter());
        Database.executeBatch(new trac_KnowledgeFeedbackCounter());
        Test.stopTest();

        List<Knowledge__kav> knowledgeArticles = [
                SELECT  Id,
                        Positive_Feedback_Counter__c,
                        Negative_Feedback_Counter__c
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Online'
        ];

        System.assertEquals(1, knowledgeArticles[0].Positive_Feedback_Counter__c, 'Expected one positive feedback');
        System.assertEquals(2, knowledgeArticles[0].Negative_Feedback_Counter__c, 'Expected two negative feedbacks');
    }
}