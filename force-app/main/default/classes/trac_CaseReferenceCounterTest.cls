/**
 * @description Test class for the Coveo AttachedResult trigger, handler class, and trac_CaseReferenceCounter
 * @author      AFee, Traction on Demand
 * @date        22-Jul-2019
 */

@IsTest
public class trac_CaseReferenceCounterTest {

    private static final Date TODAY = Date.today();

    private static final String NAME_TEST = 'Test';
    private static final String EMAIL_TEST = 'Test@smartsheet.test.com';

    private static String OPEN_CASE_SUBJECT = 'Open Case Tier3';
    private static String CLOSED_CASE_SUBJECT1 = 'Closed Case Tier3';
    private static String CLOSED_CASE_SUBJECT2 = 'Closed Case Tier2';

    @TestSetup
    static void setup() {

        //Note: setting up an Account & Entitlement are pre-requirements for inserting a new Case.
        Account acct = trac_TestUtils.createAccount();
        acct.Name = trac_Constants.THIS_MONTH_ACCOUNT_NAME;
        insert acct;

        SlaProcess sla = [
                SELECT Id
                FROM SlaProcess
                WHERE IsActive = TRUE
                LIMIT 1
        ];

        Entitlement entitlement = trac_TestUtils.createEntitlement(acct);
        entitlement.Name = trac_TestUtils.DEFAULT_ENTITLEMENT_NAME;
        entitlement.SlaProcessId = sla.Id;
        entitlement.StartDate = TODAY.addDays(-1);
        entitlement.EndDate = TODAY.addYears(1);
        insert entitlement;

        //Now we can set up the data for these tests
        Case openCase = trac_TestUtils.createCase(trac_Constants.CASE_STATUS_NEW, trac_Constants.CASE_ORIGIN_PHONE, EMAIL_TEST, NAME_TEST);
        openCase.Subject = OPEN_CASE_SUBJECT;
        openCase.Account = acct;
        insert openCase;

        Case solutionCase1 = trac_TestUtils.createCase(trac_Constants.CASE_STATUS_CLOSED, trac_Constants.CASE_ORIGIN_PHONE, EMAIL_TEST, NAME_TEST);
        solutionCase1.Subject = CLOSED_CASE_SUBJECT1;
        solutionCase1.Account = acct;
        solutionCase1.Attached_Reference_Case_Count__c = 0;
        insert solutionCase1;

        Case solutionCase2 = trac_TestUtils.createCase(trac_Constants.CASE_STATUS_CLOSED, trac_Constants.CASE_ORIGIN_PHONE, EMAIL_TEST, NAME_TEST);
        solutionCase2.Subject = CLOSED_CASE_SUBJECT2;
        solutionCase2.Account = acct;
        solutionCase2.Attached_Reference_Case_Count__c = 0;
        insert solutionCase2;
    }

    /**
    *  Test that inserting AttachedResult referencing a Case solution will
    *  increment the caseCount field on the Case record.
    */
    @IsTest
    static void attachedResultInsertTest() {
        Case openCase = [SELECT Id FROM Case WHERE Subject=:OPEN_CASE_SUBJECT LIMIT 1];
        Case closedCase = [SELECT Id FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT1 LIMIT 1];

        //insert an AttachedResult for the open Case, referencing the solution Case.
        CoveoV2__CoveoCaseAttachedResult__c ar = trac_TestUtils.createAttachedResult(openCase);
        ar.Reference_Case__c = closedCase.Id;

        test.startTest();
        insert ar;
        test.stopTest();

        //verify that the caseCount field was incremented on the solution Case record
        Case solutionCase = [SELECT Id, Attached_Reference_Case_Count__c FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT1 LIMIT 1];
        System.assertEquals(1, solutionCase.Attached_Reference_Case_Count__c, 'Case Count on the solution Case should be set to 1 after insert');
    }


    /**
    *  Test that deleting an AttachedResult referencing a Case solution will
    *  decrement the caseCount field on the Case record.
    */
    @IsTest
    static void attachedResultDeleteTest() {
        Case openCase = [SELECT Id FROM Case WHERE Subject=:OPEN_CASE_SUBJECT LIMIT 1];
        Case closedCase = [SELECT Id FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT1 LIMIT 1];

        //insert an AttachedResult for the open Case, referencing the solution Case.
        CoveoV2__CoveoCaseAttachedResult__c ar = trac_TestUtils.createAttachedResult(openCase);
        ar.Reference_Case__c = closedCase.Id;
        insert ar;   //insert trigger will increase the ref count on the solution case

        test.startTest();
        delete ar;
        test.stopTest();

        //verify that the caseCount field was decremented on the solution Case record
        Case solutionCase = [SELECT Id, Attached_Reference_Case_Count__c FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT1 LIMIT 1];
        System.assertEquals(0, solutionCase.Attached_Reference_Case_Count__c, 'Case Count on the solution Case should be set to 0 after delete');
    }


    /**
    *  Test that undeleting an AttachedResult referencing a Case solution will
    *  increment the caseCount field on the Case record (undelete should behave just like an insert).
    */
    @IsTest
    static void attachedResultUndeleteTest() {
        Case openCase = [SELECT Id FROM Case WHERE Subject=:OPEN_CASE_SUBJECT LIMIT 1];
        Case closedCase = [SELECT Id FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT1 LIMIT 1];

        //insert an AttachedResult for the open Case, referencing the solution Case.
        CoveoV2__CoveoCaseAttachedResult__c ar = trac_TestUtils.createAttachedResult(openCase);
        ar.Reference_Case__c = closedCase.Id;
        insert ar;   //insert trigger will increase the ref count on the solution case
        delete ar;   //delete trigger will decrease the ref count on the solution case

        //verify that the caseCount field is currently 0 on the solution Case record
        Case solutionCase = [SELECT Id, Attached_Reference_Case_Count__c FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT1 LIMIT 1];
        System.assertEquals(0, solutionCase.Attached_Reference_Case_Count__c);

        test.startTest();
        undelete ar;
        test.stopTest();

        //verify that the caseCount field was incremented on the solution Case record
        solutionCase = [SELECT Id, Attached_Reference_Case_Count__c FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT1 LIMIT 1];
        System.assertEquals(1, solutionCase.Attached_Reference_Case_Count__c, 'Case Count on the solution Case should be set to 1 after undelete');
    }


    /**
    *  Test that changing the solution Reference_Case__c lookup on an AttachedResult record will
    *  result in decrementing the caseCount field on the solution case record.
    */
    @IsTest
    static void attachedResultUpdateTest() {
        Case openCase = [SELECT Id FROM Case WHERE Subject=:OPEN_CASE_SUBJECT LIMIT 1];
        Case closedCase1 = [SELECT Id FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT1 LIMIT 1];
        Case closedCase2 = [SELECT Id FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT2 LIMIT 1];

        //insert an AttachedResult for the open Case, referencing the solution Case #1.
        CoveoV2__CoveoCaseAttachedResult__c ar = trac_TestUtils.createAttachedResult(openCase);
        ar.Reference_Case__c = closedCase1.Id;
        insert ar;

        //update the AttachedResult and change the Reference_Case__c lookup to solution Case #2.
        test.startTest();
        ar.Reference_Case__c = closedCase2.Id;
        update ar;
        test.stopTest();

        //verify that the caseCount field was decremented on solution case #1
        Case solutionCase1 = [SELECT Id, Attached_Reference_Case_Count__c FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT1 LIMIT 1];
        System.assertEquals(0, solutionCase1.Attached_Reference_Case_Count__c, 'Case Count on the solution Case should be set to 0 after update');

        //verify that the caseCount field was incremented on solution case #2
        Case solutionCase2 = [SELECT Id, Attached_Reference_Case_Count__c FROM Case WHERE Subject=:CLOSED_CASE_SUBJECT2 LIMIT 1];
        System.assertEquals(1, solutionCase2.Attached_Reference_Case_Count__c, 'Case Count on the solution Case should be set to 1 after update');
    }

}