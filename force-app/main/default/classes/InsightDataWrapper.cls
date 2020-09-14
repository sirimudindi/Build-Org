/**
 * The purpose of this class is to act as a wrapper for all the incomming 
 * parameters from insight.  This class will be instantiated from the insightLicensePurchased method
 *
 * @company Traction on Demand
 * @author Sergei Dobrianski
 * @version 1.0
 * @date 08/14/14
**/
public without sharing class InsightDataWrapper {

	private static Boolean isFromApiCall = false;

	public String ppId;

	public String pppId;

	public String domainUrl;

	public String uniqueUId;

    
	public String type;

	public String orgName;

	public Id domainId;

	public static Map<String, InsightDataWrapper> insightDataMap = new Map<String, InsightDataWrapper>();

	private InsightDataWrapper(String ppId, String pppId, String uniqueUId, String domainUrl, String type, String orgName) {
		this.ppId      = ppId;
		this.type 	   = type.toLowerCase();
		this.pppId     = pppId;
		this.domainUrl = domainUrl.toLowerCase();
		this.uniqueUId = uniqueUId;
		this.orgName   = orgName;
	}

	public static void add(String ppId, String pppId, String uniqueUId, String domainUrl, String type, String orgName) {

		if( !insightDataMap.containsKey(ppId) ) {
			insightDataMap.put( ppId, new InsightDataWrapper( ppId, pppId, uniqueUId, domainUrl, type, orgName ) );
		}

	}

	public static Set<String> getPPIDSet() {
		return insightDataMap.keySet();
	}

	public static Set<String> getDomainUrlSet() {
		Set<String> urls = new Set<String>();
		for(InsightDataWrapper i : insightDataMap.values()) {
			urls.add( i.domainUrl );
		}
		return urls;
	}

	public static void setApiCall(Boolean val) {
		isFromApiCall = val;
	}

	public static Boolean isApiCall() {
		return isFromApiCall;
	}

	public static void resetInsightDataMap() {
		insightDataMap = new Map<String, InsightDataWrapper>();
	}

}