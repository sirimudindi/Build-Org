trigger trac_Account on Account (before insert, after insert, before update, after update) {

	trac_AccountDispatcher disp = new trac_AccountDispatcher();
	disp.init();
	disp.execute();
	disp.finish();

}