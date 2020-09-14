/**
 * trac_EmailMessage.trigger
 * @description Trigger that is fired on creation/update of EmailMessage object
 * @author      Mike Fransblow
 * @company     Traction On Demand
 * @date        Nov 7 2016
 */

trigger trac_EmailMessage on EmailMessage (before insert, after insert, before update, after update)  { 
    trac_EmailMessageDispatcher disp = new trac_EmailMessageDispatcher();
    disp.init();
    disp.execute();
    disp.finish();
}