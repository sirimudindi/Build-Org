/**
 * Created by sdoucette on 12/7/2017.
 */

public with sharing class trac_CasePopulatePlanType {

	@testVisible private static final String PLAN_TYPE_FREE = 'Free';

	public static void execute(List<Case> newList) {
		execute(newList, new Map<Id, Case>());
	}

	public static void execute(List<Case> newList, Map<Id, Case> oldMap) {

		List<Case> casesToProcess = new List<Case>();
		Set<Id> contactIds = new Set<Id>();
		Set<Id> leadIds = new Set<Id>();
		for (Case newCase : newList) {
			Case oldCase = oldMap.get(newCase.Id);
			if (oldCase == null || newCase.ContactId != oldCase.ContactId || newCase.Lead__c != oldCase.Lead__c) {

				// If a Case happens to have both populated Contact is chosen to do the population
				if (newCase.ContactId != null) {
					casesToProcess.add(newCase);
					contactIds.add(newCase.ContactId);
				} else if (newCase.Lead__c != null) {
					casesToProcess.add(newCase);
					leadIds.add(newCase.Lead__c);
				}
			}
		}

		if (!casesToProcess.isEmpty()) {

			Map<Id, Contact> contactMap = new Map<Id, Contact>();
			Map<Id, Lead> leadMap = new Map<Id, Lead>();
			if (!contactIds.isEmpty()) {
				contactMap = new Map<Id, Contact>([SELECT Org_Product_Name__c, productName__c FROM Contact WHERE Id IN :contactIds]);
			}
			if (!leadIds.isEmpty()) {
				leadMap = new Map<Id, Lead>([SELECT Org_Product_Name__c, productName__c FROM Lead WHERE Id IN :leadIds]);
			}

			for (Case c : casesToProcess) {
				Contact parentContact = contactMap.get(c.ContactId);
				Lead parentLead = leadMap.get(c.Lead__c);

				// If a Case happens to have both populated Contact is chosen to do the population
				if (parentContact != null) {
					if (String.isNotBlank(parentContact.Org_Product_Name__c)) {
						c.Plan_Type__c = parentContact.Org_Product_Name__c;
					} else if (String.isNotBlank(parentContact.ProductName__c)) {
						c.Plan_Type__c = parentContact.ProductName__c;
					} else {
						c.Plan_Type__c = PLAN_TYPE_FREE;
					}
				} else if (parentLead != null) {
					if (String.isNotBlank(parentLead.Org_Product_Name__c)) {
						c.Plan_Type__c = parentLead.Org_Product_Name__c;
					} else if (String.isNotBlank(parentLead.ProductName__c)) {
						c.Plan_Type__c = parentLead.ProductName__c;
					} else {
						c.Plan_Type__c = PLAN_TYPE_FREE;
					}
				}
			}
		}
	}
}