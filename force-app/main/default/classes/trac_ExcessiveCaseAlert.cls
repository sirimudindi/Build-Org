/**
 * @author Steve Doucette, Traction on Demand
 * @date 1/12/2018
 *
 * @description Counts newest cases within a time frame determined by custom setting.
 * If the amount of cases exceeds a threshold determined by the custom setting,
 * will email a list of users. Reschedules itself after completion.
 */
global class trac_ExcessiveCaseAlert implements Schedulable {

	@TestVisible private static final String JOB_NAME_PREFIX = 'trac_ExcessiveCaseAlert';

	private static final Integer DEFAULT_INTERVAL = 5;

	private static Integer interval, caseCount, threshold, lookbackRange;
	private static DateTime now, lastRun, nextRun;
	private static Id thisJobId;
	private static List<String> emailTo, rtFilter;
	private static OrgWideEmailAddress owa;

	public void execute(SchedulableContext sc) {

		// Get custom settings data
		now = DateTime.now();
		Case_Alert_Settings__c settings = Case_Alert_Settings__c.getOrgDefaults();
		thisJobId = sc.getTriggerId();
		interval = (settings.Interval_In_Minutes__c == null) ? DEFAULT_INTERVAL : Integer.valueOf(settings.Interval_In_Minutes__c.setScale(0));
		if (interval <= 0) {
			interval = DEFAULT_INTERVAL;
		}
		nextRun = now.addMinutes(interval);

		String emailBody = '';
		List<OrgWideEmailAddress> owas = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :settings.From_Address__c LIMIT 1];
		if (owas.isEmpty()) {
			emailBody = 'Email provided in custom setting does not match any Org Wide Email address.';
			emailAdmins(emailBody);
			scheduleNextRun();
			return;
		}
		owa = owas.get(0);

		// Do not run if all run checkboxes are unchecked
		if (!settings.Run_During_Business_Hours__c && !settings.Run_During_Non_Business_Hours__c) {
			scheduleNextRun();
			return;
		}

		// Retrieve default/active Business Hours for this org
		BusinessHours bh = [
				SELECT Id
				FROM BusinessHours
				WHERE IsActive = TRUE AND IsDefault = TRUE
				LIMIT 1
		];
		if (bh == null) {
			emailBody += (emailBody == '' ? '' : '\n') + 'Could not find an active, default Business Hour record. Please check org Business Hour settings.';
			emailAdmins(emailBody);
			scheduleNextRun();
			return;
		}

		// Determine if we run based on custom settings and business hours
		if (settings.Run_During_Business_Hours__c && BusinessHours.isWithin(bh.Id, now)) {
			threshold = Integer.valueOf(settings.Threshold__c.setScale(0));
			emailTo = String.isBlank(settings.Email_To__c) ? new List<String>() : settings.Email_To__c.toLowerCase().replaceAll('\\s*', '').split(';');
			lookbackRange = Integer.valueOf(settings.Business_Hours_Lookback__c);
		} else if (settings.Run_During_Non_Business_Hours__c && !BusinessHours.isWithin(bh.Id, now)) {
			threshold = Integer.valueOf(settings.Non_Business_Hours_Threshold__c.setScale(0));
			emailTo = String.isBlank(settings.Non_Business_Hours_Email_To__c) ? new List<String>() : settings.Non_Business_Hours_Email_To__c.toLowerCase().replaceAll('\\s*', '').split(';');
			lookbackRange = Integer.valueOf(settings.Non_Business_Hours_Lookback__c);
		} else {
			scheduleNextRun();
			return;
		}

		// Get list of addresses to send to (either from custom setting or by default org admins
		if (emailTo.isEmpty()) {
			emailBody = 'No emails provided in custom setting to send to.';
			emailAdmins(emailBody);
			scheduleNextRun();
			return;
		}

		// Use settings interval to determine how many new cases came in since last run
		String queryString = 'SELECT Id, Subject, CaseNumber FROM Case WHERE CreatedDate > :lastRun';
		rtFilter = String.isBlank(settings.Record_Type_Filter__c) ? new List<String>() : settings.Record_Type_Filter__c.toLowerCase().replaceAll('\\s*', '').split(';');
		queryString += rtFilter.isEmpty() ? '' : ' AND RecordType.DeveloperName IN :rtFilter';
		lastRun = now.addMinutes(-lookbackRange);
		List<Case> cases = (List<Case>) Database.query(queryString);
		if (cases.isEmpty()) {
			scheduleNextRun();
			return;
		}

		// Only run if the number of cases from last run exceeds the threshold set in the custom setting
		caseCount = Integer.valueOf(cases.size());
		if (caseCount > threshold) {
			try {
				// Try to email users of exceeding threshold
				emailSettingUsers(cases);
			} catch (Exception ex) {
				// Email admins if error occured
				System.debug(ex);
				emailAdmins(emailBody, ex);
			} finally {
				scheduleNextRun();
				return;
			}
		} else {
			scheduleNextRun();
			return;
		}
	}

	// Email users based on custom setting value
	private static void emailSettingUsers(List<Case> cases) {
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		String emailBody = 'Excessive Cases have come in since last run.\nCurrent Threshold: ' + threshold + '\nNew cases in last ' + lookbackRange + ' minutes: ' + caseCount;
		for (Case c : cases) {
			emailBody += '\nCase Number: ' + c.CaseNumber + ' - Subject: ' + c.Subject;
		}
		email.setPlainTextBody(emailBody);
		email.setToAddresses(new List<String>(new Set<String>(emailTo)));
		email.setSubject(caseCount + ' cases in last ' + lookbackRange + ' minutes');
		if (owa != null) {
			email.setOrgWideEmailAddressId(owa.Id);
		} else {
			email.setSenderDisplayName('Case Alert System');
		}
		Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
				email
		});
	}

	// Email admins due to errors or incorrect settings
	private static void emailAdmins(String emailBody) {
		emailAdmins(emailBody, null);
	}

	// Email admins due to errors or incorrect settings
	private static void emailAdmins(String emailBody, Exception ex) {
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		emailBody = (ex == null ? '' : 'Error Occured: ' + ex) + emailBody;
		email.setPlainTextBody(emailBody);
		email.setToAddresses(getAdminEmails());
		email.setSubject('Errors occured running Case Alert Job');
		if (owa != null) {
			email.setOrgWideEmailAddressId(owa.Id);
		} else {
			email.setSenderDisplayName('Case Alert System');
		}
		Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
				email
		});
	}

	// Get all admin Ids to email when custom setting isn't properly configured or error occurs
	private static List<String> getAdminEmails() {
		List<String> emails = new List<String>();
		for (User u : [SELECT Id FROM User WHERE Profile.Name = 'System Administrator']) {
			emails.add(u.Id);
		}
		return emails;
	}

	// Abort current job (if it still exists) and schedule new job by X minutes (where X is determined by the interval value of custom setting)
	private static void scheduleNextRun() {
		// Abort current job
		try {
			System.abortJob(thisJobId);
		} catch (Exception e) {
			// Do Nothing
		}

		// Start a new schedule
		Type t = Type.forName(JOB_NAME_PREFIX);
		Schedulable s = (Schedulable) t.newInstance();
		System.schedule(JOB_NAME_PREFIX + '_' + System.currentTimeMillis(), '0 ' + nextRun.minute() + ' ' + nextRun.hour()
				+ ' ' + nextRun.day() + ' ' + nextRun.month() + ' ? ' + nextRun.year(), s);
	}
}