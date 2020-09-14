/**
 * Base class for all triggers handlers.
 * How to use it:
 * 1) Create a domain class for your SObject (trac_Opportunity for example) that extends trac_TriggerHandlerBase.
 * 2) Override the handler methods that you need.
 * 3) On the trigger, call trac_TriggerHandlerBase.triggerHandler passing a instance of your handler (like trac_Opportunity).
 *    Example: trac_TriggerHandlerBase.triggerHandler(new trac_CaseComment());
 */
public virtual class trac_TriggerHandlerBase {
	public static Boolean blockTrigger = false;

	protected List<SObject> newRecordsList;
	protected List<SObject> oldRecordsList;
	protected Map<Id, SObject> oldRecordsMap;
	protected Map<Id, SObject> newRecordsMap;

	public trac_TriggerHandlerBase() {
		oldRecordsMap = Trigger.oldMap;
		newRecordsMap = Trigger.newMap;
		newRecordsList = Trigger.new;
		oldRecordsList = Trigger.old;
	}

	public static void triggerHandler(trac_TriggerHandlerBase triggerHandler) {
		if (blockTrigger) {
			return;
		}

		if(Trigger.isBefore) {
			if(Trigger.isInsert) triggerHandler.handleBeforeInsert();
			else if(Trigger.isUpdate) triggerHandler.handleBeforeUpdate();
			else if(Trigger.isDelete) triggerHandler.handleBeforeDelete();
		} else {
			if(Trigger.isInsert) triggerHandler.handleAfterInsert();
			else if(Trigger.isUpdate) triggerHandler.handleAfterUpdate();
			else if(Trigger.isDelete) triggerHandler.handleAfterDelete();
			else if(Trigger.isUndelete) triggerHandler.handleAfterUndelete();
		}
	}

	public virtual void handleBeforeInsert() {}

	public virtual void handleBeforeUpdate() {}

	public virtual void handleAfterInsert() {}

	public virtual void handleAfterUpdate() {}

	public virtual void handleBeforeDelete() {}

	public virtual void handleAfterDelete() {}

	public virtual void handleAfterUndelete() {}
}