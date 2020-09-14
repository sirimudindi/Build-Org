/**
 * This class will create domains for the new incoming leads with
 * a net new domain.
 *
 * @company Traction on Demand
 * @author Sergei Dobrianski
 * @version 3.0
**/
public without sharing class trac_IntegrationLeadProcessing {

    private List<Lead> leads;
    private Set<String> domainUrls;

    private static Boolean includeLeadOwnerReassignment = true;

    public static Set<String> validProductSet = new Set<String>();

    static {
        for(Insight_Product_Name__c ipn : Insight_Product_Name__c.getAll().values()) {
            if(ipn.ProductName__c != null) {
                validProductSet.add( String.valueOf(ipn.ProductName__c).toLowerCase() );
            }
        }
    }

    /**
     * Constructor used in leadDomainAssignmentOnBeforeInsert method
    **/
    private trac_IntegrationLeadProcessing(List<Lead> leads, Set<String> domainUrls) {
        this.leads = leads;
        this.domainUrls = domainUrls;
    }

    /**
     * Method called from the trac_LeadDispatcher.  Assigns the proper domains to the leads.
     *
     * @param List<Lead> - leads from trac_LeadDispatcher
    **/                 //action - assignLeadDomainBeforeInsert
    public static void assignLeadDomain(List<Lead> leads) {
    

        Set<String> domainUrls = new Set<String>();
        for(Lead l : leads) {
            if( l.Domain__c != null ) {
                domainUrls.add(l.Domain__c);
            }
        }

        if(!domainUrls.isEmpty()) {
            trac_IntegrationLeadProcessing ilp = new trac_IntegrationLeadProcessing(leads, domainUrls);
            ilp.leadDomainAssignmentBeforeInsert();
        }

    }

    /**
     * Assignment of Lead.Domain_Lookup__c and Lead.OwnerId if the domain is in existance.
     * Otherwise a net new domain is created and the Lead.Domain_Lookup__c gets set to the net 
     * new Domain.
    **/
    private void leadDomainAssignmentBeforeInsert() {
        trac_DomainUtils du = new trac_DomainUtils();
        Map<String, Domain__c> existingDomains = du.getExistingDomains(domainUrls);
        Set<String> netNewDomainUrls = new Set<String>();
        for(Lead l : leads) { 

            if(existingDomains.containsKey(l.Domain__c)) {
                l.Domain_Lookup__c  = existingDomains.get(l.Domain__c).Id;
                if(includeLeadOwnerReassignment) {
                    /**
                        Dec 14th, 2014 - Client requested to turn off lead.Owner reassignment.
                        l.OwnerId       = existingDomains.get(l.Domain__c).OwnerId;
                    **/
                }
            } else {
                if(l.Domain__c != null) {
                    netNewDomainUrls.add(l.Domain__c);
                }
            }
        }

        if(!netNewDomainUrls.isEmpty()) {
            Map<String, Domain__c> netNewDomains = du.getNetNewDomains(netNewDomainUrls);
            for(Lead l : leads) {
                if(netNewDomains.containsKey(l.Domain__c)) {
                    l.Domain_Lookup__c = netNewDomains.get(l.Domain__c).Id;
                }
            }
        }
    }

    /**
     * This method will handle the domain changed functionality.  Creates a new domain
     * if the new domain value isn't in existance and map's the domain__c.Id to Lead.Domain_Lookup__c.
     *
     * @param Map<Id, Lead> oldMap, Map<Id, Lead> newMap
    **/
    public static void assignLeadDomain(Map<Id, Lead> oldMap, Map<Id, Lead> newMap) {
        List<Lead> eligibleLeads = new List<Lead>();
        if(!(eligibleLeads = getEligibleLeadsOnDomainUpdate(oldMap, newMap)).isEmpty()) {
            includeLeadOwnerReassignment = false;

            ///////////////////////////////////////////////////////////////
            //finds or creates domain and assigns the Lead.Domain_Lookup__c
            ///////////////////////////////////////////////////////////////
            assignLeadDomain(eligibleLeads);
            ///////////////////////////////////////////////////////////////

        }
    }

    private static List<Lead> getEligibleLeadsOnDomainUpdate(Map<Id, Lead> oldMap, Map<Id, Lead> newMap) {
        List<Lead> eligibleLeads = new List<Lead>();
        for(Lead newLead : newMap.values()) {
            Lead oldLead = oldMap.get(newLead.Id);

            if(newLead.Domain__c != oldLead.Domain__c && newLead.Domain__c != null) {
                eligibleLeads.add(newLead);
            }
        }
        return eligibleLeads;
    } 

    public static void convertLeads(List<Lead> leads) {
        if(validProductSet.isEmpty()) {
            return;
        }
        Set<String> pppIds = new Set<String>();
        for(Lead l : leads) {

            if(l.paymentProfileID__c != null && l.parentPaymentProfileID__c != null && l.Qualified_for_Conversion__c && !String.isBlank(l.productName__c)  && validProductSet.contains(l.productName__c.toLowerCase())) {
                pppIds.add(l.parentPaymentProfileID__c);
            }
        }

        //if(!pppIds.isEmpty()) {
        //    trac_LeadConversionModule.convert(pppIds);
        //}
    }

    public static void convertLeads(Map<Id, Lead> oldMap, Map<Id, Lead> newMap) {
        List<Lead> eligibleLeads = new List<Lead>();
        for(Lead newLead : newMap.values()) {

            Lead oldLead = oldMap.get(newLead.Id);       
            if(newLead.parentPaymentProfileID__c != oldLead.parentPaymentProfileID__c 
                || newLead.productName__c != oldLead.productName__c
                    || newLead.Qualified_for_Conversion__c != oldLead.Qualified_for_Conversion__c) {
                eligibleLeads.add(newLead);
            }
        }
        if(!eligibleLeads.isEmpty()) {
            convertLeads(eligibleLeads);
        }
    }

    /**
     * Masoud.A Pivotal 80797796
     * On Update when Last Activity Date is changed. Run an update on the Domain to populate the Last Activity Date in a field on the Domain record.
    **/
    //public static void syncLeadLastActivityDateWithDomains(Map<Id, Lead> oldLeads, Map<Id, Lead> newLeads){
    //    if (oldLeads == null || newLeads ==null){ return; }

    //    List<Domain__c> lstDLCToUpdate = new List<Domain__c>();

    //    Domain__c dlcToUpdate ;

    //    for(String newLeadId:newLeads.keySet()){ //using LastActivityDate on Lead instead of Last_Activity_Date__c

    //        if (oldLeads.get(newLeadId) !=null &&                 
    //            newLeads.get(newLeadId).LastActivityDate !=null && newLeads.get(newLeadId).Domain_Lookup__c !=null){
                
    //            dlcToUpdate = new Domain__c();
    //            dlcToUpdate.Id = newLeads.get(newLeadId).Domain_Lookup__c;
    //            dlcToUpdate.Last_Activity_Date__c = newLeads.get(newLeadId).LastActivityDate;
    //            lstDLCToUpdate.add(dlcToUpdate);
    //        }                
    //    }

    //    if(lstDLCToUpdate.size()>0){
    //        //update lstDLCToUpdate;
    //    }

    //}
}