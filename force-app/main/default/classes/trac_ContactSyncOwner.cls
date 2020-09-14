/**
 * trac_ContactSyncOwner
 * sets contact owner to the same user that owns the associated domain
 * @author  Alex Kong, Traction on Demand
 * @date    2018-11-23
 */
public without sharing class trac_ContactSyncOwner {

    public static void syncContactDomainOwner(List<Contact> newContacts, Map<Id,Contact> oldMap) {
        if (trac_KillSwitchUtils.isDisabled('trac_ContactSyncOwner_syncContactDomainOwner'))
            return;

        // init vars
        List<Contact> contactsToProcess = new List<Contact>();
        Set<Id> domainIds = new Set<Id>();
        Map<Id,Domain__c> domainMap = new Map<Id,Domain__c>();

        // filter for contacts to update
        for (Contact c : newContacts) {
            // if domain lookup is not null, and
            //   oldMap doesn't have this contact (insert scenario)
            //   or domain lookup has changed (update scenario)
            //   or owner ID has changed (other update scenario)
            Contact oldContact = oldMap.get(c.Id);
            if (c.Domain_Lookup__c != null &&
                ( oldContact == null ||
                    c.Domain_Lookup__c != oldContact.Domain_Lookup__c ||
                    c.OwnerId != oldContact.OwnerId
                )
            ) {
                contactsToProcess.add(c);
                domainIds.add(c.Domain_Lookup__c);
            }
        }

        if (contactsToProcess.isEmpty() || domainIds.isEmpty()) {
            // nothing to do
            return;
        }

        // retrieve associated domains, feed into map
        domainMap = new Map<Id,Domain__c>([SELECT Id, Name, OwnerId FROM Domain__c WHERE Id IN :domainIds]);

        // loop through contactsToProcess, sync owners
        for (Contact c : contactsToProcess) {
            Domain__c dom = domainMap.get(c.Domain_Lookup__c);
            if (dom == null) {
                continue;
            }
            c.OwnerId = dom.OwnerId;
        }
    }
}