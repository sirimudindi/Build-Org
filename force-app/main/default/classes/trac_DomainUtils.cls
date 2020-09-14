/**
 * Helper class for trac_IntegrationLeadProcessing class
 * and potentially any other class that may require domain assignment.
 *
 * @author Sergei Dobrianski
 * @company Traction on Demand
 * @version 1.0
 * @date 09/24/2014
**/
public without sharing class trac_DomainUtils {

    public trac_DomainUtils() {}
    

    /**
     * Returns all the domains required for lead.Domain_Lookup__c mapping
     *
     * @param Set<String> domainUrl - unique domain url names
     * @return Map<String, Domain__c> 
    **/
    public static Map<String, Domain__c> getDomains(Set<String> domainUrls) {

    	Map<String, Domain__c> existingDomains = new Map<String, Domain__c>();
    	trac_DomainUtils dUtils = new trac_DomainUtils();

    	if(!(existingDomains = dUtils.getExistingDomains(domainUrls)).isEmpty()) {
    		Set<String> nNewDomainsUrls = new Set<String>();
    		for(String domainUrl : domainUrls) {
    			if( !existingDomains.containsKey(domainUrl) ) {
    				nNewDomainsUrls.add(domainUrl);
    			}
    		}

    		for(Domain__c d : dUtils.getNetNewDomains(nNewDomainsUrls).values()) {
    			existingDomains.put(d.Domain_Name_URL__c, d);
    		}

    	} else {
    		return dUtils.getNetNewDomains(domainUrls);
    	}


    	return existingDomains;
    }

    /**
     * Returns all the domains required for lead.Domain_Lookup__c mapping.
     *
     * @param Set<String> domainUrl - unique domain url names
     * @return Map<String, Domain__c> 
    **/
    public Map<String, Domain__c> getExistingDomains(Set<String> domainUrls) {

    	Map<String, Domain__c> rDomains = new Map<String, Domain__c>();

    	for(Domain__c d : [SELECT Id, OwnerId, Domain_Name_URL__c, Domain__c.Account__c, Domain__c.Account__r.Name FROM Domain__c WHERE Domain_Name_URL__c IN : domainUrls AND Domain_Name_URL__c != null]) {
    		rDomains.put( d.Domain_Name_URL__c, d );
    	}

    	return rDomains;
    }

    /**
     * Create domains and returns the netNew domains for Lead.Domain_Lookup__c mapping.
     *
     * @param Set<String> domainsUrls - unique domain url names
     * @return Map<String, Domain__c>
    **/
    public Map<String, Domain__c> getNetNewDomains(Set<String> domainUrls) {

    	Map<String, Domain__c> rDomains = new Map<String, Domain__c>();

    	for(String domainUrl : domainUrls) {
    		rDomains.put(domainUrl, 
    			new Domain__c(Name = domainUrl, Domain_Name_URL__c = domainUrl)
    		);
    	}

    	if( !rDomains.isEmpty() ) {
    		insert rDomains.values();
    	}

    	return rDomains;
    }

}