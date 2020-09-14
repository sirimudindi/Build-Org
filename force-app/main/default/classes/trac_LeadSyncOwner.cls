/**
 * trac_LeadSyncOwner
 * sets lead owner to the same user that owns the associated domain
 * @author  Alex Kong, Traction on Demand
 * @date    2018-11-25
 */

public with sharing class trac_LeadSyncOwner {

//    @TestVisible private static Lead_Owner_Queue_Mapping__mdt ownerQueueMap;
//    public final static String LEAD_UNASSIGNED_QUEUE_MDT = 'Lead_Unassigned_Queue';
//
    public static void syncLeadDomainOwner(List<Lead> newLeads, Map<Id,Lead> oldMap) {
//
        if (trac_KillSwitchUtils.isDisabled('trac_LeadSyncOwner_syncLeadDomainOwner'))
            return;
//
//        // init vars
//        List<Lead> leadsToProcess = new List<Lead>();
//        Set<Id> domainIds = new Set<Id>();
//        Map<Id,Domain__c> domainMap = new Map<Id,Domain__c>();
//
//        // filter for leads to update
//        for (Lead ld : newLeads) {
//            // if domain lookup is not null, and
//            //   oldMap doesn't have this lead (insert scenario)
//            //   or domain lookup has changed (update scenario)
//            //   or owner ID has changed (other update scenario)
//            Lead oldLead = oldMap.get(ld.Id);
//            if (ld.Domain_Lookup__c != null &&
//                ( oldLead == null ||
//                    ld.Domain_Lookup__c != oldLead.Domain_Lookup__c ||
//                    ld.OwnerId != oldLead.OwnerId
//                )
//            ) {
//                leadsToProcess.add(ld);
//                domainIds.add(ld.Domain_Lookup__c);
//            }
//        }
//
//        if (leadsToProcess.isEmpty() || domainIds.isEmpty()) {
//            // nothing to do
//            return;
//        }
//
//        // retrieve associated domains, feed into map
//        domainMap = new Map<Id,Domain__c>([SELECT Id, Name, OwnerId FROM Domain__c WHERE Id IN :domainIds]);
//
//        // loop through leadsToProcess, sync owners
//        List<Lead> bulkFutureUpdates = new List<Lead>();
//        for (Lead ld : leadsToProcess) {
//            Domain__c dom = domainMap.get(ld.Domain_Lookup__c);
//            if (dom == null) {
//                continue;
//            }
//            if (!assignedToUnassignedQueue(ld, bulkFutureUpdates)) {
//                // we did not assign to unassigned queue, force the lead owner Id to the domain owner Id
//                ld.OwnerId = dom.OwnerId;
//            }
//        }
//        if (!bulkFutureUpdates.isEmpty()) {
//            if (!System.isBatch() && !System.isFuture() && !System.isQueueable()) {
//                updateUnassignedQueueLeadsFuture(JSON.serialize(bulkFutureUpdates));
//            }
//        }
    }
//
//    private static Boolean assignedToUnassignedQueue(Lead ld, List<Lead> bulkFutureUpdates) {
//        Boolean retval = false;
//        // check custom metadata type Lead_Owner_Queue_Mapping__mdt
//        if (ownerQueueMap == null) {
//            List<Lead_Owner_Queue_Mapping__mdt> ownerQueueMaps = [SELECT Id, DeveloperName, Owner_Id__c, Group_Id__c
//                                                                    FROM Lead_Owner_Queue_Mapping__mdt
//                                                                    WHERE DeveloperName = :LEAD_UNASSIGNED_QUEUE_MDT];
//            if (!ownerQueueMaps.isEmpty()) {
//                ownerQueueMap = ownerQueueMaps[0];
//            }
//        }
//        if (ownerQueueMap != null) {
//            String leadOwnerId = String.valueOf(ld.OwnerId);
//            if (leadOwnerId == ownerQueueMap.Owner_Id__c) {
//                // lead owner matches Owner_Id__c from the custom metadata, assign to queue!
//                //ld.OwnerId = Id.valueOf(ownerQueueMap.Group_Id__c);
//                bulkFutureUpdates.add(new Lead(Id=ld.Id, OwnerId=Id.valueOf(ownerQueueMap.Group_Id__c)));
//                ld.OwnerId = Id.valueOf(ownerQueueMap.Group_Id__c);
//                retval = true;
//            } else if (leadOwnerId == ownerQueueMap.Group_Id__c) {
//                // lead owner already matches Group_Id__c
//                retval = true;
//            }
//        }
//        return retval;
//    }
//
//    @Future
//    private static void updateUnassignedQueueLeadsFuture(String serializedLeads) {
//        List<Lead> bulkFutureLeads = (List<Lead>)JSON.deserialize(serializedLeads, List<Lead>.class);
//        if (!bulkFutureLeads.isEmpty()) {
//            update bulkFutureLeads;
//        }
//    }
}