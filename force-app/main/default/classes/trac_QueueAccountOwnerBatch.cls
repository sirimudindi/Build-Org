/**
 * trac_QueueAccountOwnerBatch
 * batch apex class to convert account-type Queue_Owner_Batch__c records to domain-type
 * @author  Alex Kong, Traction on Demand
 * @date    2018-12-21
 */
global class trac_QueueAccountOwnerBatch implements Database.Batchable<sObject> {
    global String query;

    global trac_QueueAccountOwnerBatch() {
        query = 'SELECT Id, Name, Source_Type__c, Source_Id__c, New_Owner_Id__c ' +
                'FROM Queue_Owner_Change__c ' +
                'WHERE Source_Type__c = \'' + trac_Constants.QOC_SOURCE_TYPE_ACCOUNT + '\' ' +
                'AND Target_Type__c = \'' + trac_Constants.QOC_TARGET_TYPE_DOMAIN + '\' ' +
                'ORDER BY CreatedDate ASC';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Queue_Owner_Change__c> scope) {
        if (scope.isEmpty()) {
            return;
        }

        Map<Id,Id> mapAccountIdToOwnerId = new Map<Id,Id>();
        Set<Id> accountIds = new Set<Id>();
        List<Domain__c> relatedDomains = new List<Domain__c>();
        for (Queue_Owner_Change__c queue : scope) {
            if (String.isBlank(queue.Source_Id__c)) {
                continue;
            }
            mapAccountIdToOwnerId.put(Id.valueOf(queue.Source_Id__c), queue.New_Owner_Id__c);
            accountIds.add(queue.Source_Id__c);
        }
        if (accountIds.isEmpty() || mapAccountIdToOwnerId.isEmpty()) {
            return;
        }

        relatedDomains = [SELECT Id, Account__c FROM Domain__c WHERE Account__c IN :accountIds];
        if (relatedDomains.isEmpty()) {
            return;
        }
        for (Domain__c dom : relatedDomains) {
            dom.OwnerId = Id.valueOf(mapAccountIdToOwnerId.get(dom.Account__c));
            dom.Account_Alignment_Trigger_Timestamp__c = Datetime.now();
        }
        // update the owner ID for the related domains, which will create domain-type qoc records
        update relatedDomains;

        // now delete this batch
        delete scope;
    }

    global void finish(Database.BatchableContext bc) {
        // check if any more; if so, self-perpetuate
        List<Queue_Owner_Change__c> moreQueues = [SELECT Id FROM Queue_Owner_Change__c WHERE Source_Type__c = :trac_Constants.QOC_SOURCE_TYPE_ACCOUNT AND Target_Type__c = :trac_Constants.QOC_TARGET_TYPE_DOMAIN LIMIT 1];
        if (!moreQueues.isEmpty() && !Test.isRunningTest()) {
            // there are more account type qoc records to convert to domain type qoc records
            trac_QueueAccountOwnerBatch batch = new trac_QueueAccountOwnerBatch();
            Database.executeBatch(batch);
        } else {
            // there are no more qoc records to convert! fire the domain batch jobs!
            trac_QueueDomainContactOwnerBatch.runNow(trac_Constants.QOC_SOURCE_TYPE_ACCOUNT);
            trac_QueueDomainLeadOwnerBatch.runNow(trac_Constants.QOC_SOURCE_TYPE_ACCOUNT);
        }
    }

    /**
     * immediately run this batch job if not already running
     */
    global static void runNow() {
        if (!trac_BatchUtils.isBatchRunning(trac_Constants.QOC_BATCH_CLASS_ACCOUNT_OWNER)) {
            trac_QueueAccountOwnerBatch b = new trac_QueueAccountOwnerBatch();
            Database.executeBatch(b);
        }
    }
}