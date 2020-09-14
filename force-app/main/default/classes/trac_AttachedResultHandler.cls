/**
 * @description Handler class for the CoveoV2__CoveoCaseAttachedResult__c trigger.
 * @author      AFee, Traction on Demand
 * @date        22-Jul-2019
 *
 */
public class trac_AttachedResultHandler extends trac_TriggerHandlerBase {

    private List<CoveoV2__CoveoCaseAttachedResult__c> newResultsList = (List<CoveoV2__CoveoCaseAttachedResult__c>) newRecordsList;
    private List<CoveoV2__CoveoCaseAttachedResult__c> oldResultsList = (List<CoveoV2__CoveoCaseAttachedResult__c>) oldRecordsList;
    private Map<Id, CoveoV2__CoveoCaseAttachedResult__c> oldResultsMap = (Map<Id, CoveoV2__CoveoCaseAttachedResult__c>) oldRecordsMap;

    public override void handleAfterInsert() {
        trac_CaseReferenceCounter.execute(newResultsList);
    }

    public override void handleAfterUpdate() {
        trac_CaseReferenceCounter.execute(newResultsList, oldResultsMap);
    }

    public override void handleAfterDelete() {
        trac_CaseReferenceCounter.execute(oldResultsList);
    }

    public override void handleAfterUndelete() {
        trac_CaseReferenceCounter.execute(newResultsList);
    }

}