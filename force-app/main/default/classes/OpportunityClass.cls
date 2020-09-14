public class OpportunityClass{
    public OpportunityClass(){}
    Public static void UpdateDocusignLanguage(List<opportunitylineitem> newList)
    {
        Set<id> productcodeids = new Set<id>();
        Set<String> oppIds = new Set<String>();
        //Product_Code__mdt code;
        for(opportunitylineitem opl : newList)
        {
            productcodeids.add(opl.productcode);
            oppIds.add(opl.OpportunityId);
        }
        List<Opportunity> oppList = [select id,(select id, opportunityid,productcode, product2id from OpportunityLineItems WHERE Productcode IN:productcodeids) FROM Opportunity WHERE ID IN:oppids];
        
        
        
    }
}