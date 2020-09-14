global class trac_CasesEmailTemplate implements QuickAction.QuickActionDefaultsHandler {

    @Testvisible public static String DEFAULT_CASE_TEMPLATE = 'Default_Case_Email_Template';
    @Testvisible public static String DEFAULT_CASE_TEMPLATE_BASIC = 'Default_Case_Email_Template_Basic';

    Id organizationId = UserInfo.getOrganizationId();

    @TestVisible
    List<trac_outbound_email_mapping__mdt> outboundEmailMappings = [SELECT org_id__c, inbound__c, outbound__c, group__c FROM trac_outbound_email_mapping__mdt WHERE org_id__c = :organizationId];
    Map<String, List<trac_outbound_email_mapping__mdt>> outboundEmailsMap = new Map<String, List<trac_outbound_email_mapping__mdt>>();

    List<String> caseEmailActionNames = new List<String>();


    global trac_CasesEmailTemplate() {

        //custom metadata type contains the names of Case Email Actions for which we will apply this custom logic
        List<trac_case_email_action__mdt> caseEmailActions = [SELECT Action_Name__c FROM trac_case_email_action__mdt];
        for (trac_case_email_action__mdt action : caseEmailActions) {
            caseEmailActionNames.add(action.Action_Name__c.toLowerCase());
        }
    }

    // The main interface method
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults) {
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;
        
        // Check if the quick action is the standard Case Feed send email action
        for (Integer j = 0; j < defaults.size(); j++) {
            String actionName = defaults.get(j).getActionName().toLowerCase();

            if (defaults.get(j) instanceof QuickAction.SendEmailQuickActionDefaults &&
                defaults.get(j).getTargetSObject().getSObjectType() == EmailMessage.sObjectType &&
                (defaults.get(j).getActionType().equals('Email') || defaults.get(j).getActionType().equals('SendEmail')) &&
                caseEmailActionNames.contains(actionName))
                {
                   sendEmailDefaults = (QuickAction.SendEmailQuickActionDefaults)defaults.get(j);
                   break;
                }
        }

        if (sendEmailDefaults != null) {
            outboundEmailsMap = buildOutboundEmailByInboundMail(outboundEmailMappings);

            Case c = [SELECT CaseNumber,Description, Status, Reason, Email_to_Case_Address__c, group__c, First_Response__c, Contact.Email, Lead__c, Lead__r.Email, SuppliedEmail FROM Case WHERE Id=:sendEmailDefaults.getContextId()];
            EmailMessage emailMessage = (EmailMessage)sendEmailDefaults.getTargetSObject();

            // Determine what the FROM address should be based on mappings set in custom metadata (trac_outbound_email_mapping__mdt)
            List<trac_outbound_email_mapping__mdt> outboundAddrs;
            trac_outbound_email_mapping__mdt outboundAddr;
            if( String.isNotBlank(c.Email_to_Case_Address__c) ){
				// c.Email_to_Case_Address__c may contian more than one address ie foo@bar.com,foo2@bar.com etc
				// so we will need to iterate through a comma delimited list and find a match in outboundEmailsMap
                // outboundAddrs= outboundEmailsMap.get(c.Email_to_Case_Address__c.toLowerCase());
                outboundAddrs = findOutBoundAddr(outboundEmailsMap,c.Email_to_Case_Address__c.toLowerCase());
                if (outboundAddrs != null){
                    if (outboundAddrs.size() > 1){
                        //case of IOS need to search for group
                        for (trac_outbound_email_mapping__mdt outboundEmail : outboundAddrs){
                            if (c.group__c == outboundEmail.group__c ){
                                outboundAddr = outboundEmail;
                                break;
                            }
                        }
                    } else {
                        if(outboundAddrs.size() > 0){
                            outboundAddr = outboundAddrs[0];
                        }
                    }
                }
				else {
				    // If we cannot find a match in the inbound/outbound, then attempt a match using Case.group__c 
					outboundAddr = getTheOutboundEmailFromGroup(c.group__c);					
				}
            }
            else{
               //match  Case.group__c 
               outboundAddr = getTheOutboundEmailFromGroup(c.group__c);
            }
            if (outboundAddr != null){
                emailMessage.FromAddress = outboundAddr.outbound__c;
            }
            // Set bcc address to make sure each email goes for audit
            //emailMessage.BccAddress = getBccAddress(c.Reason);

            /*
            Set Template related fields
            When the In Reply To Id field is null we know the interface
            is called on page load. Here we check if
            there are any previous emails attached to the case and load
            the 'New_Case_Created' or 'Automatic_Response' template.
            When the In Reply To Id field is not null we know that
            the interface is called on click of reply/reply all
            of an email and we load the 'Default_reply_template' template
            */
            Boolean useTemplate = true;
            if (sendEmailDefaults.getInReplyToId() == null) {
                Integer emailCount = [SELECT count() FROM EmailMessage
                                      WHERE ParentId=:sendEmailDefaults.getContextId() AND Incoming = true];            
                if (emailCount!= null && emailCount  <0) {
                    useTemplate = false;
                }

            }

            if (String.isNotBlank(string.valueof(c.First_Response__c))){
                 useTemplate = false;
            }     
            if (useTemplate) {

                if (c.group__c != 'support'){
                    sendEmailDefaults.setTemplateId(getTemplateIdHelper(DEFAULT_CASE_TEMPLATE_BASIC));
                } else {
                    sendEmailDefaults.setTemplateId(getTemplateIdHelper(DEFAULT_CASE_TEMPLATE));
                }
                sendEmailDefaults.setInsertTemplateBody(true);
                sendEmailDefaults.setIgnoreTemplateSubject(false);
            }

            // Determine the To Address :
            // If a Contact exists on the Case with an email address, email the Contact's email address
            // Else If a Lead exists on the Case with an email address, email the Lead's email address
            // Else Email the Web Email field on the Case
            // DO NOT INVOKE IF REPLYING
            if( sendEmailDefaults.getInReplyToId() == null ){
                if (String.isNotBlank(c.Contact.Email)){
                    emailMessage.ToAddress = c.Contact.Email;
                } else if (String.isNotBlank(c.Lead__r.Email)){
                    emailMessage.ToAddress = c.Lead__r.Email;
                } else if (String.isNotBlank(c.SuppliedEmail)){
                    emailMessage.ToAddress = c.SuppliedEmail;
                } else {
                    //nothing to set To Address to
                }           
            }


        }
    }

    private Trac_outbound_email_mapping__mdt getTheOutboundEmailFromGroup(String caseGroup){
        if (! outboundEmailsMap.isEmpty()){
            for (trac_outbound_email_mapping__mdt outboundInfo : outboundEmailMappings ){
                if (outboundInfo.group__c == caseGroup && String.isEmpty(outboundInfo.inbound__c) ){
                    //securing  case of ios to avoid to do other operation afterwards
                    return outboundInfo;
                }
            }
        }
        return null;
    }

    /** 
    * @description Maps target Job (Parent) to  Job_Team_Member__c
    * @author Anne-Lise Millereux, Traction on Demand
    * @date 2016 July 14
    */
    public static Map<String, List<trac_outbound_email_mapping__mdt>> buildOutboundEmailByInboundMail(List<trac_outbound_email_mapping__mdt> outboundEmails){

        Map<String, List<trac_outbound_email_mapping__mdt>>  outboundEmailMap = new Map<String, List<trac_outbound_email_mapping__mdt>> ();

        for (trac_outbound_email_mapping__mdt outboundEmail : (List<trac_outbound_email_mapping__mdt>) outboundEmails) {

                // if parent Job is not a key, add a new entry with a new list
                if ( ! outboundEmailMap.containsKey(outboundEmail.inbound__c)){

                    outboundEmailMap.put(outboundEmail.inbound__c, new List<trac_outbound_email_mapping__mdt> ()  );
                }
                outboundEmailMap.get(outboundEmail.inbound__c).add(outboundEmail);
        }
        return outboundEmailMap;
    }

    private Id getTemplateIdHelper(String templateApiName) {
        Id templateId = null;
        try {
            templateId = [select id, name from EmailTemplate
                          where developername = : templateApiName].id;
        } catch (Exception e) {
            system.debug('Unable to locate EmailTemplate using name: ' +
                templateApiName + ' refer to Setup | Communications Templates '
                    + templateApiName);
        }
        return templateId;
    }

	// MF: Iterate over either a comma delimited list of emails and return a match in outboundEmailsMap,
	//     or look for an exact match
    @TestVisible
	private List<trac_outbound_email_mapping__mdt> findOutBoundAddr( Map<String, List<trac_outbound_email_mapping__mdt>> outboundEmailsMap, String EmailToCaseAddress ){
		String[] emails = EmailToCaseAddress.split(';');
		List<trac_outbound_email_mapping__mdt> answr = new List<trac_outbound_email_mapping__mdt>();
		if( emails.size() > 1 ){
			for( String e : emails ){
				if( outboundEmailsMap.containsKey(e) ){
					answr = outboundEmailsMap.get( e );
				}
			}
		}
		else {
			answr = outboundEmailsMap.get( EmailToCaseAddress );
		}
		return answr;
	}

}