/**
 * Author:
 * Jonatas Barbosa, Traction on Demand
 *
 * Description:
 * Server-side controller for the Account Alignment Indicator.
 *
 * Revision History:
 * Jun/08/2020 - Jonatas Barbosa, Traction on Demand - File created
 */
public without sharing class AccountAlignmentIndicatorCtlr {

    public final Boolean showMessage { get; set; }

    public AccountAlignmentIndicatorCtlr(ApexPages.StandardController controller) {
        String currentRecordId = controller.getId();
        DescribeSObjectResult currentRecordDescribe = controller.getRecord().getSObjectType().getDescribe();
        String currentRecordName = currentRecordDescribe.getName();
        String currentRecordLabel = currentRecordDescribe.getLabel();

        SObject currentRecordWithFields = getCurrentRecordWithFields(currentRecordId, currentRecordName);
        List<Queue_Owner_Change__c> queueRecords = getQueueRecords(currentRecordWithFields, currentRecordLabel);

        this.showMessage = (queueRecords.size() > 0);
    }

    private SObject getCurrentRecordWithFields(Id currentRecordId, String currentRecordName) {
        String query = getCurrentRecordQuery(currentRecordName, currentRecordId);

        return Database.query(query);
    }

    private String getCurrentRecordQuery(String currentRecordName, Id currentRecordId) {
        String query = 'SELECT Id, ';
        if (isLeadOrContact(currentRecordName)) {
            query += 'Domain_Lookup__c, Domain_Lookup__r.Account__c ';
        } else if (isDomain(currentRecordName)) {
            query += 'Account__c ';
        }
        query += 'FROM ' + currentRecordName + ' WHERE Id = :currentRecordId';

        return query;
    }

    private List<Queue_Owner_Change__c> getQueueRecords(SObject currentRecordWithFields, String currentRecordLabel) {
        String query = getQueueRecordsQuery(currentRecordLabel);
        String accountLookup = getAccountLookup(currentRecordLabel, currentRecordWithFields);
        String domainLookup = getDomainLookup(currentRecordLabel, currentRecordWithFields);
        String sourceTypeAccount = trac_Constants.QOC_SOURCE_TYPE_ACCOUNT;
        String sourceTypeDomain = trac_Constants.QOC_SOURCE_TYPE_DOMAIN;

        return Database.query(query);
    }

    private String getQueueRecordsQuery(String currentRecordLabel) {
        String query = 'SELECT Id FROM Queue_Owner_Change__c ';

        if (isLeadOrContact(currentRecordLabel)) {
            query += 'WHERE ( Source_Type__c = :sourceTypeDomain AND Target_Type__c = :currentRecordLabel AND Source_Id__c = :domainLookup ) ';
            query += 'OR ( Source_Type__c = :sourceTypeAccount AND Target_Type__c = :currentRecordLabel AND Source_Id__c = :accountLookup )';
        } else if (isDomain(currentRecordLabel)) {
            query += 'WHERE Source_Type__c = :sourceTypeAccount AND Target_Type__c = :currentRecordLabel AND Source_Id__c = :accountLookup';
        }

        return query;
    }

    private String getAccountLookup(String currentRecordLabel, SObject currentRecordWithFields) {
        if (isLeadOrContact(currentRecordLabel)) {
            SObject domainLookup = currentRecordWithFields.getSObject('Domain_Lookup__r');
            if (domainLookup != null) {
                return String.valueOf(domainLookup.get('Account__c'));
            }
        } else if (isDomain(currentRecordLabel)) {
            return String.valueOf(currentRecordWithFields.get('Account__c'));
        }

        return null;
    }

    private String getDomainLookup(String currentRecordLabel, SObject currentRecordWithFields) {
        if (isLeadOrContact(currentRecordLabel)) {
            return String.valueOf(currentRecordWithFields.get('Domain_Lookup__c'));
        }

        return null;
    }

    private Boolean isLeadOrContact(String recordNameOrLabel) {
        return recordNameOrLabel == 'Contact' || recordNameOrLabel == 'Lead';
    }

    private Boolean isDomain(String recordNameOrLabel) {
        return recordNameOrLabel == 'Domain' || recordNameOrLabel == 'Domain__c';
    }
}