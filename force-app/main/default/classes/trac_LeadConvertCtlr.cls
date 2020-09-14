/***
* @author: Christian Wico - cwico@tractionondemand.com
* @description: Controller extension for tract_LeadConvert.page
*
* @modifiedBy Sergei Dobrianski
*/
public without sharing class trac_LeadConvertCtlr {

	public final Lead leadRecord {get; private set;}

    public String accountName {get;set;}
    public String opportunityName {get;set;}
    
    public Boolean dontCreateOpp {get;set;}
    public Boolean initComplete {get;set;}
    public Boolean createAccountOfLookup {get; set;}

    public Domain__c domain {get;set;}
    public Domain__c domainAccount {get;set;}
    public String strPPPID {get ; private set;}

    public String oppId {get; private set;}

    public trac_LeadConvertCtlr(ApexPages.StandardController stdController) {
        
        oppId ='';

        strPPPID ='';

        if (initComplete == true) return;
        

        domainAccount = new Domain__c();

        dontCreateOpp = false;

        createAccountOfLookup = false;

        ApexPages.Message noDomainMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No domain found in this lead.');

        //Ticket : 82994180 - remove this QualifiedForConversion check
        //ApexPages.Message notQualifiedForConversation = new ApexPages.Message(ApexPages.Severity.ERROR, 'In order to be able to convert the lead, Qualified for Conversation should be checked.');

        Lead l = (Lead)stdController.getRecord();

        this.leadRecord = [SELECT Id, Name, Status, Company, FirstName, LastName, Domain_Lookup__c, Domain_Lookup__r.Name, Domain_Lookup__r.Domain_Name_URL__c, Domain_Lookup__r.OwnerId,
                                  Qualified_for_Conversion__c, OwnerId, PPPID__c, parentPaymentProfileID__c, Owner.IsActive
                           FROM Lead 
                           WHERE  Id =:l.Id];

        if (this.leadRecord !=null){
            //System.debug('strPPPID is: ' + strPPPID);
            strPPPID = leadRecord.parentPaymentProfileID__c == null || leadRecord.parentPaymentProfileID__c == '' ? '' : leadRecord.parentPaymentProfileID__c;

            opportunityName = leadRecord.Name;
            accountName = leadRecord.Company;

            if (leadRecord.Domain_Lookup__c != null) {
                domain = [SELECT Id, Name, Account__c, Account__r.Name FROM Domain__c WHERE Id = :leadRecord.Domain_Lookup__c LIMIT 1];
                if (domain.Account__c != null) accountName = domain.Account__r.Name;
            } 
            else {
                ApexPages.addMessage(noDomainMsg);
            }

            //Ticket : 82994180 - remove this QualifiedForConversion check
            //if (leadRecord.Qualified_for_Conversion__c == false){
            //    ApexPages.addMessage(notQualifiedForConversation);
            //}
        }

        initComplete = true;
    }

    public PageReference convertLead() {

        String strAccountID ='';
        String strOppID = '';

        Database.LeadConvert lc = new Database.LeadConvert();
        Map<Id ,Lead> attachedLeads ;
        List<Database.LeadConvert> attachedLeadsToConvert = new List<Database.LeadConvert>();

        Boolean updateRequired = false;
        
        if (leadRecord.Status != 'Accepted') {
            leadRecord.Status = 'Accepted';
            updateRequired = true;
        }
        
        // if the owner is a queue use current user as the owner
        if (String.valueOf(leadRecord.OwnerId).startsWith('00G') || !leadRecord.Owner.IsActive) {
            lc.setOwnerId(UserInfo.getUserId());
            leadRecord.OwnerId = UserInfo.getUserId();
            updateRequired = true;
        }

        if (updateRequired) {
            update leadRecord;
        }


        // set lead id
        lc.setLeadId(leadRecord.Id);

        // set account
        if(createAccountOfLookup && domainAccount.Account__c != null) {
            lc.setAccountId(domainAccount.Account__c);
            strAccountID = domainAccount.Account__c;
        } else {

            if (domain != null && domain.Account__c != null) {
                lc.setAccountId(domain.Account__c);
                strAccountID = domain.Account__c;
            }
            else {
                /*
                *  @description check if this account name exist in the system then use it, otherwise create a new account
                *  @author Majeda Mahfuz, Traction on Demand
                *  @date 2014-Oct-27
                *
                *  @modifiedBy Sergei Dobrianski
                *  @modifiedDate 2014-Nov-28
                *  @modifiedTicket : 83361306 - the client does not want to match on Domain__c.Account Name, instead a new account will always be created.
                */
                //String existingAccountId = doesAccountNameExist(accountName);
                //if(String.isNotBlank(existingAccountId)){
                    //lc.setAccountId(existingAccountId);
                    //strAccountID = existingAccountId;
                //}
                //else{
                    // create and set account
                    Account a = new Account(Name = accountName, Domain__c = this.leadRecord.Domain_Lookup__r.Domain_Name_URL__c);

                    insert a;
                    strAccountID = a.Id;

                    lc.setAccountId(a.Id);
                //}
            }

        }



        // set opportunity
        if (dontCreateOpp) {
            lc.setDoNotCreateOpportunity(true);   
        }
        else {
            lc.setOpportunityName(opportunityName);
        } 

        // set status
        LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);        


        Savepoint sp = Database.setSavepoint();
        Boolean thereWasAnError = false;
        String errorMsgCustException = '';
        //********************* convert lead and its attached leads
        try {
           Database.LeadConvertResult cr = Database.convertLead(lc);  

            // display error message if conversion failed
            for (Database.Error err: cr.errors){ 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err.getMessage()));
            }

            // redirect to account if conversion is successful
            if (cr.success) {

                // if the domain account is not set use the created account 
                if(domain !=null && domain.Account__c == null) {
                    update new Domain__c(Id = domain.Id, Account__c = cr.accountId);
                } 

                if (cr.getOpportunityId() !=null){
                    strOppID = cr.getOpportunityId();
                    this.oppId = strOppID;
                    Opportunity opp = [Select Id,OwnerId From Opportunity Where Id=: strOppID];
                    if ( leadRecord !=null && leadRecord.Domain_Lookup__r !=null && leadRecord.Domain_Lookup__r.OwnerId !=null){
                        
                        //Dec 15th, 2014 - opp.OwnerId no longer reasigns to domain__c.Owner on manual lead conversion.
                        //opp.OwnerId = leadRecord.Domain_Lookup__r.OwnerId;

                        //ticket : 83056914
                        opp.StageName = 'Qualify'/*'Pending Close'*/;
                        if (strPPPID !=''){
                            opp.Parent_Payment_Profile_ID__c = strPPPID;
                        }
                        update opp; //Opportunity Owner set to Domain Owner
                    }

                }      
            }else{
                errorMsgCustException += 'Error with leadRecord convert\n';
                thereWasAnError = true;
            }

            //System.debug(strPPPID +'|' +  strAccountID + '|' + cr.success);
            //try to convert the attached leads
            // Commented out the logic which converts the leads which share the same pppid
 /*           if (strPPPID !='' && strAccountID !='' && cr.success){
                List<Lead> leadsToUpdate = new List<Lead>();
                attachedLeads = new Map<Id ,Lead>([Select Id,IsConverted,Status, OwnerId, Owner.IsActive From Lead Where parentPaymentProfileID__c =: strPPPID AND IsConverted = false ]);

                if (attachedLeads !=null && attachedLeads.size() >0 ){
                    for(Lead attachedLead: attachedLeads.values()){
                        updateRequired = false;                 

                        if (attachedLead.Status != 'Accepted'){
                            attachedLead.Status  = 'Accepted';
                            updateRequired       = true;
                        }

                        // if the owner is a queue use current user as the owner
                        if (String.valueOf(attachedLead.OwnerId).startsWith('00G') || !attachedLead.Owner.IsActive) {
                            attachedLead.OwnerId  = UserInfo.getUserId();
                            updateRequired      = true;
                        }

                        if (updateRequired) {
                            leadsToUpdate.add(attachedLead);
                        }

                        Database.LeadConvert lcTemp = new Database.LeadConvert();
                        lcTemp.setLeadId(attachedLead.Id);
                        lcTemp.setAccountId(strAccountID);
                        lcTemp.setConvertedStatus(convertStatus.MasterLabel);
                        lcTemp.setDoNotCreateOpportunity(true);
                        attachedLeadsToConvert.add(lcTemp);
                    }

                    if (leadsToUpdate.size()>0){
                        update leadsToUpdate; //update the status of all the attached fields to Accepted first before conversion
                    }

                    if (attachedLeadsToConvert.size()>0){
                        Set<String> setContactIds = new Set<String>();
                        Database.LeadConvertResult[] crList = Database.convertLead(attachedLeadsToConvert ,false);
                        for(Database.LeadConvertResult lcr: crList ){
                            if (lcr.success){
                                setContactIds.add(lcr.getContactId());
                            }else{
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, lcr.errors[0].getMessage()));
                                thereWasAnError = true;
                                errorMsgCustException += 'Error with conversion of remaining leads.\n';
                                //System.debug('Err ' + lcr.errors[0].getMessage());
                            }
                        }

                        if (thereWasAnError == false && strOppID !='' && strOppID !=null && setContactIds.size()>0){
                            createOppContactRoles(strOppID, setContactIds);
                        }                        
                        //Database.rollback(sp);
                    }
                }
            }
*/
            if (thereWasAnError == true){
                Database.rollback(sp); //rollback the whole operation if there was an error
                if(Test.isRunningTest()) { throw new CustomException(errorMsgCustException); }
            }else{
                 return new PageReference('/' + strAccountID);
            }
            
        }
        catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            System.debug('ERR: ' + e.getMessage() + '|' + e.getStackTraceString() + '|' + e.getLineNumber());
            Database.rollback(sp); //rollback the whole operation if there was an exception

            if(Test.isRunningTest()) { throw new CustomException(e.getMessage()); }

        }
        //************************
        

        return null;
    } 
    /*
    *  @description checks if an account exists with the parameter Name, and it returns the found account Id
    *  @author Majeda Mahfuz, Traction on Demand
    *  @date 2014-Oct-27
    *
    *  @modifiedBy Sergei Dobrianski
    *  @modifiedDate 2014-Nov-28
    *  @modifiedTicket : 83361306 - the client does not want to match on Domain__c.Account Name, instead a new account will always be created.
    */
    //public static String doesAccountNameExist(String accountName){
    //    String thereturn = '';
    //    List<Account> existingList = new List<Account>([
    //        SELECT Id
    //        FROM Account
    //        WHERE Name = : accountName
    //        LIMIT 1]);
    //    if(!existingList.isEmpty()){
    //        thereturn = existingList[0].Id;
    //    }
    //    return thereturn;
    //}

    public static void createOppContactRoles(String oppId,Set<String> setContactIds){
        List<String> lstContacts = new List<String>();
        lstContacts.addAll(setContactIds);
        List<OpportunityContactRole> lstInsertOCR = new List<OpportunityContactRole>();
        OpportunityContactRole ocr ;
        for(String cId:lstContacts){
            ocr = new OpportunityContactRole();
            ocr.ContactId = cId;
            ocr.OpportunityId = oppId;
            lstInsertOCR.add(ocr);
        }
        if (lstInsertOCR.size()>0){
            insert lstInsertOCR;
        }
    }

    class CustomException extends Exception {}
}