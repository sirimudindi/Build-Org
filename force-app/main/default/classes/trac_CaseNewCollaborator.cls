/**
 * @author Steve Doucette, Traction on Demand 
 * @date 2018-08-14
 *
 * @description Any cases that come in and can't be associated to some entitlement will get the default Collaborator Entitlement
 */
public without sharing class trac_CaseNewCollaborator {

	private static List<Role_Product_Entitlement_Association__mdt> roleProductEntitlementAssociationsSettings;
	private static Map<String, Id> entitlementIdByName;

	private static Map<String, String> roleProductEntitlementAssociationsMap;

	private static final String NO_ACCOUNT_FOUND_ERROR_PREFIX = 'No Collaborator Account found. '
			+ 'Set an account for this case or ensure that there is a Collaborator Account for this month Named: ';
	private static final String NO_ENTITLEMENT_THIS_MONTH_FOUND_ERROR = 'This months Collaborator Account needs an Entitlement';
	private static final String NO_ENTITLEMENT_LAST_MONTH_FOUND_ERROR = 'Last months Collaborator Account needs an Entitlement';
	private static final String NO_DEFAULT_ENTITLEMENT_SETTING_ERROR = 'No default Entitlement found. Please verify the Role / Product Entitlement Association settings '
			+ 'are correct and that this months Account has the default Entitlement';

	private static final String DEFAULT_ENTITLEMENT_NAME;

	static {
		roleProductEntitlementAssociationsSettings = [
				SELECT DeveloperName, Entitlement__c, Org_Role__c, Product_Name__c, Ranking__c
				FROM Role_Product_Entitlement_Association__mdt
				ORDER BY Ranking__c ASC
		];
		roleProductEntitlementAssociationsMap = new Map<String, String>();
		for (Role_Product_Entitlement_Association__mdt setting : roleProductEntitlementAssociationsSettings) {
			if (setting.DeveloperName != trac_Constants.DEFAULT_NAME) {
				roleProductEntitlementAssociationsMap.put(setting.Org_Role__c + ' ' + setting.Product_Name__c, setting.Entitlement__c);
			} else {
				DEFAULT_ENTITLEMENT_NAME = setting.Entitlement__c;
			}
		}
		if (DEFAULT_ENTITLEMENT_NAME == null) {
			throw new NoDefaultEntitlementException(NO_DEFAULT_ENTITLEMENT_SETTING_ERROR);
		}
	}

	// Exceptions
	public class NoAccountsFoundException extends Exception {
	}

	public class NoEntitlementsOnCollaboratorAccountException extends Exception {
	}

	public class NoDefaultEntitlementException extends Exception {
	}

	// Grab current and last months collaborator account
	private static Account thisMonthsAccount;
	private static Account lastMonthsAccount;
	static {
		List<Account> monthlyAccounts = [
				SELECT Id, Name, (
						SELECT Id, AccountId, Name
						FROM Entitlements
				)
				FROM Account
				WHERE Name = :trac_Constants.THIS_MONTH_ACCOUNT_NAME OR Name = :trac_Constants.LAST_MONTH_ACCOUNT_NAME
		];

		// Determine (if any) accounts is this months collaborator account and last months collaborator account
		for (Account acc : monthlyAccounts) {
			if (acc.Name == trac_Constants.THIS_MONTH_ACCOUNT_NAME) {
				thisMonthsAccount = acc;
			} else if (acc.Name == trac_Constants.LAST_MONTH_ACCOUNT_NAME) {
				lastMonthsAccount = acc;
			}
		}
	}

	public static void execute(List<Case> newList) {
		if (thisMonthsAccount == null && lastMonthsAccount == null) {
			throw new NoAccountsFoundException(NO_ACCOUNT_FOUND_ERROR_PREFIX + trac_Constants.THIS_MONTH_ACCOUNT_NAME);
		} else {
			if (thisMonthsAccount == null && lastMonthsAccount != null) {
				if (lastMonthsAccount.Entitlements.isEmpty()) {
					throw new NoEntitlementsOnCollaboratorAccountException(NO_ENTITLEMENT_LAST_MONTH_FOUND_ERROR);
				}
				/*
					Clone last months account and entitlement and rename, use this account for this Case.
					 This account will be used for future collaborator cases this month
				 */
				thisMonthsAccount = lastMonthsAccount.clone(false, true, true, true);
				thisMonthsAccount.Name = trac_Constants.THIS_MONTH_ACCOUNT_NAME;
				insert thisMonthsAccount;

				// Clone, insert, and link last months entitlements to new account
				Date startOfMonth = Date.today().toStartOfMonth();
				List<Entitlement> thisMonthsEntitlements = new List<Entitlement>();
				for (Entitlement e : lastMonthsAccount.Entitlements) {
					Entitlement newEntitlement = e.clone(false, true, true, true);
					newEntitlement.AccountId = thisMonthsAccount.Id;
					newEntitlement.Name = e.Name;
					newEntitlement.StartDate = startOfMonth;
					newEntitlement.EndDate = startOfMonth.addMonths(1).addDays(-1);
					thisMonthsEntitlements.add(newEntitlement);
				}
				insert thisMonthsEntitlements;
			}

			// Map entitlements by name
			if (entitlementIdByName == null) {
				entitlementIdByName = new Map<String, Id>();
				for (Entitlement e : [
						SELECT Id, Name
						FROM Entitlement
						WHERE AccountId = :thisMonthsAccount.Id
				]) {
					entitlementIdByName.put(e.Name, e.Id);
				}
			}

			// Link new cases to this months collaborator account
			for (Case c : newList) {
				if (thisMonthsAccount.Entitlements.isEmpty()) {
					throw new NoEntitlementsOnCollaboratorAccountException(NO_ENTITLEMENT_THIS_MONTH_FOUND_ERROR);
				}

				// Go through each Role_Product_Entitlement_Association__mdt (in ascending order by rank)
				// to determine if any entitlement other than default should be stamped on case
				List<String> caseAssociatedRoles = new List<String>();
				if (c.Contact.Organization_Roles__c != null) {
					caseAssociatedRoles = c.Contact.Organization_Roles__c.split(';');
				} else if (c.Lead__r.Organization_Roles__c != null) {
					caseAssociatedRoles = c.Lead__r.Organization_Roles__c.split(';');
				}
				if (!caseAssociatedRoles.isEmpty()) {
					// Trim any whitespace away
					for (Integer i = caseAssociatedRoles.size() - 1; i >= 0; i--) {
						if (String.isNotBlank(caseAssociatedRoles[i])) {
							caseAssociatedRoles[i] = caseAssociatedRoles[i].trim();
						} else {
							caseAssociatedRoles.remove(i);
						}
					}
					for (Role_Product_Entitlement_Association__mdt rpea : roleProductEntitlementAssociationsSettings) {
						if ((c.Contact.ProductName__c == rpea.Product_Name__c || c.Lead__r.ProductName__c == rpea.Product_Name__c)
								&& caseAssociatedRoles.contains(rpea.Org_Role__c)) {
							// If associated role contains metadata's Org Role and matches associated Product then assign entitlement
							c.EntitlementId = entitlementIdByName.get(rpea.Entitlement__c);
							break;
						}
					}
				}

				// If no entitlement still, use default
				if (c.EntitlementId == null) {
					if (!entitlementIdByName.containsKey(DEFAULT_ENTITLEMENT_NAME)) {
						throw new NoDefaultEntitlementException(NO_DEFAULT_ENTITLEMENT_SETTING_ERROR);
					}
					c.EntitlementId = entitlementIdByName.get(DEFAULT_ENTITLEMENT_NAME);
				}
			}
		}
	}
}