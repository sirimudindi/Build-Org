/**
 * @author Steve Doucette, Traction on Demand 
 * @date 2018-07-20
 */

@IsTest
private class trac_CaseAutoCloseMilestonesTest {

	private static Case c;

	private static void setup() {
		trac_TestUtils.CollaboratorPackage cp = trac_TestUtils.setupCollaboratorPackage();

		Id entProcessId = [
				SELECT Id
				FROM SlaProcess
				WHERE IsActive = TRUE AND SObjectType = 'Case'
				LIMIT 1
		].Id;

		Entitlement e = cp.entitlement;
		e.SlaProcessId = entProcessId;
		update e;

		c = trac_TestUtils.createCase('New', 'Email', 'Test@test.com', 'Test');
		c.AccountId = cp.collaboratorAccount.Id;
		c.EntitlementId = e.Id;
		insert c;
	}

	@IsTest
	static void testCaseClose() {
		setup();
		c.Status = trac_Constants.CASE_STATUS_CLOSED;
		update c;

		List<CaseMilestone> cms = [
				SELECT IsCompleted, CaseId
				FROM CaseMilestone
				WHERE CaseId = :c.Id
		];
		for (CaseMilestone cm : cms) {
			System.assertEquals(true, cm.IsCompleted);
		}
	}

	@IsTest
	static void testCustomMetadataFlow() {
		setup();
		List<trac_CaseMilestone_Auto_Close_Manager__mdt> settings = [
				SELECT Case_Field__c, Milestone_Prefix__c
				FROM trac_CaseMilestone_Auto_Close_Manager__mdt
				WHERE Active__c = TRUE
		];
		for (trac_CaseMilestone_Auto_Close_Manager__mdt setting : settings) {
			c.put(setting.Case_Field__c, DateTime.now());
		}
		update c;

		List<CaseMilestone> cms = [
				SELECT IsCompleted
				FROM CaseMilestone
				WHERE CaseId = :c.Id
		];
		Boolean foundCompletedMilestone = false;
		for (CaseMilestone cm : cms) {
			if (cm.IsCompleted) {
				foundCompletedMilestone = true;
			}
		}
		System.assertEquals(true, foundCompletedMilestone);
	}
}