public class PreChatRemoter {

    public String emailAddress { get; set; }
    public static List<Contact> contacts { get; set; }
    public PreChatRemoter() { } // empty constructor
    
    @RemoteAction
    public static Boolean isContact(String emailAddress) {
        contacts = [SELECT Id FROM Contact WHERE Email = :emailAddress];
        if (contacts.isEmpty())
            return false;
        else
            return true;
    }
}