@isTest
public class ProjectOpsClosedOutTest {
	@isTest
    public static void projectUnitTest(){
        
        Test.startTest();
        
        Account account = new Account(
        	Name = 'PSA Test Account');
        insert account;
        
        Profile profileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        pse__Region__c region = [SELECT ID FROM pse__Region__c WHERE Name = 'Global Region' LIMIT 1];
        
        User user = new User(
            Alias = 'testpsa', 
            Email='testpsauser@test.com', 
            UserName = 'testpsausername@test.com',
            EmailEncodingKey='UTF-8', 
            LastName='Testing', 
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = profileId.id,
            TimeZoneSidKey='America/Los_Angeles', 
            FirstName= 'Test');
        insert user;
        
        pse__Proj__c project = new pse__Proj__C(
        	Name = 'Test Project',
        	pse__Stage__c = '',
        	pse__Is_Active__c = TRUE,
        	pse__Region__c = region.id,
        	ffps_sspa__Template_Type__c = 'Consulting');
        insert project;
        
        Contact contact = new Contact(
            FirstName = 'First Name',
        	LastName = 'PSA Test',
        	AccountId = account.id,
        	pse__Salesforce_User__c = user.id,
        	pse__Is_Resource__c = TRUE,
        	pse__Is_Resource_Active__c = TRUE,
        	pse__Default_Cost_Rate__c = 0.00);
        insert contact;
        
        pse__Assignment__c assignment = new pse__Assignment__c(
    		Name = 'Test Assignment',
    		pse__Resource__c = contact.id,
    		pse__Project__c = project.id,
    		pse__Bill_Rate__c = 0.00,
    		pse__Role__c = 'SIM');
		insert assignment;
        
        pse__Timecard_Header__c timecard = new pse__Timecard_Header__c(
			pse__Resource__c = contact.id,
			pse__Start_Date__c = system.today(),
			pse__End_Date__c = system.today().addDays(6),
			CurrencyIsoCode = 'USD',
			pse__Status__c = 'Approved',
			pse__Project__c = project.id,
			pse__Assignment__c = assignment.id);
		insert timecard;
        
        pse__Permission_Control__c permissionControl = new pse__Permission_Control__c(
        	pse__Resource_Request_Entry__c = TRUE,
        	pse__Staffing__c = TRUE,
        	pse__Timecard_Entry__c = TRUE,
        	pse__Timecard_Ops_Edit__c = TRUE,
        	pse__Cascading_Permission__c = TRUE,
        	pse__User__c = user.id,
        	pse__Region__c = region.id,
          	pse__Start_Date__c = Date.newInstance(2017, 01, 01));
        insert permissionControl;

        Test.stopTest();
       
        System.runAs(user){
           project.pse__Stage__c = 'Ops Closed Out';
        	try{
            	update project;
        	} catch(Exception e) {
        	}
        }
	}
}