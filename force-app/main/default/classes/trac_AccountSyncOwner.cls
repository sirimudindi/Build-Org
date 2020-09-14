/**
 * trac_AccountSyncOwner
 * methods to syncrhonize account owner
 * @author  Alex Kong, Traction on Demand
 * @date    2018-12-31
 */
public with sharing class trac_AccountSyncOwner {
    private static Set<String> queuedChanges = new Set<String>();

    /**
     * queueAccountOwnerChange
     * on change of account owner, insert appropraite Queue_Owner_Change__c records
     * @param newAccounts
     * @param oldMap
     */
    public static void queueAccountOwnerChange(List<Account> newAccounts, Map<Id,Account> oldMap) {
        if (trac_KillSwitchUtils.isDisabled('trac_AccountSyncOwner_queueAccountOwnerChange'))
            return;

        // init vars
        List<Queue_Owner_Change__c> queueRecords = new List<Queue_Owner_Change__c>();

        // filter for accounts to update
        for (Account acc : newAccounts) {
            // if owner, account type or business development rep have changed,
            Account oldAccount = oldMap.get(acc.Id);
            if (oldAccount != null) {
                // updates only
                if ((acc.OwnerId != oldAccount.OwnerId || acc.Account_Type__c != oldAccount.Account_Type__c)
                        && acc.Account_Type__c != trac_Constants.ACCOUNT_TYPE_STRATEGIC_ACCOUNT)
                {
                    // ownerId has changed or account type has changed, and it's not a strategic account
                    //   so cascade update the ownerId to related domains
                    String hash = String.valueOf(acc.Id) + '|' + trac_Constants.QOC_SOURCE_TYPE_ACCOUNT + '|' + String.valueOf(acc.OwnerId);
                    if (!queuedChanges.contains(hash)) {
                        queueRecords.add(
                                new Queue_Owner_Change__c(
                                        Source_Id__c = String.valueOf(acc.Id),
                                        Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT,
                                        Target_Type__c = trac_Constants.QOC_TARGET_TYPE_DOMAIN,
                                        New_Owner_Id__c = String.valueOf(acc.OwnerId)
                                )
                        );
                        queueRecords.add(
                                new Queue_Owner_Change__c(
                                        Source_Id__c = String.valueOf(acc.Id),
                                        Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT,
                                        Target_Type__c = trac_Constants.QOC_TARGET_TYPE_CONTACT,
                                        New_Owner_Id__c = String.valueOf(acc.OwnerId)
                                )
                        );
                        queueRecords.add(
                                new Queue_Owner_Change__c(
                                        Source_Id__c = String.valueOf(acc.Id),
                                        Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT,
                                        Target_Type__c = trac_Constants.QOC_TARGET_TYPE_LEAD,
                                        New_Owner_Id__c = String.valueOf(acc.OwnerId)
                                )
                        );
                        queuedChanges.add(hash);
                    }
                } else if ((acc.Business_Development_Rep__c != oldAccount.Business_Development_Rep__c || acc.Account_Type__c != oldAccount.Account_Type__c || acc.OwnerId != oldAccount.OwnerId)
                        && acc.Account_Type__c == trac_Constants.ACCOUNT_TYPE_STRATEGIC_ACCOUNT)
                {
                    // business development rep has changed or account type has changed, and it is a strategic account
                    //   so cascade update the business development rep to related domains
                    Id newOwnerId = acc.Business_Development_Rep__c != null ? acc.Business_Development_Rep__c : acc.OwnerId;
                    String hash = String.valueOf(acc.Id) + '|' + trac_Constants.QOC_SOURCE_TYPE_ACCOUNT + '|' + String.valueOf(newOwnerId);
                    if (!queuedChanges.contains(hash)) {
                        queueRecords.add(
                                new Queue_Owner_Change__c(
                                        Source_Id__c = String.valueOf(acc.Id),
                                        Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT,
                                        Target_Type__c = trac_Constants.QOC_TARGET_TYPE_DOMAIN,
                                        New_Owner_Id__c = String.valueOf(newOwnerId)
                                )
                        );
                        queueRecords.add(
                                new Queue_Owner_Change__c(
                                        Source_Id__c = String.valueOf(acc.Id),
                                        Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT,
                                        Target_Type__c = trac_Constants.QOC_TARGET_TYPE_CONTACT,
                                        New_Owner_Id__c = String.valueOf(newOwnerId)
                                )
                        );
                        queueRecords.add(
                                new Queue_Owner_Change__c(
                                        Source_Id__c = String.valueOf(acc.Id),
                                        Source_Type__c = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT,
                                        Target_Type__c = trac_Constants.QOC_TARGET_TYPE_LEAD,
                                        New_Owner_Id__c = String.valueOf(newOwnerId)
                                )
                        );
                        queuedChanges.add(hash);
                    }
                }
            }
        }
        if (!queueRecords.isEmpty()) {
            insert queueRecords;

            // now run the account owner batch job if not already running
            trac_QueueAccountOwnerBatch.runNow();
        }
    }
}