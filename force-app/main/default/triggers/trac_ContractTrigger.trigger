trigger trac_ContractTrigger on Contract (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) {

	new trac_PlanTriggerHandler().process();
}