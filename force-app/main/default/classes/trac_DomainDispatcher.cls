/**
 * Domain Dispatcher class
 *
 * @author Sergei Dobrianski
 * @modifiedBy Rauza Zhenissova
**/
public without sharing class trac_DomainDispatcher extends trac_Dispatcher {

	List<Domain__c> oldDomains;
	List<Domain__c> newDomains;

	Map<Id, Domain__c> oldMap;
	Map<Id, Domain__c> newMap;

	public trac_DomainDispatcher() {
		super();	
	}

	public override void init() {
		oldDomains = ( trigger.old != null ) ? (List<Domain__c>)trigger.old : new List<Domain__c>();
		newDomains = ( trigger.new != null ) ? (List<Domain__c>)trigger.new : new List<Domain__c>();

		oldMap = ( trigger.oldMap != null ) ? (Map<Id, Domain__c>) trigger.oldMap : new Map<Id, Domain__c>();
		newMap = ( trigger.newMap != null ) ? (Map<Id, Domain__c>) trigger.newMap : new Map<Id, Domain__c>();
        
	}

	public override void execute() {

		if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate)) {
			for(Domain__c domain : newDomains) {
				if( domain.Domain_Name_URL__c != null ) {
					domain.Domain_Name_URL__c = domain.Domain_Name_URL__c.toLowerCase();
					if(domain.Name == null || domain.Name.equals('')){
						domain.Name = domain.Domain_Name_URL__c;
					}
				}
			}
		}

		if (limitExecutionEvent(TriggerEvent.BEFOREINSERT)) {
			trac_DomainSyncOwner.syncDomainAccountOwner(newDomains, new Map<Id,Domain__c>());
		}

		if (limitExecutionEvent(TriggerEvent.BEFOREUPDATE)) {
			trac_DomainSyncOwner.syncDomainAccountOwner(newDomains, oldMap);
			trac_DomainSyncOwner.queueDomainOwnerChange(newDomains, oldMap);
		}
		if (limitExecutionEvent(TriggerEvent.AFTERUPDATE)) {
//			trac_DomainSyncOwner.updateSyncOwnerAccount(newDomains, oldMap);
		}
	}
}