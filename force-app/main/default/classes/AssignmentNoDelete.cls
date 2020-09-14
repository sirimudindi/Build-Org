public class AssignmentNoDelete {  
    public static void DisableDeletion(String currentRecId){
        String UserProfileId = UserInfo.getProfileId();
        //String currentRecId = ApexPages.currentPage().getParameters().get('id');
        
        for(pse__Assignment__c currentAssignment : [SELECT Id, Assignment_Approval_Status__c 
                                                    FROM pse__Assignment__c 
                                                    WHERE Id=:currentRecId 
                                                    AND Assignment_Approval_Status__c = 'Approved']){
            If(UserProfileId != '00e33000001BhIo') {
                currentAssignment.addError('You do not have permissions to delete this Assignment. Contact Finance for assistance.');
            }
        }
    }
}

/*
String ProfileId = UserInfo.getProfileId();
    for(pse__Assignment__c a : trigger.old) {
        if(ProfileId != '00e33000001BhIo' && ProfileId != '00e400000013rQH' && a.Assignment_Approval_Status__c == 'Approved') {
                a.addError('You do not have permissions to delete this Assignment. Contact Finance for assistance.');
            }
    }
*/