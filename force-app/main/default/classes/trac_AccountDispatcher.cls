/**
 * Account Dispatcher class
 *
 * @author Sergei Dobrianski - sdobrianski@tractionondemand.com
**/
public without sharing class trac_AccountDispatcher extends trac_Dispatcher {
	List<Account> oldAccounts;
	List<Account> newAccounts;

	Map<Id, Account> oldMap;
	Map<Id, Account> newMap;

	private static trac_AccountDispatcher accDispatcher;

	public static final String AFTER_INSERT_DOMAIN_ASSIGNMENT = 'Domain Assignment - AFTER INSERT';
	public static final String AFTER_UPDATE_DOMAIN_ASSIGNMENT = 'Domain Assignment - AFTER UPDATE';

	public trac_AccountDispatcher() {
		super();
	}

	public override void init() {
		oldAccounts = ( trigger.old != null ) ? (List<Account>)trigger.old : new List<Account>();
		newAccounts = ( trigger.new != null ) ? (List<Account>)trigger.new : new List<Account>();

		oldMap = ( trigger.oldMap != null ) ? (Map<Id, Account>) trigger.oldMap : new Map<Id, Account>();
		newMap = ( trigger.newMap != null ) ? (Map<Id, Account>) trigger.newMap : new Map<Id, Account>();
	}

	public override void execute() {
		if (ignore) {
			return;
		}

		if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
			for(Account currentAccount : newAccounts){
				if(String.isNotBlank(currentAccount.Domain__c)){
					currentAccount.Domain__c = (currentAccount.Domain__c).toLowerCase();
				}
			}
		}

		if( limitExecutionEvent(TriggerEvent.AFTERINSERT) && limitExecutionCount(AFTER_INSERT_DOMAIN_ASSIGNMENT, 1) ) {
			trac_DomainAccountAssignment.assignAccountToDomain(newAccounts);
		}

		/**
		 * @author Majeda Mahfuz, Traction On Demand
		 * @description assign domain on update
		 * @date 2014-10-24
		 */
		if( limitExecutionEvent(TriggerEvent.AFTERUPDATE) ) {
			List<Account> accountsWithUpdatedDomains = new List<Account>();
			for(Account a : newAccounts){
				if(a.Domain__c != oldMap.get(a.Id).Domain__c){
					accountsWithUpdatedDomains.add(a);
				}
			}
			if(!accountsWithUpdatedDomains.isEmpty() && limitExecutionCount(AFTER_UPDATE_DOMAIN_ASSIGNMENT, 1)) {
				trac_DomainAccountAssignment.assignAccountToDomain(accountsWithUpdatedDomains);
			}
		}

		//Masoud
		if( limitExecutionEvent(TriggerEvent.AFTERUPDATE) && limitExecutionCount('syncAccountLastActivityDateWithDomains - AFTER UPDATE', 1) ) {
			trac_DomainAccountAssignment.syncAccountLastActivityDateWithDomains(oldMap, newMap);
		}

		// account owner sync
		if (limitExecutionEvent(TriggerEvent.BEFOREUPDATE)) {
			trac_AccountSyncOwner.queueAccountOwnerChange(newAccounts, oldMap);
		}
	}
}