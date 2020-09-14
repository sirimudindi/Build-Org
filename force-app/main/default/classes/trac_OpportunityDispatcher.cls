/**
 * Dispatcher class for opportunity trigger.
 * @author Sergei Dobrianski - Traction on Demand
**/
public without sharing class trac_OpportunityDispatcher extends trac_Dispatcher {

	public static final String PENDING_CLOSE = 'Pending Close';
	public static final String CLOSED_WON    = 'Closed Won';

	List<Opportunity> oldList;
	List<Opportunity> newList;

	Map<Id, Opportunity> oldMap;
	Map<Id, Opportunity> newMap;

	public trac_OpportunityDispatcher() {
		super();	
	}

	public override void init() {
		oldList = ( trigger.old != null ) ? (List<Opportunity>)trigger.old : new List<Opportunity>();
		newList = ( trigger.new != null ) ? (List<Opportunity>)trigger.new : new List<Opportunity>();

		oldMap = ( trigger.oldMap != null ) ? (Map<Id, Opportunity>) trigger.oldMap : new Map<Id, Opportunity>();
		newMap = ( trigger.newMap != null ) ? (Map<Id, Opportunity>) trigger.newMap : new Map<Id, Opportunity>();
	}
    

	public override void execute() {

		// Opportunity Plan Logic
		if( limitExecutionEvent( TriggerEvent.BEFOREUPDATE ) ) {
			
			trac_OpportunityPlanHandler handler = new trac_OpportunityPlanHandler( newList, newMap, oldMap );
			List<Opportunity> approvedOpps = handler.filterApprovedPlanOpps( newMap, oldMap );
			List<Opportunity> newApprovedOpps = handler.filterNewApprovedPlanOpps( approvedOpps );
			handler.validatePPPIds( newApprovedOpps );
			handler.flagOpportunitiesForIntegration( newApprovedOpps );
		
		}

		// Opportunity Plan Logic
		if( limitExecutionEvent( TriggerEvent.AFTERUPDATE ) ) {

			trac_OpportunityPlanHandler handler = new trac_OpportunityPlanHandler( newList, newMap, oldMap );
			List<Opportunity> approvedOpps = handler.filterApprovedPlanOpps( newMap, oldMap );
			handler.manageSKUs( approvedOpps );

		}

    }
}