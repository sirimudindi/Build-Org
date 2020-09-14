/**
 *  trac_TriggerHelper.cls
 *
 *  @description
 *  Super class for all triggers. 
 *  When a new trigger is created for any object, a separate helper class can be created 
 *  which can extend from this super class. In the extended class, the following
 *  virtual methods can be overridden and Trigger.XXX variables (eg: Trigger.New, Trigger.OldMap)
 *  can be directly used depending on the context.
 *  
 *  Example:
 *  Trigger Code:
 *  -------------
 *      trigger trac_Opportunity on Opportunity (before insert, before update, after insert, after update) {
 *          new trac_Opportunity().process();
 *      }
 *      
 *  Helper Class Code:
 *  -----------------           
 *      public class trac_Opportunity extends trac_TriggerHelper {
 *          public override void processBeforeInsert() {
 *              //before insert logic goes here
 *          }
 *          public override void processAfterUpdate() {
 *              //after update logic goes here
 *          }
 *      }   
 *  @date 2017-03-20
 *  @author Ryan Draper, Traction on demand
 */
public virtual class trac_TriggerHelper {
    
    public void process() {
         if(Trigger.isBefore){
            //if(Trigger.isInsert){
            //    processBeforeInsert();
            //}      
            //else if(Trigger.isUpdate){
            //    processBeforeUpdate();
            //}
			//if(Trigger.isDelete){
			//	processBeforeDelete();
			//}
			//else if(Trigger.isUndelete){
			//	processBeforeUndelete();
			//}
        } else if(Trigger.isAfter){
            if(Trigger.isInsert){
                processAfterInsert();
            }      
            else if(Trigger.isUpdate){
                processAfterUpdate();
            }
          	//else if(Trigger.isDelete){
           //     processAfterDelete();
           // }
           // else if(Trigger.isUndelete){
           //     processAfterUndelete();
           // }
        }       
    }
    
    /* The following methods can be overridden in the sub classes as per the need */
    
    //public virtual void processBeforeInsert() {}
    //public virtual void processBeforeUpdate() {}
    //public virtual void processBeforeDelete() {}
    //public virtual void processBeforeUndelete() {}
    public virtual void processAfterInsert() {}
    public virtual void processAfterUpdate() {}
    //public virtual void processAfterDelete() {}
    //public virtual void processAfterUndelete() {}

}