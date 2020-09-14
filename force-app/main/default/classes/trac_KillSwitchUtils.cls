/**
 * Utilitly class to query and return results from kill switch metadata
 * @author Ryan Draper, Traction
 */
public without sharing class trac_KillSwitchUtils {
	
    public static Boolean isDisabled( String methodId ) {
        List<Trigger_Validation_Killswitch__mdt> killSwitches = [
            SELECT  Method_Name__c, Disabled__c
            FROM    Trigger_Validation_Killswitch__mdt
            WHERE   Method_Name__c = :methodId
        ];

        //If the method is not configured properly any specified code based validation will still run
        if( killSwitches.isEmpty() )
            return false;

        //If the method is configured properly return the the disabled status for the specified code
        return killSwitches[0].Disabled__c;
    }
}