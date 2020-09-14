/**
 * Created by sdoucette on 12/7/2017.
 */

public with sharing class trac_Case extends trac_TriggerHandlerBase {
	private List<Case> newCasesList = (List<Case>) newRecordsList;
	private Map<Id, Case> oldCasesMap = (Map<Id, Case>) oldRecordsMap;

	public override void handleBeforeInsert() {
		trac_CasePopulatePlanType.execute(newCasesList);
	}

	public override void handleAfterInsert() {
		trac_CaseEntitlementAssociation.execute(newCasesList);
	}

	public override void handleBeforeUpdate() {
		trac_CaseAutoCloseMilestones.execute(newCasesList, oldCasesMap);
		trac_CasePopulatePlanType.execute(newCasesList, oldCasesMap);
	}

	public override void handleAfterUpdate() {
		trac_CaseEntitlementAssociation.execute(newCasesList, oldCasesMap);
	}
}