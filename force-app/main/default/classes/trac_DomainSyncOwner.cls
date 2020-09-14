/**
 * trac_DomainSyncOwner
 * methods to syncrhonize domain owner
 * @author  Alex Kong, Traction on Demand
 * @date    2018-11-23
 */
public with sharing class trac_DomainSyncOwner {
    /**
     * syncDomainAccountOwner
     * sets domain owner on insert of domain, or on change to account lookup
     * @param newDomains
     * @param oldMap
     */
    public static void syncDomainAccountOwner(List<Domain__c> newDomains, Map<Id,Domain__c> oldMap) {
        if (trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_syncDomainAccountOwner') && !Test.isRunningTest())
            return;

        // init vars
        List<Domain__c> domainsToProcess = new List<Domain__c>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Account> accountMap = new Map<Id,Account>();

        // filter for domains to update
        for (Domain__c dm : newDomains) {
            // if account lookup is not null, and
            //   oldMap doesn't have this domain (insert scenario) or
            //   account lookup has changed (update scenario 1) or
            //   ownerId has changed (updated scenario 2)
            Domain__c oldDomain = oldMap.get(dm.Id);
            if (dm.Account__c != null && (
                    oldDomain == null ||
                    dm.Account__c != oldDomain.Account__c ||
                    dm.OwnerId != oldDomain.OwnerId)
            ) {
                domainsToProcess.add(dm);
                accountIds.add(dm.Account__c);
            }
        }

        if (domainsToProcess.isEmpty() || accountIds.isEmpty()) {
            // nothing to do
            return;
        }

        // retrieve associated domains, feed into map
        accountMap = new Map<Id,Account>([SELECT Id, OwnerId, Account_Type__c, Business_Development_Rep__c FROM Account WHERE Id IN :accountIds]);

        // loop through domainsToProcess, sync owners
        for (Domain__c dm : domainsToProcess) {
            Account acc = accountMap.get(dm.Account__c);
            if (acc == null) {
                continue;
            } else if (acc.Account_Type__c == trac_Constants.ACCOUNT_TYPE_STRATEGIC_ACCOUNT && acc.Business_Development_Rep__c != null) {
                dm.OwnerId = acc.Business_Development_Rep__c;
            } else {
                dm.OwnerId = acc.OwnerId;
            }
        }
    }

    /**
     * queueDomainOwnerChange
     * on change of owner, queue domain owner change in Queue_Owner_Change__c
     * @param newDomains
     * @param oldMap
     */
    public static void queueDomainOwnerChange(List<Domain__c> newDomains, Map<Id,Domain__c> oldMap) {
        if (trac_KillSwitchUtils.isDisabled('trac_DomainSyncOwner_queueDomainOwnerChange') && !Test.isRunningTest())
            return;

        // init vars
        List<Queue_Owner_Change__c> queueRecords = new List<Queue_Owner_Change__c>();

        // filter for domains to update
        for (Domain__c dm : newDomains) {
            if (dm.Account_Alignment_Trigger_Timestamp__c != null && (((Datetime.now().getTime() - dm.Account_Alignment_Trigger_Timestamp__c.getTime()) / 1000) / 60) < 1) { // If the Account Alignment Trigger has just run, then don't create a new Queue record
                continue;
            }
            // if owner has changed
            Domain__c oldDomain = oldMap.get(dm.Id);
            if (oldDomain != null && dm.OwnerId != oldDomain.OwnerId) {
                queueRecords.add(
                        new Queue_Owner_Change__c(
                                Source_Id__c = String.valueOf(dm.Id),
                                Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_DOMAIN,
                                Target_Type__c = trac_Constants.QOC_TARGET_TYPE_CONTACT,
                                New_Owner_Id__c = String.valueOf(dm.OwnerId)
                        )
                );
                queueRecords.add(
                        new Queue_Owner_Change__c(
                                Source_Id__c = String.valueOf(dm.Id),
                                Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_DOMAIN,
                                Target_Type__c = trac_Constants.QOC_TARGET_TYPE_LEAD,
                                New_Owner_Id__c = String.valueOf(dm.OwnerId)
                        )
                );
            }
        }
        if (!queueRecords.isEmpty()) {
            insert queueRecords;

            // launch domain-type qoc batch jobs if not currently in async context
            if (!System.isBatch() && !System.isFuture() && !System.isQueueable()) {
                trac_QueueDomainContactOwnerBatch.runNow(trac_Constants.QOC_SOURCE_TYPE_DOMAIN);
                trac_QueueDomainLeadOwnerBatch.runNow(trac_Constants.QOC_SOURCE_TYPE_DOMAIN);
            }
        }
    }

//    /**
//     * @author  Mani Mahal , Traction on Demand
//     * @date    2018-09-16
//     * on change of SyncOnwerIndicator on Domain, update SyncOwnerIndicator on related Account
//     * @param newDomains
//     * @param oldMap
//     */
//    public static void updateSyncOwnerAccount(List<Domain__c> newDomains, Map<Id, Domain__c> oldMap) {
//        List<Account> accToUpdate = new List<Account>();
//
//        for(Domain__c domain: newDomains) {
//            Domain__c oldDomain = oldMap.get(domain.Id);
//            if(domain.SyncOwnerLeadIndicatorJob__c != oldDomain.SyncOwnerLeadIndicatorJob__c || domain.SyncOwnerContactIndicatorJob__c != oldDomain.SyncOwnerContactIndicatorJob__c) {
//                if(domain.SyncOwnerLeadIndicatorJob__c == true || domain.SyncOwnerContactIndicatorJob__c == true) {
//                    accToUpdate.add(new Account(Id = domain.Account__c, SyncOwnerIndicatorJob__c = true, SyncOwnerQueueJob__c = false));
//                    break;
//                } else {
//                    accToUpdate.add(new Account(Id=domain.Account__c, SyncOwnerIndicatorJob__c = false ));
//                }
//            }
//        }
//
//        if(!accToUpdate.isEmpty()) {
//            update accToUpdate[0];
//        }
//    }
}