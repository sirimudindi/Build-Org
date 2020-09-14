/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_ffrr_RevenueRecognitionTransa81Test
{
    @IsTest(SeeAllData=true)
    private static void testTrigger()
    {
try 
{ 
ffrr__RevenueRecognitionTransactionLine__c line = [SELECT ffrr__CostCenter__c FROM ffrr__RevenueRecognitionTransactionLine__c LIMIT 1]; 
line.Account_Income__c = '46100 Services Revenue : Consulting Revenue '; 
update line; 
} 
catch(Exception ex){}
    }
}