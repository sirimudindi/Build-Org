/**
 * Class extends trac_Dispatcher.  Called from trac_Lead trigger
 *
 * @author Sergei Dobrianski - Traction on Demand
 * @modified - Dec 2, 2014 : removed the Payment_Profile__c layer
**/
public with sharing class trac_LeadDispatcher extends trac_Dispatcher {

	List<Lead> oldLeads;
	List<Lead> newLeads;

	Map<Id, Lead> oldMap;
	Map<Id, Lead> newMap;

	public trac_LeadDispatcher() {
		super();
	}

	public override void init() {
		oldLeads = ( trigger.old != null ) ? (List<Lead>)trigger.old : new List<Lead>();
		newLeads = ( trigger.new != null ) ? (List<Lead>)trigger.new : new List<Lead>();

		oldMap = ( trigger.oldMap != null ) ? (Map<Id, Lead>) trigger.oldMap : new Map<Id, Lead>();
		newMap = ( trigger.newMap != null ) ? (Map<Id, Lead>) trigger.newMap : new Map<Id, Lead>();

	}

	public override void execute() {
		if (ignore) {
			return;
		}

		if( trigger.isBefore && (trigger.isInsert || trigger.isUpdate) ) {
			for(Lead l : newLeads) {
				if( l.Domain__c != null ) {
					l.Domain__c = l.Domain__c.toLowerCase();
				}

			}
		}

		if( limitExecutionEvent(TriggerEvent.BEFOREINSERT) && limitExecutionCount('Process Domain - BEFORE INSERT', 1) ) {
			trac_IntegrationLeadProcessing.assignLeadDomain(newLeads);
		}

		if( limitExecutionEvent(TriggerEvent.BEFOREUPDATE) && limitExecutionCount('Domain__c Changed & paymentProfile processing - BEFORE UPDATE', 1) ) {
			trac_IntegrationLeadProcessing.assignLeadDomain(oldMap, newMap);
		}

		if( limitExecutionEvent(TriggerEvent.AFTERINSERT) && limitExecutionCount('Lead Conversion Event Handler - AFTER INSERT', 1) ) {
			trac_IntegrationLeadProcessing.convertLeads(newLeads);
		}

		if( limitExecutionEvent(TriggerEvent.AFTERUPDATE) && limitExecutionCount('Lead Conversion Event Handler - AFTER UPDATE', 1) ) {
			trac_IntegrationLeadProcessing.convertLeads(oldMap, newMap);
		}

		//if( limitExecutionEvent(TriggerEvent.AFTERUPDATE) && limitExecutionCount('syncLeadLastActivityDateWithDomains - AFTER UPDATE', 1) ){
		//	trac_IntegrationLeadProcessing.syncLeadLastActivityDateWithDomains(oldMap, newMap);
		//}

		// Transfer Cases attached to Leads after conversion
		// Do not restrict firing of this handler via limitExecutionCount() as SF will perform a number of updates during conversion
		if( limitExecutionEvent(TriggerEvent.AFTERUPDATE) ) {
			trac_CaseToContactAssociation.associateCases(oldMap, newMap);
		}

		if (limitExecutionEvent(TriggerEvent.BEFOREINSERT)) {
			trac_LeadSyncOwner.syncLeadDomainOwner(newLeads, new Map<Id,Lead>());
		}

		if (limitExecutionEvent(TriggerEvent.BEFOREUPDATE)) {
			trac_LeadSyncOwner.syncLeadDomainOwner(newLeads, oldMap);
		}
	}

}