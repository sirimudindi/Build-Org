/**
 * @author Steve Doucette, Traction on Demand 
 * @date 2018-07-20
 * @description Handles child CaseMilestones based on Custom Metadata type
 * or if Case is closed then closes all CaseMilestones
 */
public with sharing class trac_CaseAutoCloseMilestones {

	private static DateTime NOW = DateTime.now();

	private static final Map<String, SObjectField> CASE_FIELD_MAP = Case.getSObjectType().getDescribe().fields.getMap();

	public static void execute(List<Case> newList, Map<Id, Case> oldMap) {

		// Get Settings that determine if a milestone closes
		// (other than when Case closes) and map them by Milestone Prefix
		Map<String, Set<String>> settingCaseFieldToMilestonePrefixMap = new Map<String, Set<String>>();
		for (trac_CaseMilestone_Auto_Close_Manager__mdt setting : [
				SELECT Case_Field__c, Milestone_Prefix__c
				FROM trac_CaseMilestone_Auto_Close_Manager__mdt
				WHERE Active__c = TRUE
		]) {
			if (!settingCaseFieldToMilestonePrefixMap.containsKey(setting.Case_Field__c)) {
				settingCaseFieldToMilestonePrefixMap.put(setting.Case_Field__c, new Set<String>());
			}
			settingCaseFieldToMilestonePrefixMap.get(setting.Case_Field__c).add(setting.Milestone_Prefix__c);
		}

		// Handle cases that has just closed
		// OR has a field updated that is one of our active settings
		List<Case> casesToProcess = new List<Case>();
		for (Case c : newList) {
			Case oldCase = oldMap.get(c.Id);
			if (isChanged(c, oldCase, trac_Constants.CASE_IS_CLOSED)) {
				casesToProcess.add(c);
			} else {
				// See if any fields in our settings are updated on case, if so add to list to check milestones later
				for (String settingField : settingCaseFieldToMilestonePrefixMap.keySet()) {
					if (CASE_FIELD_MAP.containsKey(settingField)
							&& isChanged(c, oldCase, settingField)) {
						casesToProcess.add(c);
						break;
					}
				}
			}
		}

		if (!casesToProcess.isEmpty()) {
			// Get all child milestones for the cases we are processing
			List<CaseMilestone> childMilestones = [
					SELECT MilestoneType.Name, CompletionDate, CaseId
					FROM CaseMilestone
					WHERE CaseId IN :casesToProcess
			];

			// Map cases to their child milestones
			Map<Id, List<CaseMilestone>> caseToMilestoneMap = new Map<Id, List<CaseMilestone>>();
			for (CaseMilestone cm : childMilestones) {
				if (!caseToMilestoneMap.containsKey(cm.CaseId)) {
					caseToMilestoneMap.put(cm.CaseId, new List<CaseMilestone>());
				}
				caseToMilestoneMap.get(cm.CaseId).add(cm);
			}

			// Based on these cases and settings find which case milestones to close
			for (Case c : casesToProcess) {
				Case oldCase = oldMap.get(c.Id);
				if (caseToMilestoneMap.containsKey(c.Id)) {
					if (isChanged(c, oldCase, trac_Constants.CASE_IS_CLOSED)) {
						// Update all case milestone to be completed
						for (CaseMilestone cm : caseToMilestoneMap.get(c.Id)) {
							if (cm.CompletionDate == null) {
								cm.CompletionDate = NOW;
							}
						}
					} else {
						// Determine changed fields and close milestones by their prefix (based on settings)
						for (String settingField : settingCaseFieldToMilestonePrefixMap.keySet()) {
							if (CASE_FIELD_MAP.containsKey(settingField)
									&& isChanged(c, oldCase, settingField)) {
								for (CaseMilestone cm : caseToMilestoneMap.get(c.Id)) {
									if (cm.CompletionDate == null
											&& settingCaseFieldToMilestonePrefixMap.get(settingField).contains(cm.MilestoneType.Name.substringBefore('-').trim())) {
										cm.CompletionDate = NOW;
									}
								}
							}
						}
					}
				}
			}
			update childMilestones;
		}
	}

	private static Boolean isChanged(Case c, Case oldCase, String field) {
		return c.get(field) != oldCase.get(field);
	}
}