/**
 * Created by akong on 1/4/2019.
 * Modified by afee on 7/17/2019 (SMT003-51)
 */
global with sharing class trac_QueueDomainLeadOwnerBatch implements Database.Batchable<sObject>,Database.Stateful {
    global Map<String, Queue_Owner_Change__c> queueMap = new Map<String, Queue_Owner_Change__c>();
    global Map<String, Queue_Owner_Change__c> sourceRecordsToQueueMap = new Map<String, Queue_Owner_Change__c>();
    global Map<String, String> lookupFieldBySourceObject = new Map<String, String>{ trac_Constants.QOC_SOURCE_TYPE_ACCOUNT => 'Domain_Account_ID__c', trac_Constants.QOC_SOURCE_TYPE_DOMAIN => 'Domain_Lookup__c' };
    global Set<String> sourceRecordsId = new Set<String>();
    global String query;
    global String targetType = trac_Constants.QOC_TARGET_TYPE_LEAD;
    global String sourceType;

    global trac_QueueDomainLeadOwnerBatch(String sourceType) {
        this.sourceType = sourceType;
        this.queueMap = new Map<String, Queue_Owner_Change__c>([SELECT Id, Name, Source_Type__c, Source_Id__c, Target_Type__c, New_Owner_Id__c
        FROM Queue_Owner_Change__c
        WHERE Source_Type__c = :sourceType
        AND Target_Type__c = :targetType
        ORDER BY CreatedDate ASC
        LIMIT 200]);
        if (!queueMap.isEmpty()) {
            for (Queue_Owner_Change__c qoc : queueMap.values()) {
                sourceRecordsToQueueMap.put(qoc.Source_Id__c.substring(0, 15), qoc);
            }
            sourceRecordsId = sourceRecordsToQueueMap.keySet();
        }

        query = 'SELECT Id, OwnerId, Domain_Account_ID__c, Domain_Lookup__c ' +
                'FROM ' + targetType + ' ' +
                'WHERE ' + lookupFieldBySourceObject.get(sourceType) + ' IN :sourceRecordsId ' +
                'AND IsConverted = FALSE';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Lead> upLeads = new List<Lead>();
        for (SObject obj : scope) {
            Lead ld = (Lead) obj;
            String ldField = (String) lookupFieldBySourceObject.get(sourceType);
            String ldSourceId = (String) ld.get(ldField);
            Queue_Owner_Change__c qoc = sourceRecordsToQueueMap.get(ldSourceId.substring(0, 15));
            ld.OwnerId = qoc.New_Owner_Id__c;
            ld.Account_Alignment_Trigger_Timestamp__c = Datetime.now();
            upLeads.add(ld);
        }
        if (!upLeads.isEmpty()) {
            update upLeads;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // delete the queue records that we've processed
        delete queueMap.values();

        // check if there are more queue records; restart batch if needed
        List<Queue_Owner_Change__c> moreQueues = [SELECT Id
        FROM Queue_Owner_Change__c
        WHERE Source_Type__c = :sourceType
        AND Target_Type__c = :targetType
        LIMIT 1];
        if (!moreQueues.isEmpty()) {
            // there is more!
            trac_QueueDomainLeadOwnerBatch batch = new trac_QueueDomainLeadOwnerBatch(sourceType);
            Database.executeBatch(batch);
        }
    }

    /**
     * immediately run this batch job if not already running
     */
    global static void runNow(String sourceType) {
        if (!trac_BatchUtils.isBatchRunning(trac_Constants.QOC_BATCH_CLASS_DOMAIN_LEAD_OWNER)) {
            trac_QueueDomainLeadOwnerBatch b = new trac_QueueDomainLeadOwnerBatch(sourceType);
            Database.executeBatch(b);
        }
    }

}