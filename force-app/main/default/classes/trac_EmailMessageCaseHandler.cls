/**
 * trac_EmailMessageDispatcher.cls
 * @description Class extends trac_Dispatcher.  Called from trac_EmailMessage.trigger
 * @author      Mike Fransblow
 * @company     Traction On Demand
 * @date        Nov 7 2016
 */

public class trac_EmailMessageCaseHandler { 

	private static final List<EmailServicesAddress> SERVICE_ADDRESSES = [SELECT EmailDomainName,IsActive,LocalPart,RunAsUserId,FunctionId,AuthorizedSenders FROM EmailServicesAddress where LocalPart != 'emailtosalesforce'];
	private static final Service_Settings__c sts = Service_Settings__c.getOrgDefaults();
	private static final List<String> FROM_FILTER = new List<String>{'service@paypal.com'};
	
	public static void reparentExistingEmailMessagesToCases(){

		// isolate those emails which have been addressed to a non-support queue email address,
		// but cc'd to a support queue email address
		List<EmailMessage> emailList = [SELECT Id, toAddress, fromAddress, CcAddress, incoming, headers, ParentId FROM EmailMessage WHERE Id IN :trigger.new];
		
		List<EmailMessage> possibleDupes = new List<EmailMessage>();
		List<EmailMessage> possibleReplyToSelf = new List<EmailMessage>();
	
		for( EmailMessage e : emailList){
			/* 
				Matching algorithm:
				1. Inspect incoming email messages only 
				2. cc address must be to an e2c routing address
				3. to address must NOT be to an e2c service address
				4. must have the header In-Reply-To
				5. cannot be from an entry in the exclusion list
			*/
			if( e.Incoming && 
				String.isNotBlank(e.ToAddress) && 
				String.isNotBlank(e.CcAddress) && 
				!fromExclusionList(e.fromAddress) &&
				!addressedToSupportQueue(e.ToAddress) && 
				addressedToSupportQueue(e.CcAddress) && 
				String.isNotBlank(e.headers) && 
				hasInReplyToHeader(e.headers)  ){

				possibleDupes.add(e);

			}
			/* 
				Matching algorithm:
				1. Inspect incoming email messages only 
				2. to address must be to an e2c service address
				3. must have the header In-Reply-To
				4. cannot be from an entry in the exclusion list
			*/
			if( e.Incoming && 
				String.isNotBlank(e.ToAddress) && 
				!fromExclusionList(e.fromAddress) &&
				addressedToSupportQueue(e.ToAddress) && 
				String.isNotBlank(e.headers) && 
				hasInReplyToHeader(e.headers)  ){

				possibleReplyToSelf.add(e);

			}

		}

		processPossibleDupes(possibleDupes);
		processPossibleReplyToSelf(possibleReplyToSelf);

	}

	private static void processPossibleDupes( List<EmailMessage> possibleDupes ){

		// get all of the Ids of email messages identified in possibleDupes list
		Set<Id> emailMessageIdsInScope = (new Map<Id,SObject>(possibleDupes)).keySet();

		if(possibleDupes.size() <= 0 ){
			return;	
		}
				
		// Create a Map of the In-Reply-To msg header value as Map key, and a List of email msgs that contain that same Map value
		Map<String,List<EmailMessage>> possibleDupeMap = new Map<String,List<EmailMessage>>();
		if( possibleDupes.size() > 0 ){
			for( EmailMessage e : possibleDupes){
				// Get the 'In-Reply-To' mail header from this emailmsg
				String inReplyToVal = pullInReplyToValFromHeader(e.headers);
				if( !possibleDupeMap.containsKey(inReplyToVal) ){
					possibleDupeMap.put(inReplyToVal,new List<EmailMessage> { e });
				}
				else{
					possibleDupeMap.get(inReplyToVal).add( e );				
				}
			}
		}
		
		Boolean dupeMapModified = false;
		if( !possibleDupeMap.isEmpty() ){			
			// Get all emailmessages in the past X days that are NOT the same as those in trigger scope, then inspect each to determine if they contain the In-Reply-To header value
			// Note this is heavy handed, but we cannot filter directly using SOQL/SOSL on the headers field in EmailMessage due the field being a textarea			 
			Date nDaysAgo = Date.today() - (Integer)sts.numberOfDaysToSearchForDuplicates__c;
			Map<Id,EmailMessage> lastNdaysMap = new Map<Id,EmailMessage>([SELECT Id, Headers, ParentId
																		  FROM EmailMessage 
																		  WHERE MessageDate >= :nDaysAgo 
																		  AND Id != :emailMessageIdsInScope 
																		  AND Incoming=true 
																		  AND FromAddress NOT IN :FROM_FILTER
																		  ORDER BY MessageDate DESC ]); 

			// iterate over possibleDupeMap, retreive any other historical email msgs that contain the msg-id in the In-Reply-To string
			for( String inReplyTo : possibleDupeMap.keySet() ){		
							
				for( Id emId : lastNdaysMap.keySet() ){

					EmailMessage em = lastNdaysMap.get(emId);

					if( !String.isEmpty(em.Headers) && em.Headers.contains(inReplyTo)  ){
						dupeMapModified = true;
						possibleDupeMap.get(inReplyTo).add(em);
					}
				}
			}

		}

		if( dupeMapModified ){
			reparentEmailMessagesAndMarkCasesClosedDupe( possibleDupeMap );	
		}

	}

	private static void processPossibleReplyToSelf( List<EmailMessage> possibleReplyToSelf ){
		// get all of the Ids of email messages identified in possibleReplyToSelf list
		Set<Id> emailMessageIdsInScope = (new Map<Id,SObject>(possibleReplyToSelf)).keySet();	

		if(possibleReplyToSelf.size() <= 0 ){
			return;	
		}

		// Create a Map of the In-Reply-To msg header value as Map key, and a List of email msgs that contain that same Map value
		Map<String,List<EmailMessage>> possibleDupeMap = new Map<String,List<EmailMessage>>();
		if( possibleReplyToSelf.size() > 0 ){
			for( EmailMessage e : possibleReplyToSelf){
				// Get the 'In-Reply-To' mail header from this emailmsg
				String inReplyToVal = pullInReplyToValFromHeader(e.headers);
				if( !possibleDupeMap.containsKey(inReplyToVal) ){
					possibleDupeMap.put(inReplyToVal,new List<EmailMessage> { e });
				}
				else{
					possibleDupeMap.get(inReplyToVal).add( e );				
				}
			}
		}
		Boolean dupeMapModified = false;
		if( !possibleDupeMap.isEmpty() ){			
			// Get all emailmessages in the past 30 days that are NOT the same as those in trigger scope, that are also incoming messages, then inspect each to determine 
			// if they contain a Message-ID: <In_reply_to value> header
			// Note this is heavy handed, but we cannot filter directly using SOQL/SOSL on the headers field in EmailMessage due the field being a textarea
			Date nDaysAgo = Date.today() - (Integer)sts.numberOfDaysToSearchForDuplicates__c;
			List<EmailMessage> lastNdays = [SELECT Id, Headers, ParentId
											FROM EmailMessage 
											WHERE MessageDate >= :nDaysAgo 
											AND Id != :emailMessageIdsInScope 
											AND Incoming=true
											AND FromAddress NOT IN :FROM_FILTER
											ORDER BY MessageDate DESC  ];

			// iterate over possibleDupeMap, retreive any other historical email msgs that contain the msg-id in the In-Reply-To string
			for( String inReplyTo : possibleDupeMap.keySet() ){		
						
				for( EmailMessage em : lastNdays ){

					if( !String.isEmpty(em.Headers) && em.Headers.contains(inReplyTo) && hasMessageId(em.Headers,inReplyTo) ){
						dupeMapModified = true;
						possibleDupeMap.get(inReplyTo).add(em);
					}
				}
			}
		}

		if( dupeMapModified ){
			reparentEmailMessagesAndMarkCasesClosedDupe( possibleDupeMap );	
		}

	}

	// attempt to match local part of inbound email to address with a service address in Email-to-Case config
	private static boolean addressedToSupportQueue(String toAddress){
		boolean inQueue = false;

		// determine if this address is single or multiple
		List<String> addresses = toAddress.split(';');

		// remove spaces
		for( String e : addresses){
			e = e.replaceAll( '\\s+', '');
		}

		String eaLocalPart;

		for( String addy : addresses){
			eaLocalPart = addy.substring(0, addy.indexOf('@')).replaceAll( '\\s+', '');
			for( EmailServicesAddress sa : SERVICE_ADDRESSES ){
				if( sa.LocalPart.equalsIgnoreCase(eaLocalPart) ){
					return true;
				}
			}		
		}

		return inQueue;
	}

	// exlusion list 
	private static boolean fromExclusionList(String fromAddress){
		for( String addy : FROM_FILTER){
			if( fromAddress.equalsIgnoreCase(addy) ){
				return true;
			}	
		}
		return false;
	}

	private static void reparentEmailMessagesAndMarkCasesClosedDupe( Map<String,List<EmailMessage>> possibleDupeMap ){
		Set<Id> allCaseIdsToClose = new Set<Id>();
		Map<Id,EmailMessage> clonedEmailMsgs = new Map<Id,EmailMessage>();
		Set<Id> processedEmails = new Set<Id>();
		List<EmailMessage> discardedEmailMsgs = new List<EmailMessage>();

		// Iterate over the List of each node in the Map, find the earliest Case Id and clone all other Email Messages to that same Case Id
		// Keep track of the Case Ids that are being replaced by marking each of those as 'Closed - Duplicate'
		for( String inReplyTo : possibleDupeMap.keySet() ){	
			List<EmailMessage> emCases = possibleDupeMap.get(inReplyTo);
			Set<Id> caseIds = new Set<Id>();				
			for(EmailMessage em : emCases){
				caseIds.add(em.ParentId);				
			}

			Map<Id,Case> parentCaseMap = new Map<Id,Case>([SELECT Id, Status FROM Case WHERE Id = :caseIds ORDER BY CreatedDate]);
			Case parentCase = parentCaseMap.values()[0];
			// Remove parent Case from Set
			caseIds.remove(parentCase.Id);
			allCaseIdsToClose.addAll(caseIds);

			// update the EmailMsg list with all fields required for cloning
			List<EmailMessage> emCasesUdtd = [  SELECT Id, Headers, ParentID, Incoming, HtmlBody, TextBody, ToAddress, FromAddress, Subject, MessageDate, Status, CcAddress
												FROM EmailMessage
												WHERE Id = :(new Map<Id,SObject>(emCases)).keySet() ];

			// now that we know which Case is parent, clone each EmailMessage and attach the Parent Id we found, and any attachments
			for(EmailMessage em : emCasesUdtd){
				if(em.ParentID != parentCase.Id && parentCaseMap.get(em.ParentID).Status != 'Closed - Duplicate' ){
					processedEmails.add(em.Id);
					discardedEmailMsgs.add(em);
					// clone the email and mark the original for deletion
					EmailMessage newEm = em.clone(false,true,true,false); 
					// update the parent id
					newEm.ParentId = parentCase.Id;										

					clonedEmailMsgs.put( em.Id, newEm );																
				}
			}
		}

		try{
			insert clonedEmailMsgs.values();		
		} 
		catch(Exception e){
			System.debug(Logginglevel.ERROR,'Exception during attempt to insert clonedEmailMsgs =' + e);
		}
		
		// 1. Close Cases that have been marked as duplicate
		List<Case> casesToClose = [SELECT Id, Status FROM Case WHERE Id = :allCaseIdsToClose];
		for(Case c : casesToClose){
			c.Status = 'Closed - Duplicate';
		}
		update casesToClose;
		
	}

	// detect if reply to header exists in email message
	private static boolean hasInReplyToHeader(String headers){
		Integer indexStart = headers.indexOf('In-Reply-To: <');
		if(indexStart<=0){
		  indexStart = headers.indexOf('In-Reply-To:<');
		}
		return ( indexStart>0 ? true : false );
	}

	private static String pullInReplyToValFromHeader(String headers){
		String hdrVal = '';
		Integer indexStart = headers.indexOf('In-Reply-To: <');
		if(indexStart<=0){
		  indexStart = headers.indexOf('In-Reply-To:<');
		}
		if( indexStart >= 0 ){
			Integer indexEnd = headers.indexOf('>',indexStart);
			if( indexEnd >= 0 ){
				hdrVal = headers.substring(indexStart,indexEnd+1);
				// remove bookends of header to isolate value only as msg id format
				hdrVal = hdrVal.replace('In-Reply-To: <','');
				hdrVal = hdrVal.replace('In-Reply-To:<','');
				hdrVal = hdrVal.replace('>','');
			}
		}
		return hdrVal;
	}

	private static boolean hasMessageId(String headers,String inReplyToValue){
		return  headers.contains( 'Message-ID: <' + inReplyToValue + '>' ) || headers.contains( 'Message-ID:<' + inReplyToValue + '>' );
	}

}