/**
 * @description Counts the number of AttachedResults records where a given Case has been used as a solution.
 * @author      AFee, Traction on Demand
 * @date        22-Jul-2019
 */
public without sharing class trac_CaseReferenceCounter {

    //called in the INSERT/DELETE/UNDELETE scenario
    public static void execute(List<CoveoV2__CoveoCaseAttachedResult__c> results) {

        Set<Id> caseIds = new Set<Id>();

        //make a list of case Ids that need references recalculated
        for (CoveoV2__CoveoCaseAttachedResult__c result : results) {

            if (result.Reference_Case__c != null) {
                caseIds.add(result.Reference_Case__c);
            }
        }
        if (!caseIds.isEmpty()) {
            countCaseReferences(caseIds);
        }
    }

    //called in the UPDATE scenario
    public static void execute(List<CoveoV2__CoveoCaseAttachedResult__c> results, Map<Id, CoveoV2__CoveoCaseAttachedResult__c> oldResults) {

        //make a list of case Ids that need to be recalculated
        Set<Id> caseIds = new Set<Id>();

        for (CoveoV2__CoveoCaseAttachedResult__c result : results) {
            CoveoV2__CoveoCaseAttachedResult__c oldResult = oldResults.get(result.Id);

            //if lookup changes, we must recalc for both the old and the new record (unless either is null)
            if (result.Reference_Case__c != oldResult.Reference_Case__c) {

                if (result.Reference_Case__c != null) {
                    caseIds.add(result.Reference_Case__c);
                }
                if (oldResult.Reference_Case__c != null) {
                    caseIds.add(oldResult.Reference_Case__c);
                }
            }
        }
        if (!caseIds.isEmpty()) {
            countCaseReferences(caseIds);
        }
    }

    //Count AttachedResults that lookup to these Cases, and stamp the total on each Case.
    private static void countCaseReferences(Set<Id> caseIds) {
        List<CoveoV2__CoveoCaseAttachedResult__c> results = [SELECT Id, Reference_Case__c FROM CoveoV2__CoveoCaseAttachedResult__c WHERE Reference_Case__c IN :caseIds];

        //create a map to summarize reference counts
        Map<Id,Integer> caseCounts = new Map<Id,Integer>();

        //initialize counts to 0 for each Case Id
        for (Id caseId : caseIds) {
            caseCounts.put(caseId, 0);
        }

        //tally up reference counts
        for (CoveoV2__CoveoCaseAttachedResult__c r : results) {
            Integer count = caseCounts.get(r.Reference_Case__c);
            count++;
            caseCounts.put(r.Reference_Case__c, count);
        }

        //update case records contained in the Map
        List<Case> casesToUpdate = new List<Case>();

        for (Id CaseId : caseCounts.keySet()) {
            Case c = new Case(Id=CaseId);
            c.Attached_Reference_Case_Count__c = caseCounts.get(CaseId);
            casesToUpdate.add(c);
        }
        if (!casesToUpdate.IsEmpty()) {
            update casesToUpdate;
        }
    }
}