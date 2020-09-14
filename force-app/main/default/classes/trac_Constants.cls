/**
 * @author Steve Doucette, Traction on Demand 
 * @date 2018-07-23
 */
public with sharing class trac_Constants {

	//------------------- CASE ------------------------//
	public static final String CASE_IS_CLOSED = 'IsClosed';

	public static final String CASE_STATUS_NEW = 'New';
	public static final String CASE_STATUS_CLOSED = 'Closed';

	public static final String CASE_ORIGIN_PHONE = 'Phone';

	public static final String ENTITLEMENT_STATUS_ACTIVE = 'Active';
	public static final String ASSET_STATUS_ACTIVE = 'Active';

	//------------------- COLLABORATOR ACCOUNT ------------------------//
	@TestVisible private static final String MONTHLY_ACCOUNT_PREFIX = 'Free Collaborator - ';
	@TestVisible private static final Date TODAY = Date.today();
	@TestVisible private static final Date LAST_MONTH = Date.today().addMonths(-1);
	public static final String THIS_MONTH_ACCOUNT_NAME = MONTHLY_ACCOUNT_PREFIX + TODAY.year()
			+ (TODAY.month() < 10 ? '0' + TODAY.month() : String.valueOf(TODAY.month()));
	public static final String LAST_MONTH_ACCOUNT_NAME = MONTHLY_ACCOUNT_PREFIX + LAST_MONTH.year()
			+ (LAST_MONTH.month() < 10 ? '0' + LAST_MONTH.month() : String.valueOf(LAST_MONTH.month()));

	public static final String DEFAULT_NAME = 'Default';

	//-------------------  ACCOUNT TYPE ------------------------//
	public static final String ACCOUNT_TYPE_STRATEGIC_ACCOUNT = 'Strategic Account';

	//-------------------  ACCOUNT TERRITORY ------------------------//
	public static final String ACCOUNT_TERRITORY_SEFL = 'SE - Florida';
	public static final String ACCOUNT_TERRITORY_WSF1 = 'W - San Francisco - 1';

	//------------------- QUEUE OWNER CHANGE ------------------------//
	public static final String QOC_SOURCE_TYPE_ACCOUNT = 'Account';
	public static final String QOC_SOURCE_TYPE_DOMAIN = 'Domain';
	public static final String QOC_TARGET_TYPE_DOMAIN = 'Domain';
	public static final String QOC_TARGET_TYPE_CONTACT = 'Contact';
	public static final String QOC_TARGET_TYPE_LEAD = 'Lead';
    public static final String QOC_BATCH_CLASS_ACCOUNT_OWNER = 'trac_QueueAccountOwnerBatch';
    public static final String QOC_BATCH_CLASS_DOMAIN_CONTACT_OWNER = 'trac_QueueDomainContactOwnerBatch';
    public static final String QOC_BATCH_CLASS_DOMAIN_LEAD_OWNER = 'trac_QueueDomainLeadOwnerBatch';

    //------------------- QUEUE OWNER CHANGE ------------------------//
    public static final String ASYNC_STATUS_HOLDING = 'Holding';
    public static final String ASYNC_STATUS_QUEUED = 'Queued';
    public static final String ASYNC_STATUS_PREPARING = 'Preparing';
    public static final String ASYNC_STATUS_PROCESSING = 'Processing';
    public static final String ASYNC_STATUS_ABORTED = 'Aborted';
    public static final String ASYNC_STATUS_COMPLETED = 'Completed';
    public static final String ASYNC_STATUS_FAILED = 'Failed';
}