trigger trac_Opportunity on Opportunity (before insert, before update, after insert, after update) {

    trac_OpportunityDispatcher disp = new trac_OpportunityDispatcher();
    disp.init();
    disp.execute();
    disp.finish();

}