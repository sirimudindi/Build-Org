public class LiveChatRemoter {

    public String emailAddress { get; set; }
    public String agentUserId { get; set; }
    public String referrerURL { get; set; }
    public static List<Contact> contacts { get; set; }
    public static List<Lead> leads { get; set; }
    public static Flow.Interview.Chat_Completed_Flow chatFlow { get; set; }
    public static Lead l { get; set; }
    public LiveChatRemoter() { } // empty constructor
    
    @RemoteAction
    public static Boolean isContact(String emailAddress) {
        contacts = [SELECT Id FROM Contact WHERE Email = :emailAddress];
        if (contacts.isEmpty())
            return false;
        else
            return true;
    }

    @RemoteAction
    public static Boolean waitForContactOrLeadCreation(String emailAddress) {
        for(Integer i = 0; i < 100; i++) {
            contacts = [SELECT Id FROM Contact WHERE Email = :emailAddress];
            leads = [SELECT Id FROM Lead WHERE Email = :emailAddress];
    
            if (!contacts.isEmpty())
                return true;
    
            if (!leads.isEmpty())
                return true;
            
            Long startingTime = System.now().getTime(); // Num milliseconds since Jan 1 1970
            Integer delayInMilliseconds = 1000; // One-second delay
            while (System.now().getTime() - startingTime < delayInMilliseconds)  {
                // Do nothing until desired delay has passed
            }
            
            // waitForContactOrLeadCreation(emailAddress);
        }
        
        return false;
    }

    @RemoteAction
    public static Boolean startChatCompletedFlow(String emailAddress, String agentUserId, String referrerURL) {
        String contactID = null;
        String leadID = null;
        
        for(Integer i = 0; i < 100; i++) {
            contacts = [SELECT Id FROM Contact WHERE Email = :emailAddress];
            leads = [SELECT Id FROM Lead WHERE Email = :emailAddress];
    
            if (!contacts.isEmpty())
                contactID = contacts[0].Id;
    
            if (!leads.isEmpty())
                leadID = leads[0].Id;
            
            Long startingTime = System.now().getTime(); // Num milliseconds since Jan 1 1970
            Integer delayInMilliseconds = 1000; // One-second delay
            while (System.now().getTime() - startingTime < delayInMilliseconds)  {
                // Do nothing until desired delay has passed
            }
            
            if (contactID != null || leadID != null)
                break;
        }
        
        Map<String, Object> flowMap = new Map<String, Object>();

        flowMap.put('ContactID', contactID);
        flowMap.put('LeadID', leadID);
        flowMap.put('ChatAgentID', agentUserId);
        flowMap.put('referrer', referrerURL);
                
        chatFlow = new Flow.Interview.Chat_Completed_Flow(flowMap);
        chatFlow.start();
        
        String returnValue = (String) chatFlow.getVariableValue('ChatAgentID');
        System.debug('Flow returned ' + returnValue);
        
        if (returnValue == agentUserId)
            return true;
        else
            return false;
    }

    @RemoteAction
    public static Map<String, Object> captureLostLead(String emailAddress) {
        contacts = [SELECT Id FROM Contact WHERE Email = :emailAddress];
        leads = [SELECT Id FROM Lead WHERE Email = :emailAddress];
        
        Map<String, Object> lead = new Map<String, Object>();
        if (contacts.isEmpty() && leads.isEmpty()) {
            l = new Lead(LastName='Unknown', Company='Unknown', Status='New', LeadSource='Chat', Email=emailAddress);
            insert l;
            lead.put('LeadID', l.Id);
            lead.put('ContactID', null);
            return lead;
        }
        
        if (contacts.isEmpty())
            lead.put('ContactID', null);
        else
            lead.put('ContactID', contacts[0].Id);
        
        if (leads.isEmpty())
            lead.put('LeadID', null);
        else
            lead.put('LeadID', leads[0].Id);
            
        return lead;
    }
}