/**
 * @author Sergei Dobrianski
**/
public with sharing class trac_ContactDispatcher extends trac_Dispatcher {
	List<Contact> oldContacts;
	List<Contact> newContacts;

	Map<Id, Contact> oldMap;
	Map<Id, Contact> newMap;

	public trac_ContactDispatcher() {
		super();
	}

    
	public override void init() {
		oldContacts = ( trigger.old != null ) ? (List<Contact>)trigger.old : new List<Contact>();
		newContacts = ( trigger.new != null ) ? (List<Contact>)trigger.new : new List<Contact>();

		oldMap = ( trigger.oldMap != null ) ? (Map<Id, Contact>) trigger.oldMap : new Map<Id, Contact>();
		newMap = ( trigger.newMap != null ) ? (Map<Id, Contact>) trigger.newMap : new Map<Id, Contact>();
	}

	public override void execute() {
		if (ignore) {
			return;
		}

		if(limitExecutionEvent(TriggerEvent.BEFOREINSERT) && limitExecutionCount('Contact - Domain URL to lowercase - BEFORE INSERT', 1)){
			for(Contact currentContact : newContacts){
				if(String.isNotBlank(currentContact.Domain__c)){
					currentContact.Domain__c = (currentContact.Domain__c).toLowerCase();
				}
			}
		}

		if(limitExecutionEvent(TriggerEvent.BEFOREUPDATE)){
			for(Contact currentContact : newContacts){
				if(String.isNotBlank(currentContact.Domain__c)){
					currentContact.Domain__c = (currentContact.Domain__c).toLowerCase();
				}
			}
			/**
			 * @author Majeda Mahfuz, Traction On Demand
			 * @description assign domain on update
			 * @date 2014-10-24
			 */
			List<Contact> contactsWithUpdatedDomains = new List<Contact>();
			for(Contact c : newContacts){
				if(c.Domain__c != oldMap.get(c.Id).Domain__c){
					contactsWithUpdatedDomains.add(c);
				}
			}
			if(!contactsWithUpdatedDomains.isEmpty()){
				trac_ContactDomainAssignment.assignDomainToContact(contactsWithUpdatedDomains);
			}
		}

		if( limitExecutionEvent(TriggerEvent.BEFOREINSERT) && limitExecutionCount('Contact Domain Assignment - BEFORE INSERT', 1) ) {
			trac_ContactDomainAssignment.assignDomainToContact(newContacts);
		}

		if (limitExecutionEvent(TriggerEvent.BEFOREINSERT)) {
			trac_ContactSyncOwner.syncContactDomainOwner(newContacts, new Map<Id,Contact>());
		}

		if (limitExecutionEvent(TriggerEvent.BEFOREUPDATE)) {
			trac_ContactSyncOwner.syncContactDomainOwner(newContacts, oldMap);
		}
	}
}