/**
 * trac_CaseToLeadAssociation.cls
 * @description This class is used by trac_CaseDispatcher.cls and will associate a Case to a Lead
 *              using Case.Lead__c as the lookup.
 *              Association rules:
 *                - only if there is no existing match already on Contact
 *                - only if there is a single match on Lead, if there is more than one Lead matched the
 *                  association is not created
 *              See https://developer.salesforce.com/page/Autocreating_Contacts_From_Web_To_Case?language=en for more info
 * @author      Mike Fransblow
 * @company     Traction On Demand
 * @date        Fri May 13 09:47:27 2016
 */


public with sharing class trac_CaseToLeadAssociation {

    public static void associateCaseToLead(List<Case> caseList){

        // Create a set of all incoming case emails, exclude any cases where the contact has already been
        // associated by SF, or a Lead lookup has already been assigned, during email-to-case or web-to-case or other
        List<String> emailAddresses = new List<String>();
        for (Case caseObj : caseList) {
            if ( qualifiesForLeadAssociation( caseObj ) ){
                emailAddresses.add(caseObj.SuppliedEmail);
            }
        }

        // Create a List of all matched contacts in the emailAddresses list
        List<Contact> listContacts = [Select Id,Email From Contact Where Email in :emailAddresses];
        Set<String> takenEmails = new Set<String>();
        for (Contact c:listContacts) {
            takenEmails.add(c.Email);
        }

        // Create list of cases without contacts or leads assigned, these will be used to attempt a match on Leads
        List<Case> casesWithoutContacts = new List<Case>();
        for (Case caseObj : caseList) {
            if ( qualifiesForLeadAssociation( caseObj )  && !takenEmails.contains( caseObj.SuppliedEmail ) ) {
                //The case was created without a matched contact
                casesWithoutContacts.add(caseObj);
            }
        }

        // Create a map of leads using email address as key
        // If the lead exists more than once, then add the lead to the list in the map
        // This will allow us to determine number of leads for a given email address
        Map<String,List<Lead>> mapLeads = new Map<String,List<Lead>>();
        List<Lead> listLeads = [select Id, Email from Lead where Email in :emailAddresses];

        for(Lead thisLead : listLeads) {
            if( mapLeads.containsKey( thisLead.Email.toLowerCase() )){
                mapLeads.get(thisLead.Email.toLowerCase()).add(thisLead);
            }
            else{
               mapLeads.put(thisLead.Email.toLowerCase(),new List <Lead> { thisLead });
            }
        }

        // Loop through casesWithoutContacts, if the email matches a key in mapLeads
        // and the lead list size in the map is equal to one (ie there is only one lead with the matching email address)
        // update the case with a lookup to the lead
        for ( Case thisCase : casesWithoutContacts ){
            if (  mapLeads.containsKey( thisCase.SuppliedEmail.toLowerCase() ) && mapLeads.get( thisCase.SuppliedEmail.toLowerCase() ).size() == 1   ){
                thisCase.Lead__c = mapLeads.get( thisCase.SuppliedEmail.toLowerCase() )[0].Id;
            }
        }

    }

    public static Boolean qualifiesForLeadAssociation( Case caseObj ){
        return caseObj.ContactId==null && String.isNotEmpty( caseObj.SuppliedEmail ) && caseObj.Lead__c==null;
    }

}