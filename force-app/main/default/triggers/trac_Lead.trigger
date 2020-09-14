/**
 * This trigger calls a dispatcher class
**/
trigger trac_Lead on Lead (before insert, after insert, before update, after update) {
	trac_LeadDispatcher disp = new trac_LeadDispatcher();
	disp.init();
	disp.execute();
	disp.finish();

}