/**
 * @author Steve Doucette, Traction on Demand 
 * @date 2018-10-01
 * @description Converts licensed leads into contacts on a scheduled basis
 */
global without sharing class trac_ConvertLicensedLeads implements Database.Batchable<sObject>, Schedulable {

	@TestVisible private static Boolean testFlag = false;
	@TestVisible private static Boolean caseTestFlag = false;

	private static final trac_Settings__c SETTINGS = trac_Settings__c.getOrgDefaults();
	private static final LeadStatus CONVERT_STATUS = [
			SELECT Id, MasterLabel	FROM LeadStatus
			WHERE IsConverted = TRUE
			LIMIT 1
	];
	private static final Integer MAX_BATCH_SIZE = 100;
	private static final Integer MAX_QUERY_SIZE = 100000;

	private static Integer batchNumber = 0;

	private static Integer querySize;

	global void execute(SchedulableContext sc) {
		// Enforce batch size
		Integer batchSize = Integer.valueOf(SETTINGS.Lead_Conversion_Batch_Size__c);
		if (batchSize > MAX_BATCH_SIZE) {
			batchSize = MAX_BATCH_SIZE;
		} else if (batchSize < 1) {
			batchSize = 1;
		}
		Database.executeBatch(new trac_ConvertLicensedLeads(), batchSize);
	}

	global Database.QueryLocator start(Database.BatchableContext bc) {
		// Enforce query size
		querySize = Integer.valueOf(SETTINGS.Lead_Conversion_Query_Size__c);
		if (querySize > MAX_QUERY_SIZE) {
			querySize = MAX_QUERY_SIZE;
		} else if (querySize < 1) {
			querySize = 1;
		}
		
		return Database.getQueryLocator('SELECT Id, FirstName, LastName, Domain_Lookup__r.Account__c, Domain_Lookup__r.Account__r.OwnerId'
				+ ' FROM Lead WHERE Licensed_User__c = TRUE'
				+ ' AND Domain_Lookup__r.Account__c != NULL'
				+ ' ORDER BY CreatedDate DESC'
				+ ' LIMIT ' + querySize);
	}

	global void execute(Database.BatchableContext bc, List<sObject> leads) {
		trac_Dispatcher.ignore = true;
		batchNumber++;

		// Get any cases related to leads
		List<Case> cases = [
				SELECT Lead__c, ContactId
				FROM Case
				WHERE Lead__c IN :leads
		];
		Map<Id, List<Case>> casesByLead = new Map<Id, List<Case>>();
		for (Case c : cases) {
			if (!casesByLead.containsKey(c.Lead__c)) {
				casesByLead.put(c.Lead__c, new List<Case>());
			}
			casesByLead.get(c.Lead__c).add(c);
		}
		casesByLead.remove(null);

		// Change owner of lead to that of the Domain's Account's Owner
		for (Lead l : (List<Lead>) leads) {
			l.OwnerId = l.Domain_Lookup__r.Account__r.OwnerId;
		}
		update leads;

		// Prepare lead conversion
		String errors = '';
		List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
		for (Lead l : (List<Lead>) leads) {
			try {
				Database.LeadConvert lc = new Database.LeadConvert();
				lc.setLeadId(l.Id);
				lc.setConvertedStatus(CONVERT_STATUS.MasterLabel);
				lc.setAccountId(l.Domain_Lookup__r.Account__c);
				lc.setDoNotCreateOpportunity(true);
				leadConverts.add(lc);
			} catch (Exception e) {
				errors += '\nLead: ' + l.Id + ' - ' + e.getMessage() + ' - ' + e.getStackTraceString();
			}
		}

		// Convert Leads
		List<Case> casesToUpdate = new List<Case>();
		List<Database.LeadConvertResult> lcrs = Database.convertLead(leadConverts, false);
		for (Database.LeadConvertResult lcr : lcrs) {
			if (!lcr.isSuccess() || testFlag) {
				errors += '\nLead: ' + lcr.leadId;
				for (Database.Error e : lcr.errors) {
					errors += ' ' + e.message;
				}
			} else {
				List<Case> leadsCases = casesByLead.get(lcr.getLeadId());
				if (leadsCases != null) {
					for (Case c : leadsCases) {
						c.ContactId = lcr.getContactId();
						c.Lead__c = null;
						casesToUpdate.add(c);
					}
				}
			}
		}

		// Update cases
		List<Database.SaveResult> caseResults = Database.update(casesToUpdate, false);
		for (Database.SaveResult result : caseResults) {
			if (!result.isSuccess() || caseTestFlag) {
				errors += '\nCase: ' + result.getId();
				for (Database.Error e : result.errors) {
					errors += ' ' + e.message + '.';
				}
			}
		}

		// Email regarding errors if any
		if (String.isNotBlank(errors)) {
			errors = 'Batch # ' + batchNumber + ' ERRORS ' + errors;
			System.debug(errors);
			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			email.setSenderDisplayName('Lead Conversion Batch Job #' + batchNumber);
			email.setToAddresses(new List<String>{
					SETTINGS.Lead_Conversion_Error_Email__c
			});
			email.setPlainTextBody(errors);
			Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{
					email
			});
		}
	}

	global void finish(Database.BatchableContext bc) {

	}
}