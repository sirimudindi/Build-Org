trigger NoDeleteonTask on Task (before delete)
{
   String ProfileId = UserInfo.getProfileId();  
   List<Profile> profiles=[select id from Profile where id='00e0b000000rusr' or id='00e0b000000rv07' or id='00e0b000000rv0R' or id='00e0b000000s4oq' or id='00e40000000yzOf' or id='00e0b000000rv2r' or id='00e0b000000rud8'];

   if (7!=profiles.size())
   {
      // unable to get the profiles - handle error
   }
   else
   {
       for (Task a : Trigger.old)      
       {            
          if ( (profileId==profiles[0].id) || (profileId==profiles[1].id) || (profileId==profiles[2].id) || (profileId==profiles[3].id) || (profileId==profiles[4].id) || (profileId==profiles[5].id) || (profileId==profiles[6].id))
          {
             a.addError('You may not delete this record');
          }
       }            
   }
}