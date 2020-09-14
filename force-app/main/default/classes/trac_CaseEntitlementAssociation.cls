/**
 * This class will automatically assign an Entitlement to a Case based on parent Contact or Leads Plan.
 * NOTE: Must be in AFTER context as lead/contact fields are stamped via other methods
 *
 * @author Steve Doucette, Traction on Demand
 * @date 2018-09-13
**/
public without sharing class trac_CaseEntitlementAssociation {

	/**
	 * @description Stamp the Entitlement of associated Plan onto Case
	 * @author Steve Doucette, Traction on Demand
	 * @param cases Case record to process
	 * @param oldCases Old values for case records
	 */
	public static void execute(List<case> cases, Map<Id, Case> oldCases) {
		Set<Id> accIds = new Set<Id>();
		List<Case> casesToProcess = new List<Case>();

		Map<Id, Contract> contractByCaseId = new Map<Id, Contract>();
		for (Case c : cases) {
			Case oldCase = oldCases.get(c.Id);
			if ((c.Lead__c != oldCase.Lead__c || c.ContactId != oldCase.ContactId)
					&& (c.Lead__c != null || c.ContactId != null)) {
				casesToProcess.add(c);
			}
		}
		if (!casesToProcess.isEmpty()) {
			execute(casesToProcess);
		}
	}

	/**
	*  @description Stamp the Entitlement of associated Plan onto Case
	*  @author Steve Doucette, Traction on Demand
 	*  @date 2018-09-13
	*  @param cases Case records to process
	*/
	public static void execute(List<case> cases) {
		// Need parent info from Cases so we need to re-query current list
		List<Case> casesWithPlanIds = [
				SELECT Id, Lead__r.Plan__c, Contact.Plan__c, EntitlementId,
						Lead__r.Organization_Roles__c, Lead__r.ProductName__c,
						Contact.Organization_Roles__c, Contact.ProductName__c,
						User_Lookup__c
				FROM Case
				WHERE Id IN :cases
		];

		// Get plan ids for query
		Map<String, Id> plansIdByEmail = new Map<String, Id>();
		Set<Id> planIds = new Set<Id>();
		Set<String> usersEmail = new Set<String>();
		for (Case c : casesWithPlanIds) {
			planIds.add(c.Contact.Plan__c);
			planIds.add(c.Lead__r.Plan__c);
			if (c.User_Lookup__c != null) {
				usersEmail.add(c.User_Lookup__c);
			}
		}

		for (Contact c : [ SELECT Email, Plan__c FROM Contact WHERE Email IN :usersEmail ]) {
			if (c.Plan__c != null) {
				planIds.add(c.Plan__c);
				plansIdByEmail.put(c.Email, c.Plan__c);
			}
		}

		// Query plans and their assets to gather what possible entitlements we will use
		Map<Id, Contract> plans = new Map<Id, Contract>();
		Map<Id, Id> entitlementTemplateByProduct = new Map<Id, Id>();
		Map<Id, Id> slaProcessByTemplate = new Map<Id, Id>();
		Map<Id, Id> activeEntitlementsBySLAProcessId = new Map<Id, Id>();

		if (!planIds.isEmpty()) {
			plans = new Map<Id, Contract>([
					SELECT Id, (
							SELECT Id, Product2Id
							FROM SKUs__r
							WHERE Status = :trac_Constants.ASSET_STATUS_ACTIVE
							ORDER BY Product2.Entitlement_Ranking__c ASC
					)
					FROM Contract
					WHERE Id IN :planIds
			]);

			// Gather Product ids to find ProductEntitlementTemplate records
			Set<Id> productIds = new Set<Id>();
			Set<Id> assetIds = new Set<Id>();
			for (Contract c : plans.values()) {
				for (Asset a : c.SKUs__r) {
					productIds.add(a.Product2Id);
					assetIds.add(a.Id);
				}
			}

			// Query ProductEntitlementTemplate records to find entitlements associated to each product
			// (Uncertain as to why in SOQL EntitlementTemplate is an invalid relationship for ProductEntitlementTemplate
			// as well as SlaProcess for EntitlementTemplate)
			if (!productIds.isEmpty()) {
				for (ProductEntitlementTemplate pet : [
						SELECT Id, Product2Id, EntitlementTemplateId
						FROM ProductEntitlementTemplate
						WHERE Product2Id IN :productIds AND EntitlementTemplateId != NULL
				]) {
					entitlementTemplateByProduct.put(pet.Product2Id, pet.EntitlementTemplateId);
				}

				if (!entitlementTemplateByProduct.isEmpty()) {
					for (EntitlementTemplate et : [
							SELECT Id, SlaProcessId
							FROM EntitlementTemplate
							WHERE Id IN :entitlementTemplateByProduct.values()
					]) {
						slaProcessByTemplate.put(et.Id, et.SlaProcessId);
					}

					// Finally query entitlements and map by plan for case stamping
					if (!slaProcessByTemplate.isEmpty()) {
						for (Entitlement e : [
								SELECT Id, SlaProcessId
								FROM Entitlement
								WHERE SlaProcessId IN :slaProcessByTemplate.values()
								AND Status = :trac_Constants.ENTITLEMENT_STATUS_ACTIVE
								AND AssetId IN :assetIds
						]) {
							activeEntitlementsBySLAProcessId.put(e.SlaProcessId, e.Id);
						}
					}
				}
			}
		}

		// Determine cases entitlement
		// ASSUMPTION: Products to Entitlements is a 1 to 1 relationship
		List<Case> collaboratorCases = new List<Case>();
		for (Case c : casesWithPlanIds) {
			c.EntitlementId = null; // Reset each case to so they go through the process to ensure correct entitlement is stamped
			Contract plan;
			if (c.Contact.Plan__c != null) {
				plan = plans.get(c.Contact.Plan__c);
			} else if (c.Lead__r.Plan__c != null) {
				plan = plans.get(c.Lead__r.Plan__c);
			} else if (c.User_Lookup__c != null && plansIdByEmail.get(c.User_Lookup__c) != null) {
				Id planId = plansIdByEmail.get(c.User_Lookup__c);
				plan = plans.get(planId);
			}

			if (plan != null) {
				// Cycle through the related assets until we find the highest ranking active entitlement (if any)
				for (Asset a : plan.SKUs__r) {
					if (entitlementTemplateByProduct.containsKey(a.Product2Id)) {
						Id templateId = entitlementTemplateByProduct.get(a.Product2Id);
						if (slaProcessByTemplate.containsKey(templateId)) {
							Id entitlementId = slaProcessByTemplate.get(templateId);
							if (activeEntitlementsBySLAProcessId.containsKey(entitlementId)) {
								c.EntitlementId = activeEntitlementsBySLAProcessId.get(entitlementId);
								break;
							}
						}
					}
				}
			}

			// If we couldn't find an entitlement for case put under collaborator logic
			if (c.EntitlementId == null) {
				collaboratorCases.add(c);
			}
		}

		if (!collaboratorCases.isEmpty()) {
			trac_CaseNewCollaborator.execute(collaboratorCases);
		}
		update casesWithPlanIds;
	}
}