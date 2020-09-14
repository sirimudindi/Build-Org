public without sharing class trac_ContactDomainAssignment {
	/*
	 * @description assignDomainToContact method checks if the Contact has a domain
	 *              if it does, it checks if that domain has an account, if not then
	 *              assign contact account info to domain. If it does have an account
	 *              and it doesn't match the contact account it throws an error message.
	 *              If it has an account and matches the contact account, it updates the
	 *              contact domain lookup.
	 *
	 * @author Thomas Tran, Traction on Demand
	 * @date 09-30-2014
	 */
	public static void assignDomainToContact(List<Contact> contactList){
		Set<String> newDomainSet = new Set<String>();
		Map<String, Domain__c> domainURLsToDomainMap = new Map<String, Domain__c>();
		List<Domain__c> domainsToUpdate = new List<Domain__c>();

        
		for(Contact currentContact : contactList){

			if(String.isNotBlank(currentContact.Domain__c)){ //Checks if the Domain__c is empty, if so then don't add it to the set.
				newDomainSet.add(currentContact.Domain__c);
			}
		}

		//Check if the domain exists or is net new.
		if(!newDomainSet.isEmpty()){
			domainURLsToDomainMap = trac_DomainUtils.getDomains(newDomainSet);

		}

		if(!domainURLsToDomainMap.isEmpty()){
			for(Contact currentContact : contactList){
				Domain__c currentDomain = domainURLsToDomainMap.get(currentContact.Domain__c);

				if(currentDomain != null){
					if(String.isBlank(currentDomain.Account__c)){
						currentContact.Domain_Lookup__c = currentDomain.Id;
						currentDomain.Account__c = currentContact.AccountId;
						domainsToUpdate.add(currentDomain);
					} else{
						if(currentContact.AccountId != currentDomain.Account__c){
							currentContact.addError('The domain is currently associated with another account.');
						} else{
							currentContact.Domain_Lookup__c = currentDomain.Id;
						}
					}
				}
			}
		}

		if(!domainsToUpdate.isEmpty()){
			update domainsToUpdate;
		}
	}
}