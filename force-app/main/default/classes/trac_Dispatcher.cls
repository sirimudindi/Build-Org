/**
* @author Ernesto Valdes
* @company Traction on Demand
* @description Utility class to manage triggers
*               Is extendable so that each trigger may have its own dispatcher
*               Handles recursion control, concurrent dml, and error handling
* @modifiedBy Sergei Dobrianski - 11/20/2013
*/
public abstract class trac_Dispatcher {

    private static Boolean DEBUG_MODE = true;

	public static Boolean ignore = false;
    
    /*************************************************
     *	Recursion Variables
     ************************************************/
	private static Map<String, Integer> processCountMap = new Map<String, Integer>();
  	public enum TriggerEvent {BEFOREINSERT, AFTERINSERT, BEFOREUPDATE, AFTERUPDATE, BEFOREDELETE, AFTERDELETE, BEFOREUNDELETE, AFTERUNDELETE}

    /**
     * Boolean for code coverage, THIS FIELD IS REFERENCED IN DispatcherTestClass
    **/
    public static Boolean isTestFrom_DispatcherTest_Class = false;

    /*************************************************
     *	DML Variables
     ************************************************/
    public List<sObject> insertList;
    public List<sObject> updateList;
    public List<sObject> deleteList;
    public List<sObject> undeleteList;

    // Map of dml list index -> index in original list in identifier
    public static Map<Integer, Integer> insertIndex;
    public static Map<Integer, Integer> updateIndex;
    public static Map<Integer, Integer> deleteIndex;
    public static Map<Integer, Integer> undeleteIndex;

    // Map of dml list index -> identifier
    public static Map<Integer, String> insertIdentifier;
    public static Map<Integer, String> updateIdentifier;
    public static Map<Integer, String> deleteIdentifier;
    public static Map<Integer, String> undeleteIdentifier;

    // Map of identifier - > list of errors in identifier
    public static Map<String, List<sObject>> insertErrors;
    public static Map<String, List<sObject>> updateErrors;
    public static Map<String, List<sObject>> deleteErrors;
    public static Map<String, List<sObject>> undeleteErrors;

    /*************************************************
     *	Constructor
     ************************************************/
    public trac_Dispatcher(){

    	// Init DML Variables
    	insertList = new List<sObject>();
    	updateList = new List<sObject>();
    	deleteList = new List<sObject>();
    	undeleteList = new List<sObject>();

    	insertIndex = new Map<Integer, Integer>();
    	updateIndex = new Map<Integer, Integer>();
    	deleteIndex = new Map<Integer, Integer>();
    	undeleteIndex = new Map<Integer, Integer>();

    	insertIdentifier = new Map<Integer, String>();
    	updateIdentifier = new Map<Integer, String>();
    	deleteIdentifier = new Map<Integer, String>();
    	undeleteIdentifier = new Map<Integer, String>();

    	insertErrors = new Map<String, List<sObject>>();
    	updateErrors = new Map<String, List<sObject>>();
    	deleteErrors = new Map<String, List<sObject>>();
    	undeleteErrors = new Map<String, List<sObject>>();
    }

    // You must implement this method to run your modular logic
    public abstract void init();

    // You must implement this method to run your modular logic
    public abstract void execute();

    // Preforms DMLs after all modules have run
    public void finish() {
		doDML();

        //custom post execution
        //postTriggerExecution();
   	}

    /*************************************************
     *	DML Methods - Use these inside your modules
     ************************************************/
    public void insertDML(List<sObject> insertItems, String identifier) {
    	
    	Integer dmlIndex = insertList.size(); // get curent dmlIndex index
    	Integer identIndex = 0; // index for this identifier
    	for (sObject obj : insertItems) {
    		insertList.add(obj); // store into insert list
    		insertIndex.put(dmlIndex, identIndex); // store relative index
    		insertIdentifier.put(dmlIndex, identifier); // store identifier for index

    		dmlIndex++;
    		identIndex++;
    	}
    }
    public void insertDML(List<sObject> insertList) { this.insertList.addAll(insertList); }
    public void insertDML(sObject insertObj) { this.insertList.add(insertObj); }

    public void updateDML(List<sObject> updateItems, String identifier) {
    	
    	Integer dmlIndex = updateList.size(); // get curent dmlIndex index
    	Integer identIndex = 0; // index for this identifier
    	for (sObject obj : updateItems) {
    		updateList.add(obj); // store into update list
    		updateIndex.put(dmlIndex, identIndex); // store relative index
    		updateIdentifier.put(dmlIndex, identifier); // store identifier for index

    		dmlIndex++;
    		identIndex++;
    	}
    }
    public void updateDML(List<sObject> updateList) { this.updateList.addAll(updateList); }
    public void updateDML(sObject updateObj) { this.updateList.add(updateObj); }

    public void doDML() {
    	try { doInsert(); } catch (Exception e) {	handleException(e, 'Insert DML'); }
    	try { doUpdate(); } catch (Exception e) { handleException(e, 'Update DML'); }
     }

    public void doInsert() {
    	if (!insertList.isEmpty()) {
    		LIST<Database.SaveResult> saveResultList = Database.insert(insertList, false);
    		insertErrors = processInsertDMLResults(saveResultList);
    	}
    }
	public void doUpdate() {
    	if (!updateList.isEmpty()) {
    		LIST<Database.SaveResult> saveResultList = Database.update(updateList, false);
    		updateErrors = processUpdateDMLResults(saveResultList);
    	}
    }

    public Map<String, List<sObject>> processInsertDMLResults(LIST<Database.SaveResult> saveResultLIST) {
    	Integer dmlIndex = 0;
    	Map<String, List<sObject>> errorMap = new Map<String, List<sObject>>();
		for (Database.SaveResult result : saveResultList) {
			if (!result.isSuccess()) {

				// Get index and identifier for informative debugging
				String identifier = (insertIdentifier.containsKey(dmlIndex)) ? insertIdentifier.get(dmlIndex) : 'Unknown';
				String index = (insertIndex.containsKey(dmlIndex)) ? String.valueOf(insertIndex.get(dmlIndex)) : 'Unknown';
				
                if (DEBUG_MODE) {
                    system.debug(LoggingLevel.ERROR, 'DML EXCEPTION AT INDEX: ' + index 
    												+ ' IN [' + identifier + ']: ' 
    												+ result.getErrors()[0].getMessage());
                }

				// Add to error list
				if (!errorMap.containsKey(identifier)) errorMap.put(identifier, new List<sObject>());
				errorMap.get(identifier).add(insertList.get(dmlIndex));
			}
			dmlIndex++;
		}
		return errorMAP;
    }

    public Map<String, List<sObject>> processUpdateDMLResults(LIST<Database.SaveResult> saveResultLIST) {
    	Integer dmlIndex = 0;
    	Map<String, List<sObject>> errorMap = new Map<String, List<sObject>>();
		for (Database.SaveResult result : saveResultList) {
			if (!result.isSuccess()) {

				// Get index and identifier for informative debugging
				String identifier = (updateIdentifier.containsKey(dmlIndex)) ? updateIdentifier.get(dmlIndex) : 'Unknown';
				String index = (updateIndex.containsKey(dmlIndex)) ? String.valueOf(updateIndex.get(dmlIndex)) : 'Unknown';

                if (DEBUG_MODE) {
    				system.debug(LoggingLevel.ERROR, 'DML EXCEPTION AT INDEX: ' + index 
    												+ ' IN [' + identifier + ']: ' 
    												+ result.getErrors()[0].getMessage());
                }

				// Add to error list
				if (!errorMap.containsKey(identifier)) errorMap.put(identifier, new List<sObject>());
				errorMap.get(identifier).add(updateList.get(dmlIndex));
			}
			dmlIndex++;
		}
		return errorMAP;
    }

    /*************************************************
     *	Recursion Methods
     ************************************************/

    public static Boolean limitExecutionEvent(TriggerEvent triggeringEvent) {    	
     	if (currentTriggerEvent() == triggeringEvent) return true;
     	else return false;
    }

    public static Boolean limitExecutionCount(String processName, Integer count) {
     	
        if (numTimesExecuted(processName) >= count) return false;
        
        countExecuted(processName);
        return true;
    }

	// Returns how many times a given process name has run, 0 otherwise
	public static Integer numTimesExecuted(String processName) {
		if (processCountMap.containsKey(processName)) return processCountMap.get(processName);
		else return 0;
	}

	// Increments the number of times a given process name has run
	public static void countExecuted(String processName) {
		if (!processCountMap.containsKey(processName)) processCountMap.put(processName, 0);
		processCountMap.put(processName, processCountMap.get(processName) + 1);
	}

	// Resets a given process name's run count
	public static void resetProcessCount(String processName) {
    	processCountMap.put(processName, 0);
	}

	// Resets all processes' run count
	public static void resetProcessCount() {
		processCountMap = new Map<String, Integer>();
	}

	// Returns the current trigger event
	public static TriggerEvent currentTriggerEvent() {
        if (!isTestFrom_DispatcherTest_Class && trigger.isBefore && trigger.isInsert) return TriggerEvent.BEFOREINSERT;
        if (!isTestFrom_DispatcherTest_Class && trigger.isAfter && trigger.isInsert) return TriggerEvent.AFTERINSERT;
        if (!isTestFrom_DispatcherTest_Class && trigger.isBefore && trigger.isUpdate) return TriggerEvent.BEFOREUPDATE;
        if (!isTestFrom_DispatcherTest_Class && trigger.isAfter && trigger.isUpdate) return TriggerEvent.AFTERUPDATE;
        if (!isTestFrom_DispatcherTest_Class && trigger.isBefore && trigger.isDelete) return TriggerEvent.BEFOREDELETE;
        if (!isTestFrom_DispatcherTest_Class && trigger.isAfter && trigger.isDelete) return TriggerEvent.AFTERDELETE;
        if (!isTestFrom_DispatcherTest_Class && trigger.isBefore && trigger.isUndelete) return TriggerEvent.BEFOREUNDELETE;
        if (!isTestFrom_DispatcherTest_Class && trigger.isAfter && trigger.isUndelete) return TriggerEvent.AFTERUNDELETE;
	  
	    return null;
	}

	// Debugs and Logs an Exception
	public static void handleException(Exception e) {
		system.debug(LoggingLevel.ERROR, e.getMessage() + e.getStackTraceString());
	}
	public static void handleException(Exception e, String identifier) {
		system.debug(LoggingLevel.ERROR, 'EXCEPTION IN [' + identifier + ']: ' + e.getMessage() + e.getStackTraceString());
	}

    /**
     * @description Extract a set of Id field values from a list of SObjects
     *
     */
    public static Set<Id> sobjectListToIdSet(String fieldName, List<SObject> sobjects) {
        //TODO: confirm fieldname specified is of type Id
        
        Set<Id> fieldSet = new Set<Id>();
        
        for(SObject sobj : sobjects) {
            fieldSet.add((Id)sobj.get(fieldName));
        }
        
        return fieldSet;
    }

    //public virtual void postTriggerExecution(){}

    public class DispatcherException extends Exception {}

}