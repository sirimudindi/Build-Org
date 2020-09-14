/*
 * @description Returns a list of tasks associated with the domain. It also create the
 *              related list pagination.
 */
public without sharing class trac_ActivityRelatedListCtlr {
	public Id domainId {get; set;}
	public String baseURL {get; set;}

	//paging variables
	private Integer counter = 0;
	private Integer list_size = 10;
	public Integer total_size;

	public trac_ActivityRelatedListCtlr(ApexPages.StandardController pageParameters) {
		domainId = String.valueOf(pageParameters.getRecord().get('id'));
		baseURL = URL.getSalesforceBaseUrl().toExternalForm() + '/';
	}

	public List<Task> getTasks(){
		Set<Id> idsToQueryTasks = new Set<Id>();
		List<Task> taskListToReturn = new List<Task>();

		for(Opportunity currentOpportunity : [SELECT Id FROM Opportunity WHERE Domain_Lookup__c = :domainId]){
			idsToQueryTasks.add(currentOpportunity.Id);
		}
        

		for(Contact currentContact : [SELECT Id FROM Contact WHERE Domain_Lookup__c = :domainId]){
			idsToQueryTasks.add(currentContact.Id);
		}

		for(Lead currentLead : [SELECT Id FROM Lead WHERE Domain_Lookup__c = :domainId]){
			idsToQueryTasks.add(currentLead.Id);
		}

		total_size = [SELECT count() FROM Task WHERE WhatId = :idsToQueryTasks];

		taskListToReturn = [
			SELECT Id, Subject, ActivityDate, Status, OwnerId, Owner.Name
			FROM Task
			WHERE WhatId IN :idsToQueryTasks OR WhoId IN :idsToQueryTasks
			ORDER BY ActivityDate DESC
			LIMIT :list_size
			OFFSET :counter
		];

		return taskListToReturn;

	}

	public PageReference beginning() { //user clicked beginning
      counter = 0;
      return null;
   }
 
   public PageReference previous() { //user clicked previous button
      counter -= list_size;
      return null;
   }
 
   public PageReference next() { //user clicked next button
      counter += list_size;
      return null;
   }
 
   public PageReference end() { //user clicked end
      counter = total_size - math.mod(total_size, list_size);
      return null;
   }
 
   public Boolean getDisablePrevious() { 
      //this will disable the previous and beginning buttons
      if (counter>0) return false; else return true;
   }
 
   public Boolean getDisableNext() { //this will disable the next and end buttons
      if (counter + list_size < total_size) return false; else return true;
   }
 
   public Integer getTotal_size() {
      return total_size;
   }
 
   public Integer getPageNumber() {
      return counter/list_size + 1;
   }
 
   public Integer getTotalPages() {
      if (math.mod(total_size, list_size) > 0) {
         return total_size/list_size + 1;
      } else {
         return (total_size/list_size);
      }
   }
}