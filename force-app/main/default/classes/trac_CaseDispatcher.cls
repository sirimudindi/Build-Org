/**
 * trac_CaseDispatcher.cls
 * @description Class extends trac_Dispatcher.  Called from trac_Case trigger
 * @author 		Mike Fransblow
 * @company     Traction On Demand
 * @date 		Thu May 12 15:44:08 2016
 */

public with sharing class trac_CaseDispatcher extends trac_Dispatcher {

	List<Case> oldCases;
	List<Case> newCases;

	Map<Id, Case> oldMap;
	Map<Id, Case> newMap;

	public trac_CaseDispatcher() {
		super();
	}

	public override void init() {
		oldCases = ( trigger.old != null ) ? (List<Case>)trigger.old : new List<Case>();
		newCases = ( trigger.new != null ) ? (List<Case>)trigger.new : new List<Case>();

		oldMap = ( trigger.oldMap != null ) ? (Map<Id, Case>) trigger.oldMap : new Map<Id, Case>();
		newMap = ( trigger.newMap != null ) ? (Map<Id, Case>) trigger.newMap : new Map<Id, Case>();

	}

	public override void execute() {

		if( limitExecutionEvent(TriggerEvent.BEFOREINSERT) && limitExecutionCount('Case to Lead lookup - BEFORE INSERT', 99) ) {
			trac_CaseToLeadAssociation.associateCaseToLead(newCases);
		}

	}

}