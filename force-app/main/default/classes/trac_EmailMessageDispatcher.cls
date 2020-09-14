/**
 * trac_EmailMessageDispatcher.cls
 * @description Class extends trac_Dispatcher.  Called from  * trac_EmailMessage.trigger
 * @author      Mike Fransblow
 * @company     Traction On Demand
 * @date        Nov 7 2016
 */
public class trac_EmailMessageDispatcher extends trac_Dispatcher { 

	List<EmailMessage> oldEmails;
	List<EmailMessage> newEmails;

	Map<Id, EmailMessage> oldMap;
	Map<Id, EmailMessage> newMap;

	public trac_EmailMessageDispatcher() {
		super();
	}

	public override void init() {
		oldEmails = ( trigger.old != null ) ? (List<EmailMessage>)trigger.old : new List<EmailMessage>();
		newEmails = ( trigger.new != null ) ? (List<EmailMessage>)trigger.new : new List<EmailMessage>();
		oldMap = ( trigger.oldMap != null ) ? (Map<Id, EmailMessage>) trigger.oldMap : new Map<Id, EmailMessage>();
		newMap = ( trigger.newMap != null ) ? (Map<Id, EmailMessage>) trigger.newMap : new Map<Id, EmailMessage>();		
	}

	public override void execute() {
		if( limitExecutionEvent(TriggerEvent.AFTERINSERT)  ) {
			// Avoid recurive trigger
			if(trac_TriggerMonitor.ExecutedTriggers.contains('trac_EmailMessageCaseHandler.reparentExistingCases')){
				System.debug('trac_TriggerMonitor detects this has run already');
				return;
			}				
			trac_TriggerMonitor.ExecutedTriggers.add('trac_EmailMessageCaseHandler.reparentExistingCases');
			trac_EmailMessageCaseHandler.reparentExistingEmailMessagesToCases();
		}
	}

}