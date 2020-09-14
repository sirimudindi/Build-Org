/**
 * Test class for trac_Dispatcher.
 * 
 * @author Sergei Dobrianski
 * @company Traction on Demand
**/
@isTest (seeAllData = false)
public with sharing class trac_DispatcherTest {
	
	static{
		trac_Dispatcher.isTestFrom_DispatcherTest_Class = true;
	}

	private class DispatcherTestClass extends trac_Dispatcher{
		public DispatcherTestClass(){
			super();
		}
        

		public override void init(){}
		public override void execute(){}

	}

	public static testMethod void constructorCoverage(){
		DispatcherTestClass d = new DispatcherTestClass();	
	}

	public static testMethod void coverLimitExecutionEvents(){
		trac_Dispatcher.limitExecutionEvent(trac_Dispatcher.TriggerEvent.AFTERINSERT);
		trac_Dispatcher.limitExecutionCount('Test', 1);
		trac_Dispatcher.countExecuted('Test');
		trac_Dispatcher.resetProcessCount('Test');
		trac_Dispatcher.resetProcessCount();
	}

	public static testMethod void coverDML(){
		DispatcherTestClass d = new DispatcherTestClass();
		Account a = new Account(Name = 'Test');
		d.insertList.add((SObject)a);
		d.updateList.add((SObject)a);
		d.deleteList.add((SObject)a);
		d.undeleteList.add((SObject)a);
		d.finish();
	}

	public static testMethod void coverDMLLists(){
		DispatcherTestClass d = new DispatcherTestClass();
		Account a = new Account(Name = 'Test');
		List<SObject> objList = new List<SObject>();
		objList.add((SObject)a);
		d.insertList.add((SObject)a);
		d.updateList.add((SObject)a);
		d.deleteList.add((SObject)a);
		d.undeleteList.add((SObject)a);

		trac_Dispatcher.insertIndex.put(0, 1);
		trac_Dispatcher.updateIndex.put(0, 1);
		trac_Dispatcher.deleteIndex.put(0, 1);
		trac_Dispatcher.undeleteIndex.put(0, 1);

		trac_Dispatcher.insertIdentifier.put(0, 'Test');
        trac_Dispatcher.updateIdentifier.put(0, 'Test');
        trac_Dispatcher.deleteIdentifier.put(0, 'Test');
        trac_Dispatcher.undeleteIdentifier.put(0, 'Test');
		
		d.insertDML(objList);
		d.insertDML((SObject)a);
		d.insertDML(objList, 'Test');

		d.updateDML(objList);
		d.updateDML((SObject)a);
		d.updateDML(objList, 'Test');

		//d.deleteDML(objList);
		//d.deleteDML((SObject)a);
		//d.deleteDML(objList, 'Test');

		//d.unDeleteDML(objList);
		//d.unDeleteDML((SObject)a);
		//d.unDeleteDML(objList, 'Test');
	}

	private class HandledDispatcherException extends Exception{}

	public static testMethod void coverExceptionHandler(){
		trac_Dispatcher.handleException(new HandledDispatcherException('Exception Coverage'));
		trac_Dispatcher.handleException(new HandledDispatcherException('Exception Coverage'), 'Test Identifier');
	}

	public static testMethod void testSObjectListToIdSet(){
		DispatcherTestClass d = new DispatcherTestClass();
		Account a = new Account(Name = 'Test');
		List<SObject> objList = new List<SObject>();
		objList.add((SObject)a);
		trac_Dispatcher.sobjectListToIdSet('Id', objList);
	}


}