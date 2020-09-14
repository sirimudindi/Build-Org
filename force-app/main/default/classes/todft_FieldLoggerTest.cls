/**
 * @author Rishabh Garg, Traction on Demand 
 * @date 2019-01-04
 */
@isTest
private class todft_FieldLoggerTest {

	@testSetup static void setupCustomSetting() {
		// Create common custom setting record for running trigger
		Field_Tracker_Settings__c settingRecord = new Field_Tracker_Settings__c();
		settingRecord.Trigger_Switch__c = true;
		settingRecord.SetupOwnerId = UserInfo.getOrganizationId();
		insert settingRecord;

		trac_TestUtils.setupCollaboratorPackage();
	}

	//inserting case records in bulk(10 records)
	private static Database.SaveResult[] createParentRecords() {
		Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Case');
		List<SObject> recordList = todft_TestDataFactory.createSObjects(targetType, 10);
		Trigger_Record_Type__mdt caseRT = [
				SELECT Record_Type_Name__c
				FROM Trigger_Record_Type__mdt
				WHERE Object_Name__c = 'Case'
				LIMIT 1
		];
		Id caseRTId = Case.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get(caseRT.Record_Type_Name__c).getRecordTypeId();
		for (SObject obj : recordList) {
			//obj.put('RecordTypeId', caseRTId);
		}
		Database.SaveResult[] updateResults = Database.insert(recordList, false);
		for (Database.SaveResult sr : updateResults) {
			System.debug(sr);
		}
		return updateResults;
	}

	private static testmethod void updateOwnerOfRecords() {
		Case testCase = new Case();
		insert testCase;

		List<AgentWork> testAgentWorkRecords = new List<AgentWork>();
		AgentWork testAgentWork = new AgentWork();
		testAgentWork.WorkItemId = testCase.Id;
		testAgentWorkRecords.add(testAgentWork);

		Map<Id, SObject> testOldAgentWorkMap = new Map<Id, SObject>();
		Exception resultException;

		Test.startTest();

		try {
			todft_AgentWorkService.updateOwnerOfRecords(testAgentWorkRecords, testOldAgentWorkMap);
		} catch(Exception e) {
			resultException = e;
		}

		Test.stopTest();

		System.assertEquals(null, resultException);
	}

	private static testmethod void agentWorkDomain() {
		Exception resultException;

		Test.startTest();

		try {
			todft_AgentWorkDomain agentWorkDomain = new todft_AgentWorkDomain();
			agentWorkDomain.handleAfterInsert();
		} catch(Exception e) {
			resultException = e;
		}

		Test.stopTest();

		System.assertEquals(null, resultException);
	}

	private static testmethod void triggerHandlerBase() {
		Exception resultException;

		try {
			todft_TriggerHandlerBase triggerHandlerBase = new todft_TriggerHandlerBase();
			triggerHandlerBase.handleAfterInsert();
			triggerHandlerBase.handleAfterUpdate();
		} catch(Exception e) {
			resultException = e;
		}

		System.assertEquals(null, resultException);
	}

	private static testmethod void includeParentRecord() {
		String testFieldValueList = 'Field1,Field2,Field3';
		String testFieldValue = 'Field1';
		Exception resultException;

		Test.startTest();

		Boolean result;
		try {
			result = todft_FieldLoggerUtils.includeParentRecord(testFieldValueList, testFieldValue);
		} catch(Exception e) {
			resultException = e;
		}

		Test.stopTest();

		System.assertEquals(null, resultException);
		System.assertNotEquals(null, result);
		System.assertEquals(true, result);
	}

	private static testmethod void executeForWorkAgent() {
		String testObjectName = 'Case';
		List<SObject> testSObjects = new List<SObject>();
		Boolean testViaWorkAgent = false;
		Exception resultException;

		Test.startTest();

		try {
			todft_FieldLogger.executeForWorkAgent(testObjectName, testSObjects, testViaWorkAgent);
		} catch(Exception e) {
			resultException = e;
		}

		Test.stopTest();

		System.assertEquals(null, resultException);
	}

	//insert scenario where time log will be created when the parent record is created.
	private static testmethod void createSObjectsRecordUtility() {
		Map<String, Set<String>> fieldMappingsByObject = new Map<String, Set<String>>();
		fieldMappingsByObject = todft_FieldLoggerUtils.fieldMappingsByObject;
		Test.startTest();
		Database.SaveResult[] updateResults = createParentRecords();
		Test.stopTest();
		List<Case_Time_Log__c> caseTimeLogRecords = [
				SELECT Id, Start_Time__c, End_Time__c, Owner_Type__c
				FROM Case_Time_Log__c
				WHERE End_Time__c = NULL
		];
		system.assertEquals(10, caseTimeLogRecords.size());
		List<Case_Time_Log__c> closedCaseTimeLogRecords = [
				SELECT Id, Start_Time__c, End_Time__c, Owner_Type__c
				FROM Case_Time_Log__c
				WHERE End_Time__c != NULL
		];
		system.assertEquals(0, closedCaseTimeLogRecords.size());
	}

	//update scenario where time log will be created/updated when parent record is created/updated via assignment rule
	private static testmethod void createUpdateSObjectsRecordUtility() {
		Test.startTest();
		Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Case');
		List<SObject> recordList = todft_TestDataFactory.createSObjects(targetType, 10);
		Group testGroup = new Group(Name = 'test group', Type = 'Queue');
		insert testGroup;
		System.runAs(new User(Id = UserInfo.getUserId())) {
			QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case');
			insert testQueue;
			QueuesObject testQueueForTimeLog = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Case_Time_Log__c');
			insert testQueueForTimeLog;
			GroupMember member = new GroupMember();
			member.UserOrGroupId = UserInfo.getUserId();
			member.GroupId = testGroup.Id;
			insert member;
		}
		for (SObject record : recordList) {
			record.put('OwnerId', testGroup.Id);
		}
		insert recordList;
		Test.stopTest();
		List<Case_Time_Log__c> caseTimeLogRecords = [
				SELECT Id, Start_Time__c, End_Time__c, Owner_Type__c
				FROM Case_Time_Log__c
				WHERE End_Time__c = NULL
		];
		system.assertEquals(10, caseTimeLogRecords.size());
		List<Case_Time_Log__c> closedCaseTimeLogRecords = [
				SELECT Id, Start_Time__c, End_Time__c, Owner_Type__c
				FROM Case_Time_Log__c
				WHERE End_Time__c != NULL
		];
		system.assertEquals(0, closedCaseTimeLogRecords.size());
		List<Case_Time_Log__c> queueCaseTimeLogRecords = [
				SELECT Id, Start_Time__c, End_Time__c, Owner_Type__c
				FROM Case_Time_Log__c
				WHERE End_Time__c = NULL AND Owner_Type__c = 'Queue'
		];
		system.assertEquals(10, queueCaseTimeLogRecords.size());
	}

	//update scenario where time log record is created & updated when parent record is updated
	private static testmethod void updateCaseParentRecords() {
		User usr = new User(Id = UserInfo.getUserId(), FirstName = 'Rishabh', LastName = 'Garg');
		system.runAs(usr) {
			Database.SaveResult[] updateResults = createParentRecords();
			List<Case_Time_Log__c> caseTimeLogRecords = [
					SELECT Id, Start_Time__c, End_Time__c, Owner_Type__c
					FROM Case_Time_Log__c
					WHERE End_Time__c = NULL
			];
			system.assertEquals(10, caseTimeLogRecords.size());
			List<Case_Time_Log__c> closedCaseTimeLogRecords = [
					SELECT Id, Start_Time__c, End_Time__c, Owner_Type__c
					FROM Case_Time_Log__c
					WHERE End_Time__c != NULL
			];
			system.assertEquals(0, closedCaseTimeLogRecords.size());
			Test.startTest();
			List<SObject> parentRecordToUpdate = new List<SObject>();
			// Iterate through each returned result
			for (Integer i = 0; i < updateResults.size(); i++) {
				if (updateResults.get(i).isSuccess()) {
					Id objectRecordId = updateResults.get(i).getId();
					String sObjName = objectRecordId.getSObjectType().getDescribe().getName();
					sObject sObj = Schema.getGlobalDescribe().get(sObjName).newSObject();
					sObj.put('Id', updateResults.get(i).getId());
					sObj.put('Status', 'Working');
					sObj.put('OwnerId', usr.Id);
					parentRecordToUpdate.add(sObj);
				}
			}
			todft_FieldLogger.isParentRecordCreated = false;
			//Database.SaveResult[] updateParentRecords = Database.update(parentRecordToUpdate, false);
			update parentRecordToUpdate;
			Test.stopTest();
			closedCaseTimeLogRecords = [
					SELECT Id, Start_Time__c, End_Time__c, Owner_Type__c
					FROM Case_Time_Log__c
					WHERE End_Time__c != NULL
			];
			system.assertEquals(10, closedCaseTimeLogRecords.size());
		}
	}

	//Testing functionality of updating parent record using omni channel assignment
	//and tracking the changes by creating & updating time logs
	private static testmethod void createAgentWorkRecords() {
		Database.SaveResult[] updateResults = createParentRecords();
		Test.startTest();
		List<SObject> parentRecordToUpdate = new List<SObject>();
		// Iterate through each returned result
		for (Integer i = 0; i < updateResults.size(); i++) {
			if (updateResults.get(i).isSuccess()) {
				Id objectRecordId = updateResults.get(i).getId();
				String sObjName = objectRecordId.getSObjectType().getDescribe().getName();
				sObject sObj = Schema.getGlobalDescribe().get(sObjName).newSObject();
				sObj.put('Id', updateResults.get(i).getId());
				Database.DMLOptions dmo = new Database.DMLOptions();
				dmo.assignmentRuleHeader.useDefaultRule = true;
				sObj.setOptions(dmo);
				parentRecordToUpdate.add(sObj);
			}
		}
		Database.SaveResult[] updateParentRecords = Database.update(parentRecordToUpdate, false);
		Schema.SObjectType targetTypeAgentWork = Schema.getGlobalDescribe().get('AgentWork');
		//List<SObject> workAgentList = todft_TestDataFactory.createSObjects(targetTypeAgentWork, 10);
		List<SObject> workAgentList = new List<SObject>();
		ServiceChannel serviceChannelRecord = [
				SELECT Id
				FROM ServiceChannel
				WHERE RelatedEntity = 'Case'
				LIMIT 1
		];

		for (Integer i = 0; i < updateParentRecords.size(); i++) {
			sObject sObj = Schema.getGlobalDescribe().get('AgentWork').newSObject();
			sObj.put('WorkItemId', updateParentRecords.get(i).getId());
			sObj.put('ServiceChannelId', serviceChannelRecord.Id);
			sObj.put('UserId', UserInfo.getUserId());
			sObj.put('ShouldSkipCapacityCheck', true);
			workAgentList.add(sObj);
		}
		todft_FieldLogger.isParentRecordCreated = false;

		//Database.SaveResult[] insertAgentWorkList = Database.insert(workAgentList, false);
		try {
			insert workAgentList;
			List<Case_Time_Log__c> queueCaseTimeLogRecords = [
					SELECT Id, Start_Time__c, End_Time__c, Owner_Type__c
					FROM Case_Time_Log__c
					WHERE End_Time__c != NULL AND Owner_Type__c = 'Queue'
			];
			system.assertEquals(10, queueCaseTimeLogRecords.size());
		} catch (DmlException e) {
			if (e.getMessage().contains('FIELD_INTEGRITY_EXCEPTION')) {
				//exception occurs if current user is not logged into Omni-Channel. exit test.
				return;
			}
		}
		Test.stopTest();
	}
}