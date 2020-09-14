trigger trac_DomainTrigger on Domain__c (before insert, before update, after insert, after update) {

	trac_DomainDispatcher disp = new trac_DomainDispatcher();
	disp.init();
	disp.execute();
	disp.finish();

}