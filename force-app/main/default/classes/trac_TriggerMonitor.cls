/**
 * trac_TriggerMonitor.cls
 * @description Simple class used to prevent trigger recursion
 * @author      Mike Fransblow
 * @company     Traction On Demand
 * @date        Nov 14 2016
 */
public class trac_TriggerMonitor {

	public static set<string> ExecutedTriggers {get;set;}

	static {
		ExecutedTriggers = new Set<String>();
	}
}