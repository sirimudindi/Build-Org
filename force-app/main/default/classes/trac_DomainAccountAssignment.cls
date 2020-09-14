public without sharing class trac_DomainAccountAssignment {
	public static final String EXISTING_ACCOUNT_ON_DOMAIN_MSG = 'The domain is currently associated to ';
	/*
	 * @description assignAccountToDomain method gets executed during the Account trigger.
	 *              It loops through the Trigger.new and determines wiether a new a domain
	 *              should be created. We then associate the account to the domain that
	 *              was created.
	 * 
	 * @author Thomas Tran
	 * @company Traction on Demand
	 * @date 09-25-2014
	 */
	public static void assignAccountToDomain(List<Account> accountList){
		Set<String> domainURLs = new Set<String>();
		Map<String, Domain__c> domainURLsToDomainMap = new Map<String, Domain__c>();
		List<Domain__c> domainsToUpdateList = new List<Domain__c>();

        
		//Grab all domainUrls if its avaliable on the account
		for(Account currentAccount : accountList){
			if(String.isNotBlank(currentAccount.Domain__c)){
				domainURLs.add(currentAccount.Domain__c);
			}
		}

		//Pass the set to domain utils to check if its existing or a net new.
		if(!domainURLs.isEmpty()){
			domainURLsToDomainMap = trac_DomainUtils.getDomains(domainURLs);
		}

		if(!domainURLsToDomainMap.isEmpty()){
			for(Account currentAccount : accountList){
				Domain__c currentDomain = domainURLsToDomainMap.get(currentAccount.Domain__c);
				if(currentDomain != null){
					if(currentDomain.Account__c == null){
						currentDomain.Account__c = currentAccount.Id;
						domainsToUpdateList.add(currentDomain);
					} else{

						currentAccount.addError(EXISTING_ACCOUNT_ON_DOMAIN_MSG + currentDomain.Account__r.Name);
					}
				}
			}
		}

		if(!domainsToUpdateList.isEmpty()){
			update domainsToUpdateList;
		}
	}

	/**
     * Masoud.A Pivotal 80797796
     * On Update when Last Activity Date is changed on Accoubt. Run an update on all the attached Domains to update Last Activity .
    **/
	public static void syncAccountLastActivityDateWithDomains(Map<Id, Account> oldAccounts, Map<Id, Account> newAccounts){        
        if (oldAccounts == null || newAccounts ==null){
            return;
        }
        
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Date> mapAccountToActivityDate = new Map<Id, Date>();
        List<Domain__c> lstDLCToUpdate = new List<Domain__c>();
        for(String newAccountId:newAccounts.keySet()){
            if (oldAccounts.get(newAccountId) !=null &&  
                newAccounts.get(newAccountId).LastActivityDate !=null ){ 
            	accountIds.add(newAccountId);
            	mapAccountToActivityDate.put(newAccountId, newAccounts.get(newAccountId).LastActivityDate);
            }
        }


        if (accountIds.size()>0){

        	List<Domain__c> lstDomains = new List<Domain__c>();
        	List<Domain__c> updateList = new List<Domain__c>();

        	lstDomains = [Select Id,Account__c, Last_Activity_Date__c From Domain__c Where Account__c IN:accountIds ];


        	List<Account> lstTest = [Select ID,Name,LastActivityDate From Account Where Id in:accountIds];

        	for(Domain__c d:lstDomains){
        		if (mapAccountToActivityDate.get(d.Account__c) !=null ){
        			Domain__c domain = new Domain__c();
        			domain.Id = d.Id;
        			domain.Last_Activity_Date__c = mapAccountToActivityDate.get(d.Account__c);

        			updateList.add(domain);
        		}
        	}

        	if (updateList.size()>0){
        		update updateList;
        	}
    	}    	
	}

}