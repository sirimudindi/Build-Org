/**
 * @description Test class for Knowledge Feedback trigger
 * @author  Heather Purvis, Traction on Demand
 * @date    2020-01-08
 */
@IsTest
private class trac_KnowledgeFeedbackHandlerTest {
    private static final String POSITIVE_FEEDBACK = 'Helpful';
    private static final String STATUS_APPROVED = 'Approved';
    private static final Id RECORD_TYPE_ID = [
            SELECT  Id, Name, SobjectType
            FROM    RecordType
            WHERE   SobjectType = 'Knowledge__kav'
            LIMIT 1
    ].Id;

    @TestSetup
    static void setup() {

        // Create Draft Knowledge articles
        Knowledge__kav ka = new Knowledge__kav();
        ka.RecordTypeId = RECORD_TYPE_ID;
        ka.Title = 'trac_KnowledgeFeedbackCounterTest Batch Test';
        ka.UrlName = 'trac-KnowledgeFeebackCounterTest-Batch-Test';
        insert ka;

        // Get Drafts in order to publish
        List<Knowledge__kav> draftKnowledgeArticles = [
                SELECT  Id,
                        KnowledgeArticleId
                FROM    Knowledge__kav
                WHERE   Id = :ka.Id
        ];

        // Publish a given number of these draft articles
        for(Knowledge__kav article : draftKnowledgeArticles) {
            KbManagement.PublishingService.publishArticle(article.KnowledgeArticleId, true);
        }
    }

    @IsTest
    static void idStampingOnFeedback() {
        List<Knowledge__kav> knowledgeArticles = [
                SELECT  Id,
                        KnowledgeArticleId
                FROM    Knowledge__kav
                WHERE   PublishStatus = 'Online'
        ];

        Test.startTest();
        Knowledge_Feedback__c kf_pos = new Knowledge_Feedback__c();
        kf_pos.Knowledge_Article__c = knowledgeArticles[0].Id;
        kf_pos.Feedback_Category__c = POSITIVE_FEEDBACK;
        kf_pos.Feedback_Status__c = STATUS_APPROVED;
        insert kf_pos;
        Test.stopTest();

        List<Knowledge_Feedback__c> feedback = [
                SELECT  Id,
                        KnowledgeArticleId__c,
                        Knowledge_Article__c
                FROM    Knowledge_Feedback__c
        ];

        knowledgeArticles = [
                SELECT  Id,
                        KnowledgeArticleId
                FROM    Knowledge__kav
                WHERE   Id = :feedback[0].Knowledge_Article__c
        ];

        System.assertNotEquals(null, feedback[0].KnowledgeArticleId__c,
                'Expected a value to be stamped onto feedback in order to reparent');
        System.assertEquals(knowledgeArticles[0].KnowledgeArticleId, feedback[0].KnowledgeArticleId__c,
                'Expected base Knowledge Article Id to be stamped onto feedback in order to reparent');
    }
}