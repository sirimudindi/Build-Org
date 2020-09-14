/**
 * trac_CaseToContactAssociation.cls
 * @description This class is used by trac_LeadDispatcher.cls and will associate Case(s) that are already
 *              attached to Leads with the newly created Contact
 * @author      Mike Fransblow
 * @company     Traction On Demand
 * @date        Wed May 25 08:26:04 2016
 */


public with sharing class trac_CaseToContactAssociation {

    public static void associateCases(Map<Id, Lead> oldMap, Map<Id, Lead> newMap) {

        Map<Id,Lead> convertedLeads = new Map<Id,Lead>();

        // isolate only those leads that were converted recently and contain a contact id
        for( Lead thisLead : newMap.values() ) {
            if( thisLead.isConverted &&
                thisLead.ConvertedContactId != null &&
                thisLead.ConvertedContactId != oldMap.get(thisLead.Id).ConvertedContactId ){
                    convertedLeads.put(thisLead.Id,thisLead);
            }
        }

        if( convertedLeads.isEmpty() ){
            return;
        }

        // get all cases attached to the converted leads
        List<Case> existingCases = [select Id, Lead__c, ContactId from Case where Lead__c in :convertedLeads.keySet() ];
        if( existingCases.isEmpty() ){
            return;
        }

        // create a list of cases to update
        List<Case> casesToUpdate = new List<Case>();

        // iterate over cases, if we find a match in convertedLeads,
        // update the case with the contact id
        for( Case c : existingCases ) {
            if( convertedLeads.containsKey(c.Lead__c) && c.ContactId == null ){
                c.ContactId = convertedLeads.get(c.Lead__c).ConvertedContactId;
                c.Original_Case_Lead__c = convertedLeads.get(c.Lead__c).FirstName + ' ' + convertedLeads.get(c.Lead__c).LastName; // preserve association of Case to Lead using F/L Name
                c.Lead__c = null;
                casesToUpdate.add(c);
            }
        }

        if( !casesToUpdate.isEmpty() ){
            update casesToUpdate;
        }

    }
}