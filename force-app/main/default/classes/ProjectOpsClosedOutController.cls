public class ProjectOpsClosedOutController {
    public static void ProjectOpsClosed(List<pse__proj__c> newProj, Map<Id,pse__proj__c> oldProj){
        List<pse__timecard_header__c> timecardsList = new List<pse__timecard_header__c>();
        
        FOR(pse__proj__c p : newProj){
            IF(p.pse__Stage__c == 'Ops Closed Out' && oldProj.get(p.id).pse__Stage__c != 'Ops Closed Out'){
                timecardsList = [SELECT ID, pse__Status__c FROM pse__timecard_header__c WHERE pse__Project__c = :p.id AND (pse__Status__c != 'Approved' OR pse__Status__c != 'Rejected')];
        		IF(timecardsList.size()>0){
                	p.addError(' Cannot move Project to Ops Closed Out as there ' + timecardsList.Size() + ' open Timecard(s).');
            	}       
        	}
    	}
	}
}