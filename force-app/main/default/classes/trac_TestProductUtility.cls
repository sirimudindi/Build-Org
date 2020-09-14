public class trac_TestProductUtility {

    @testVisible private static final trac_TestProductUtility instance = new trac_TestProductUtility();
    public static Product2 testProduct1 { get; set; }
    public static Product2 testProduct2 { get; set; }
    public static Product2 testProduct3 { get; set; }

    public static boolean hasSecondaryProduct {get; set;}

    static{
        testProduct1 = createTestProduct( 'testProduct1' );
        testProduct2 = createTestProduct( 'testProduct2' );
        testProduct2.Primary_Subscription__c = false;
        testProduct3 = createTestProduct( 'testProduct3' );
        if(Test.isRunningTest())
            insert new List<Product2>{ testProduct1, testProduct2, testProduct3 };

        hasSecondaryProduct = false;
    }

    public static Product2 createTestProduct( String productName ){
        return new Product2( 
            Name = productName, 
            IsActive = true,
            Primary_Subscription__c=true,
            Maximum_Quantity__c = 3

        );
    }

}