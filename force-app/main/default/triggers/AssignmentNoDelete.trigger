//Trigger to prevent Non-Finance or Admins from deleting an Assignment record when related Project has been Approved.
trigger AssignmentNoDelete on pse__Assignment__c (before delete) {
    String ProfileId = UserInfo.getProfileId();
    for(pse__Assignment__c a : trigger.old) {
        if(ProfileId != '00e33000001BhIoAAK' && ProfileId != '00e400000013rQHAAY' && a.Assignment_Approval_Status__c == 'Approved') {
                a.addError('You do not have permissions to delete this Assignment.');
            }
    }
}