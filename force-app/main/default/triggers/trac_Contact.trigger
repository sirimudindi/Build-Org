trigger trac_Contact on Contact (before insert, after insert, before update, after update) {
	trac_ContactDispatcher disp = new trac_ContactDispatcher();
	disp.init();
	disp.execute();
	disp.finish();
}