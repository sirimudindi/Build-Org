/**
 * trac_Case.trigger
 * @description Trigger that is fired on creation/update of Case object
 * @author      Mike Fransblow
 * @company     Traction On Demand
 * @date        Thu May 12 15:41:28 2016
 */
trigger trac_Case on Case (before insert, after insert, before update, after update,
        before delete, after delete, after undelete) {


    trac_CaseDispatcher disp = new trac_CaseDispatcher();
    disp.init();
    disp.execute();
    disp.finish();

    trac_TriggerHandlerBase.triggerHandler(new trac_Case());
}