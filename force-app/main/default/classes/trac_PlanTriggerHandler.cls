/**
 * @author Ryan Draper - Traction on Demand
 * @date   2017-07-21
 * @description Handles Plan to SKU and Oli to SKU syncing when inserting/updating Plans(Contract)
 */
public class trac_PlanTriggerHandler extends trac_TriggerHelper {
	@testVisible private static final String TYPE_NEW              = trac_OpportunityPlanHandler.newRTId;
	@testVisible private static final String BILL_TO               = 'BILL_TO';
	@testVisible private static final String NOT_BILL_TO           = 'Not Bill To';
	@testVisible private static final String SKUS_PROCESSED_STATUS = trac_OpportunityPlanHandler.SKUS_PROCESSED_STATUS;
	@testVisible private static final String ACTIVE                = 'Active';
	@testVisible private static final String INACTIVE              = 'Inactive';
	private List<Opportunity_Plan_Mapping__mdt> planToSkuMappings;
	private List<Opportunity_Plan_Mapping__mdt> withSecondarySkuMappings1;
	private List<Opportunity_Plan_Mapping__mdt> withSecondarySkuMappings2;
	@testVisible private static Integer executionCount;
	@testVisible private static Integer executionCountUpdate;
	
	private Map<String, List<Opportunity_Plan_Mapping__mdt>> mappingsMap;
	private Map<Id, Integer>      oliToSkuInsertIndex;
	private Map<Id, Contract>     notBillToPlanMap;
	private Map<Id, Product2>     tempTestMap;
	private Map<Id, Product2>     productMap;
	private Map<String, CurrencyType> currencyMap;
	private List<Asset>               skuInsertList;
	private List<OpportunityLineItem> olisToUpdate;
	private List<Asset>               skuUpdateList;
	private Set<String>               updateOppListIds;
	private List<Opportunity>         updateOppList;
	private Set<String>               updatePlanSetIds;
	private Map<Id, Contract> planUpdateMap = new Map<Id, Contract>();
	private Integer                   skuInsertIndex;
	private Map<Integer,String> planErrors = new Map<Integer,String>();

	static{
		executionCount = 0;
		executionCountUpdate = 0;
	}

	public trac_PlanTriggerHandler(){
		skuInsertList       = new List<Asset>();
		skuUpdateList       = new List<Asset>();
		oliToSkuInsertIndex = new Map<Id,Integer>();
		olisToUpdate        = new List<OpportunityLineItem>();
		updateOppList       = new List<Opportunity>();
		updatePlanSetIds    = new Set<String>();
		notBillToPlanMap  = new Map<Id,Contract>();
		updateOppListIds    = new Set<String>();
		skuInsertIndex 		= 0;
		mappingsMap = buildMappingMap( queryOpportunityPlanMappings() );
		planToSkuMappings = mappingsMap.get( 'Plan_to_SKU' );
		withSecondarySkuMappings1 = mappingsMap.get( 'Plan_to_SKU_w_secondary_product_SKU_1' );
		withSecondarySkuMappings2 = mappingsMap.get( 'Plan_to_SKU_w_secondary_product_SKU_2' );
		planUpdateMap = new Map<Id, Contract>();
	}

	public override void processAfterInsert(){
		manageSKUsOnInsert();
	}

	public override void processAfterUpdate(){
		executionCountUpdate++;

		if( executionCountUpdate > 1)
			return;

		manageSKUsOnUpdate();

	}

	private void manageSKUsOnUpdate(){

		List<Contract> notBillToPlans   = new List<Contract>();
		List<Id>       notBillToPlanIds = new List<Id>();
		Set<String>    productIds       = new Set<String>();
		Set<String>    currencyCodes    = new Set<String>();

		for( Contract plan : (List<Contract>) trigger.new ){

			if( String.isNotBlank( plan.Currency_Code__c ) ){
				currencyCodes.add( plan.Currency_Code__c );
			} else {
				flagPlanForNotification( plan, 'Notify_of_Currency_Code_Issue__c' );
			}

			if( plan.Payment_Type__c != BILL_TO ){
				notBillToPlans.add( plan );
				notBillToPlanIds.add( plan.Id );
				if( String.isNotBlank( plan.Related_Product_ID__c ) )
					productIds.add( plan.Related_Product_ID__c );

				if( String.isNotBlank( plan.Related_Secondary_Product_ID__c ) )
					productIds.add( plan.Related_Secondary_Product_ID__c );
			}

		}
		//tempTestMap is necessary as productIds will always contain the hardcoded
		//formula field, which will work in regular execution but fail in the test class
		Map<Id,Product2> tempTestMap = new Map<Id,Product2>();
		tempTestMap.putAll( new List<Product2>{ trac_TestProductUtility.testProduct1, trac_TestProductUtility.testProduct2 } );
		productMap = Test.isRunningTest() ?  tempTestMap : queryProducts( productIds );

		currencyMap = queryCurrencyTypes( currencyCodes );
		notBillToPlanMap = queryPlans( notBillToPlanIds );
		manageSKUsForNotBillToUpdate( notBillToPlans, notBillToPlanMap );

		System.debug('RIGHT BEFORE INSERT: ' + skuInsertList);
		if( !skuInsertList.isEmpty() ) {
			//insert skuInsertList;
			List<Database.SaveResult> srs = Database.insert(skuInsertList, false);
			processPlanErrors(srs, skuInsertList, 'Plan__c');
		}

		if( !skuUpdateList.isEmpty() ) {
			//update skuUpdateList;
			List<Database.SaveResult> srs = Database.update(skuUpdateList, false);
			processPlanErrors(srs, skuInsertList, 'Plan__c');
		}

		if( !planUpdateMap.isEmpty() ) {
			//update planUpdateMap.values();
			List<Database.SaveResult> srs = Database.update(planUpdateMap.values(), false);
			processPlanErrors(srs, planUpdateMap.values(), 'Id');
		}

		processTriggerErrors();
	}

	private void flagPlanForNotification( Contract plan, String fieldAPIName ){
		//Notify salesoperations@smartsheet.com including Plan SFID and PPPID
		////executionCount check only required if going the way of the workflow rule
		if(executionCount < 1){

			executionCount++;
			Boolean fieldValue = Boolean.valueOf( plan.get(fieldAPIName) );
			if( !fieldValue )
				registerPlanUpdate( plan, fieldAPIName, fieldValue );

		}
	}

	private void registerPlanUpdate( Contract plan, String fieldAPIName, Object value ){

		if( !planUpdateMap.containsKey(plan.Id) )
			planUpdateMap.put( plan.Id, new Contract( Id=plan.Id ) );

		planUpdateMap.get( plan.Id ).put( fieldAPIName, value );

	}

	private void manageSKUsOnInsert() {

		//gather product Ids from Contract to query products
		//requery products based on the contract related product id to get the Product Primary Subscription value of the product
		//figure out which contracts are bill to and which are not bill to
		List<Contract> notBillToPlans = new List<Contract>();
		List<Contract> billToPlans = new List<Contract>();
		Set<String> productIds = new Set<String>();
		Set<String> currencyCodes = new Set<String>();

		for (Contract plan : (List<Contract>) trigger.new) {

			if (String.isNotBlank(plan.Related_Product_ID__c))
				productIds.add(plan.Related_Product_ID__c);

			if (String.isNotBlank(plan.Related_Secondary_Product_ID__c))
				productIds.add(plan.Related_Secondary_Product_ID__c);

			if (String.isNotBlank(plan.Currency_Code__c)) {
				currencyCodes.add(plan.Currency_Code__c);
			} else {
				flagPlanForNotification(plan, 'Notify_of_Currency_Code_Issue__c');
			}

			if (plan.Payment_Type__c != BILL_TO) {
				notBillToPlans.add(plan);
			} else {
				billToPlans.add(plan);
			}

		}

		//tempTestMap is necessary as productIds will always contain the hardcoded
		//formula field, which will work in regular execution but fail in the test class
		Map<Id, Product2> tempTestMap = new Map<Id, Product2>();
		tempTestMap.putAll(new List<Product2>{
				trac_TestProductUtility.testProduct1
		});
		productMap = Test.isRunningTest() ? tempTestMap : queryProducts(productIds);

		currencyMap = queryCurrencyTypes(currencyCodes);

		manageSKUsForNotBillTo(notBillToPlans);
		manageSKUsForBillTo(billToPlans);

		List<OpportunityLineItem> olisToUpdate = new List<OpportunityLineItem>();

		System.debug('FOOOOOOOOOOOOOOOO: ' + skuInsertList);
		if (!skuInsertList.isEmpty()) {
			//insert skuInsertList;
			List<Database.SaveResult> srs = Database.insert(skuInsertList, false);
			processPlanErrors(srs, skuInsertList, 'Plan__c');
		}

		if( !updateOppList.isEmpty() ) {
			//update updateOppList;
			List<Database.SaveResult> srs = Database.update(updateOppList, false);
			processPlanErrors(srs, updateOppList, 'ContractId');
		}

		if( !planUpdateMap.isEmpty() ) {
			//update planUpdateMap.values();
			List<Database.SaveResult> srs = Database.update(planUpdateMap.values(), false);
			processPlanErrors(srs, planUpdateMap.values(), 'Id');
		}

		Map<Id,Asset> mapInsertedSkus = new Map<Id,Asset>();
		if (!skuInsertList.isEmpty()) {
			for (Asset sku : skuInsertList) {
				if (sku.Id != null) {
					mapInsertedSkus.put(sku.Id, sku);
				}
			}
		}
		for( Id oppProductid : oliToSkuInsertIndex.keySet() ){
			Integer i = oliToSkuInsertIndex.get( oppProductid );
			olisToUpdate.add(
				new OpportunityLineItem(
					Id = oppProductid,
					Related_SKU__c = skuInsertList[i].Id
				)
			);
		}

		if( !olisToUpdate.isEmpty() ) {
			//update olisToUpdate;
			List<Database.SaveResult> srs = Database.update(olisToUpdate, false);
			processPlanErrorsForOLIs(srs, olisToUpdate, mapInsertedSkus);
		}

		processTriggerErrors();
	}

	private void manageSKUsForNotBillTo( List<Contract> planList ){
		System.debug('inserting plan');
		Set<String> pbIds = new Set<String>();
		Set<String> productIds = new Set<String>();

		for( Contract plan : planList ){
			if( String.isNotBlank( plan.Related_Price_Book_ID__c ) )
				pbIds.add( plan.Related_Price_Book_ID__c );

			if( String.isNotBlank( plan.Related_Product_ID__c ) )
				productIds.add( plan.Related_Product_ID__c );

			if( String.isNotBlank( plan.Related_Secondary_Product_ID__c ) )
				productIds.add( plan.Related_Secondary_Product_ID__c );
		}

		Map<String, PriceBookEntry> pbeMap = queryPriceBookEntries( pbIds, productIds );

		for( Contract plan : planList ){
			System.debug('before createNewPlanSKUs');
			createNewPlanSKUs( plan, pbeMap, true, true );

		}

	}

	private void manageSKUsForNotBillToUpdate( List<Contract> planList, Map<Id,Contract> notBillToPlanMap ){

		Set<String> pbIds = new Set<String>();
		Set<String> productIds = new Set<String>();

		for( Contract plan : planList ){
			if( String.isNotBlank( plan.Related_Price_Book_ID__c ) )
				pbIds.add( plan.Related_Price_Book_ID__c );

			if( String.isNotBlank( plan.Related_Product_ID__c ) )
				productIds.add( plan.Related_Product_ID__c );

			if( String.isNotBlank( plan.Related_Secondary_Product_ID__c ) )
				productIds.add( plan.Related_Secondary_Product_ID__c );
		}

		Map<String, PriceBookEntry> pbeMap = queryPriceBookEntries( pbIds, productIds );

		for( Contract plan : planList ){

			Set<Id> productsIdsWithActiveSKUs = new Set<Id>();
			Contract cont = notBillToPlanMap.get( plan.Id );
			Product2 planProduct = Test.isRunningTest() ? trac_TestProductUtility.testProduct1 : productMap.get( plan.Related_Product_ID__c );
			Product2 secondaryPlanProduct = Test.isRunningTest() && trac_TestProductUtility.hasSecondaryProduct
												? 	trac_TestProductUtility.testProduct2
												: 	productMap.get( plan.Related_Secondary_Product_ID__c );

			String currencyISOCode = secureCurrencyType( plan.Currency_Code__c );

			List<Asset> skuList = cont.SKUs__r;

			Set<Id> updatedSKUIds = new Set<Id>(); //protect against duplicate SKUS in list

			if( skuList.isEmpty() ){
				System.debug('skuList is empty');
				System.debug('!noSecondaryProduct( plan ): ' + !noSecondaryProduct( plan ));
				createNewPlanSKUs( plan, pbeMap, true, !noSecondaryProduct( plan ) );
			} else {
				Boolean foundPrimarySKU = false;
				Boolean foundSecondarySKU = false;
				for(Asset sku : skuList){
					if( planProduct != null && sku.Product2Id == planProduct.Id ){
						foundPrimarySKU = true;
					}
					if( secondaryPlanProduct != null && sku.Product2Id == secondaryPlanProduct.Id ){
						foundSecondarySKU = true;
					}
				}
				if( !foundPrimarySKU || !foundSecondarySKU ){
					createNewPlanSKUs( plan, pbeMap, !foundPrimarySKU, !foundSecondarySKU );
				}
			}

			for( Asset sku : skuList ){

				if( sku.Product2.Primary_Subscription__c == true && !productsIdsWithActiveSKUs.contains( planProduct.Id ) ){

					productsIdsWithActiveSKUs.add( planProduct.Id );

					if( sku.Product2Id == planProduct.Id ){

						//update existing
						// if no secondary populated do this
						if( noSecondaryProduct( plan ) ){

							for( Opportunity_Plan_Mapping__mdt mapping : planToSkuMappings )
								mapPlanToSKU( plan, sku, mapping );

							sku.CurrencyIsoCode = currencyISOCode;
							sku.Status = ACTIVE;
							if( !updatedSKUIds.contains(sku.Id) )
								skuUpdateList.add(sku);

						} else {
							//we do have a secondary
							//we need to update the secondary sku only
							//loop through skus, find the one with the same ProductID as planProduct2.Id, then update it
							for( Asset otherSku : skuList ){

								if( secondaryPlanProduct != null && otherSku.Product2.Id == secondaryPlanProduct.Id && !updatedSKUIds.contains(otherSku.Id) ){
									updatedSKUIds.add(otherSku.Id);
									//TODO This is where we check that the value of Contract.UserLimit - PlanProduct.Quantity < 1
									//If Primary Sku makes up the entirety of the Contract User Limit
									Boolean deactivatedSecondarySku = false;
									if( Plan.User_Limit__c - sku.Quantity < 1){
										//Then deactivate the secondary Sku
										deactivatedSecondarySku = true;
										otherSku.Status = INACTIVE;
										otherSku.Quantity = 0;
									}

									//Then set status of otherSKU to deactivated
									//and add to update list without any changes ie skip to 344

									if( secondaryPlanProduct != null ){
										//No need to update other data about Sku if it is due to be deactivated
										if(!deactivatedSecondarySku){
											for( Opportunity_Plan_Mapping__mdt mapping : withSecondarySkuMappings2 )
												mapPlanToSKU( plan, otherSku, mapping );

											PriceBookEntry thePBE = null;

											otherSku.Product2Id = secondaryPlanProduct.Id;
											otherSku.Name = secondaryPlanProduct.Name;
											otherSku.Primary_Subscription__c = secondaryPlanProduct.Primary_Subscription__c;

											if( plan.User_Limit__c != null && planProduct.Maximum_Quantity__c != null )
												otherSku.Quantity = plan.User_Limit__c - planProduct.Maximum_Quantity__c;

											if( plan.Related_Price_Book_ID__c != null )
												thePBE = pbeMap.get( currencyISOCode + String.valueOf( secondaryPlanProduct.Id ).substring(0,15) + String.valueOf( plan.Related_Price_Book_ID__c ).substring(0,15) );

											if( thePBE != null && otherSku.Quantity != null )
												otherSku.Price = plan.Previous_ARR_For_Expansion__c - sku.Price;
										}
										skuUpdateList.add(otherSku);

						            }

								}

							}
						}

					} else {

						if( noSecondaryProduct( plan ) ){
							//deactivate
							sku.Status = INACTIVE;

							if( !updatedSKUIds.contains(sku.Id) )
								skuUpdateList.add(sku);

							//Get other SKUs and De-activate as well
							for( Asset otherSku : skuList ){

								if( otherSku.Id != sku.Id && !updatedSKUIds.contains(otherSku.Id) ){
									otherSku.Status = INACTIVE;
									skuUpdateList.add(otherSku);
								}

							}

							//createNewPlanSKUs( plan, pbeMap, true, false );

						} else {

							//de-activate and re-create all
							sku.Status = INACTIVE;

							if( !updatedSKUIds.contains(sku.Id) )
								skuUpdateList.add(sku);

							//Get other SKUs and De-activate as well
							for( Asset otherSku : skuList ){

								if( otherSku.Id != sku.Id && !updatedSKUIds.contains(otherSku.Id) ){
									otherSku.Status = INACTIVE;
									skuUpdateList.add(otherSku);
								}

							}

							//createNewPlanSKUs( plan, pbeMap, true, !noSecondaryProduct( plan ) );

						}

					}
				}

			}
		}
	}

	private void manageSKUsForBillTo( List<Contract> planList ){

		Map<String,List<Opportunity>> pppIDToListOppsMap = createMapPPPIDToOpportunity( planList );
		List<Opportunity_Plan_Mapping__mdt> mappings = mappingsMap.get( 'OLI_to_SKU' );

		for(Contract plan : planList){
			List<Opportunity> oppsByPlanList = pppIDToListOppsMap.get(plan.Payment_Profile_ID__c);

			if( oppsByPlanList != null && oppsByPlanList.size() == 1 ){
				Opportunity opp = oppsByPlanList[0];

				//Create new SKUS for all the Opportunity Products on related opportunity
				List<OpportunityLineItem> oppProducts = opp.OpportunityLineItems;

				for( OpportunityLineItem oppProduct : oppProducts ){

					if( oppProduct.Product2.Is_Recurring__c == true || oppProduct.Subscription_Discount__c == true ){

						Asset newSku = new Asset();

						for( Opportunity_Plan_Mapping__mdt mapping : mappings )
							mapOliToSKU( oppProduct, newSku, mapping );

						//Add Opportunity Level Data
						newSku.Price_Book__c   = opp.Pricebook2Id;
						newSku.Plan__c         = opp.ContractId;
						newSku.Name            = oppProduct.Product2.Name;
						//newSku.CurrencyIsoCode = secureCurrencyType( opp.Currency__c );  //bug identified in SMT003-49 - afee
						newSku.Plan__c         = plan.Id;
						newSku.AccountId       = plan.AccountId;

						//Still need to add Primary_Subscription__c from Product to SKU
						newSku.Primary_Subscription__c = oppProduct.Product2.Primary_Subscription__c;
						skuInsertList.add( newSku );

						//Update Opportunity Status
						opp.Plan_integration_status__c = SKUS_PROCESSED_STATUS;
						opp.ContractId = plan.Id;

						if(!updateOppListIds.contains( opp.Id )){
							updateOppListIds.add( opp.Id );
							updateOppList.add( opp );
						}

						oliToSkuInsertIndex.put(oppProduct.Id,skuInsertIndex);
						skuInsertIndex++;
					}
				}

			}else{

				flagPlanForNotification( plan, 'Notify_Sales_Ops__c' );

			}

		}

	}

	private void createNewPlanSKUs( Contract plan, Map<String, PriceBookEntry> pbeMap, Boolean requiresPrimarySKU, Boolean requiresSecondarySKU ){
		System.debug('plan: ' + plan);
		System.debug('pbeMap: ' + pbeMap);
		System.debug('requiresPrimarySKU: ' + requiresPrimarySKU);
		System.debug('requiresSecondarySKU: ' + requiresSecondarySKU);


		Asset primarySku = new Asset();
		Asset secondarySku = new Asset();
		String currencyISOCode = secureCurrencyType( plan.Currency_Code__c );

		if( requiresPrimarySKU && productMap != null && noSecondaryProduct( plan ) ){

			Product2 planProduct = Test.isRunningTest() ? trac_TestProductUtility.testProduct1 : productMap.get( plan.Related_Product_ID__c );
			System.debug('planProduct: ' + planProduct);
			//create new SKU
			Asset newSKU = new Asset(
				Product2Id = planProduct.Id,
				CurrencyIsoCode = currencyISOCode,
				Primary_Subscription__c = true,
				Status = ACTIVE,
				Name = Test.isRunningTest() ? trac_TestProductUtility.testProduct1.Name : productMap.get(plan.Related_Product_ID__c).Name
			);

			for( Opportunity_Plan_Mapping__mdt mapping : planToSkuMappings )
				mapPlanToSKU(plan, newSku, mapping);

			skuInsertList.add(newSKU);
		}

    	if( productMap != null && !noSecondaryProduct( plan ) ){

            Product2 planProduct = Test.isRunningTest() ? trac_TestProductUtility.testProduct1 : productMap.get( plan.Related_Product_ID__c );
            Product2 secondaryPlanProduct = Test.isRunningTest() ? trac_TestProductUtility.testProduct2 : productMap.get( plan.Related_Secondary_Product_ID__c );

			System.debug('secondaryPlanProduct: ' + secondaryPlanProduct);

            if( requiresPrimarySKU && planProduct != null ){

				for( Opportunity_Plan_Mapping__mdt mapping : withSecondarySkuMappings1 )
	                mapPlanToSKU( plan, primarySku, mapping );

                PriceBookEntry thePBE = null;
    			String isoCode = secureCurrencyType( plan.Currency_Code__c );
    			primarySku.CurrencyIsoCode = isoCode;
            	primarySku.Product2Id = planProduct.Id;
            	primarySku.Name = planProduct.Name;
            	primarySku.Primary_Subscription__c = planProduct.Primary_Subscription__c;
            	primarySku.Quantity = planProduct.Maximum_Quantity__c;

            	if( plan.Related_Price_Book_ID__c != null ){
            		String key = isoCode + String.valueOf( planProduct.Id ).substring(0,15) + String.valueOf( plan.Related_Price_Book_ID__c ).substring(0,15);
            		thePBE = pbeMap.get( key );
            	}

        		if( thePBE != null && planProduct.Maximum_Quantity__c != null ){
        			primarySku.Price = planProduct.Maximum_Quantity__c * thePBE.UnitPrice;
				}

        		skuInsertList.add( primarySku );

            }

            if( requiresSecondarySKU && secondaryPlanProduct != null ){



            	Decimal secondarySKUQuantity = plan.User_Limit__c - planProduct.Maximum_Quantity__c;
				System.debug('secondarySKUQuantity: ' + secondarySKUQuantity);
            	if( secondarySKUQuantity <= 0 )
            		return;



	            for( Opportunity_Plan_Mapping__mdt mapping : withSecondarySkuMappings2 )
	                mapPlanToSKU( plan, secondarySku, mapping );

	            PriceBookEntry thePBE = null;
				String isoCode = secureCurrencyType( plan.Currency_Code__c );
    			secondarySku.CurrencyIsoCode = isoCode;
            	secondarySku.Product2Id = secondaryPlanProduct.Id;
            	secondarySku.Name = secondaryPlanProduct.Name;
            	secondarySku.Primary_Subscription__c = secondaryPlanProduct.Primary_Subscription__c;

            	if( plan.User_Limit__c != null && planProduct.Maximum_Quantity__c != null )
            		secondarySku.Quantity = secondarySKUQuantity;

            	if( plan.Related_Price_Book_ID__c != null )
            		thePBE = pbeMap.get( isoCode + String.valueOf( secondaryPlanProduct.Id ).substring(0,15) + String.valueOf( plan.Related_Price_Book_ID__c ).substring(0,15) );

        		if( thePBE != null && secondarySku.Quantity != null )
        			secondarySku.Price = secondarySku.Quantity * thePBE.UnitPrice;


        		skuInsertList.add( secondarySku );

            }
        }

        System.debug('skuInsertList: ' + skuInsertList);

	}

	private void mapPlanToSKU(  Contract plan,
                                Asset sku,
                                Opportunity_Plan_Mapping__mdt mapping ){

        String sourceApi = mapping.Source_Field__c;
        String destApi = mapping.Destination_Field__c;
        String action = mapping.Plan_Insert_Action__c;

        if( action == 'Insert' )
            sku.put( destApi, plan.get( sourceApi ) );

    }

    private void mapOliToSKU(  OpportunityLineItem oppProduct,
                                Asset sku,
                                Opportunity_Plan_Mapping__mdt mapping ){

        String sourceApi = mapping.Source_Field__c;
        String destApi = mapping.Destination_Field__c;
        String action = mapping.Plan_Insert_Action__c;

        if( action == 'Insert' )
            sku.put( destApi, oppProduct.get( sourceApi ) );

    }

	private Map<String, List<Opportunity_Plan_Mapping__mdt>> buildMappingMap( List<Opportunity_Plan_Mapping__mdt> mappings ){

		Map<String, List<Opportunity_Plan_Mapping__mdt>> mappingsMap = new Map<String, List<Opportunity_Plan_Mapping__mdt>>();

		for( Opportunity_Plan_Mapping__mdt mapping : mappings ){

			if( !mappingsMap.containsKey( mapping.Mapping_Type__c ) )
				mappingsMap.put( mapping.Mapping_Type__c, new List<Opportunity_Plan_Mapping__mdt> () );

			mappingsMap.get( mapping.Mapping_Type__c ).add( mapping );
		}

		return mappingsMap;

	}

	private String secureCurrencyType( String currencyType ){

		String securedCurrencyString = '';

		if( currencyMap != null ){
    		CurrencyType currencyRecord = currencyMap.get( currencyType );
    		if( currencyRecord != null ){
    			if( currencyRecord.IsActive ){
	    			securedCurrencyString = currencyRecord.IsoCode;
	    		} else {
	    			securedCurrencyString = 'USD';
	    		}
    		}
    	}

    	if( String.isBlank( securedCurrencyString ) )
    		securedCurrencyString = 'USD';

		return securedCurrencyString;

	}

	private Boolean noSecondaryProduct( Contract plan ){
		return
			( ( !Test.isRunningTest() && String.isBlank( plan.Related_Secondary_Product_ID__c ) )
					|| 	( Test.isRunningTest() && !trac_TestProductUtility.hasSecondaryProduct ) );
	}

	private Map<Id,Contract> queryPlans(List<Id> planIdList){

		return new Map<Id,Contract>([
			SELECT Id, CurrencyIsoCode, Currency_Code__c, (
				SELECT	Id,
						Plan__c,
						Primary_Subscription__c,
						Product2.Name,
						Product2.Primary_Subscription__c,
						Product2.Is_Recurring__c,
						Product2.Maximum_Quantity__c,
						Status,
						CurrencyIsoCode,
						Price,
						Quantity
				FROM 	SKUs__r
				WHERE 	Status = :ACTIVE
			)
			FROM Contract
			WHERE Id IN :planIdList]);

	}

	private Map<String, List<Opportunity>> createMapPPPIDToOpportunity( List<Contract> planList ){

		Map<String,List<Opportunity>> returnMap = new Map<String,List<Opportunity>>();
		Set<String>                   pppIdSet  = new Set<String>();

		for( Contract plan : planList ){
			if( plan.Payment_Profile_ID__c != null && !pppIdSet.contains( plan.Payment_Profile_ID__c ) ){
				pppIdSet.add( plan.Payment_Profile_ID__c );
			}
		}

		List<Opportunity> oppList = [
			SELECT 	Id,
					Parent_Payment_Profile_ID__c,
					Pricebook2Id,
					ContractId,
					Currency__c,
					CurrencyIsoCode,
					AccountId, (
						SELECT 	Id,
								Is_Recurring_Checkbox__c,
								Product2Id,
								Product2.Primary_Subscription__c,
								Product2.Is_Recurring__c,
								Product2.Name,
								Product2.Maximum_Quantity__c,
								CurrencyIsoCode,
								Discount__c,
								Netsuite_Line_Item_ID__c,
								Netsuite_SO_ID__c,
								Rev_Rec_End_Date__c,
								Rev_Rec_Start_Date__c,
								TotalPrice,
								Quantity,
								Subscription_Discount__c
						FROM   	OpportunityLineItems
					)
			FROM 	Opportunity
			WHERE 	Parent_Payment_Profile_ID__c in :pppIdSet
			AND 	RecordTypeId = :TYPE_NEW
		];

		for( Contract plan : planList ){

			List<Opportunity> oppListBuilt = new List<Opportunity>();

			for( Opportunity opp : oppList ){
				if( opp.Parent_Payment_Profile_ID__c == plan.Payment_Profile_ID__c ){
					oppListBuilt.add( opp );
				}
			}

			returnMap.put( plan.Payment_Profile_ID__c, oppListBuilt );

		}

		return returnMap;
	}

	@TestVisible private static Map<Id, Product2> queryProducts(Set<String> productIds){

		if( productIds.isEmpty() )
			return null;

		return
			new Map<Id, Product2>([
				SELECT 	Id, Primary_Subscription__c, Name, Maximum_Quantity__c, Is_Recurring__c
				FROM 	Product2
				WHERE 	Id in :productIds
			]);

	}

	private Map<String, CurrencyType> queryCurrencyTypes(Set<String> currencyCodes){

		if( currencyCodes.isEmpty() )
			return null;

		List<CurrencyType> currencyTypeList = new List<CurrencyType>([
				SELECT 	Id, IsActive, IsoCode
				FROM 	CurrencyType
				WHERE 	IsoCode in :currencyCodes
			]);

		Map<String, CurrencyType> currencyTypeMap = new Map<String, CurrencyType>();
		for( CurrencyType currencyType : currencyTypeList ){
        	currencyTypeMap.put(currencyType.IsoCode, currencyType);
        }

		return currencyTypeMap;

	}

	private Map<String, PriceBookEntry> queryPriceBookEntries( Set<String> pbIds, Set<String> productIds ){

		List<PriceBookEntry> pbeList = [
			SELECT 	Id, UnitPrice, Product2Id, Pricebook2Id, CurrencyIsoCode
			FROM 	PriceBookEntry
			WHERE 	Product2Id in :productIds
			AND 	Pricebook2Id in :pbIds
		];

		Map<String, PriceBookEntry> mapWithCompoundKeys = new Map<String, PriceBookEntry>();
		for( PriceBookEntry pbe : pbeList ){
			mapWithCompoundKeys.put( pbe.CurrencyIsoCode + String.valueOf( pbe.Product2Id ).substring(0,15) + String.valueOf( pbe.Pricebook2Id ).substring(0,15), pbe );
		}

		return mapWithCompoundKeys;

	}

    private List<Opportunity_Plan_Mapping__mdt> queryOpportunityPlanMappings(){

        return [
            SELECT  Source_Field__c, Destination_Field__c, New_Type_Action__c, Renewal_Type_Action__c, Expansion_Type_Action__c,
            		Mapping_Type__c, Plan_Insert_Action__c
            FROM    Opportunity_Plan_Mapping__mdt
        ];

    }

	private void processPlanErrors(List<Database.SaveResult> srs, List<SObject> sobjs, String planLookupField) {
		System.debug('akong: processPlanErrors: srs: ' + srs);
		System.debug('akong: processPlanErrors: sobjs: ' + sobjs);
		System.debug('akong: processPlanErrors: planLookupField: ' + planLookupField);
		for (Integer i=0; i<srs.size(); i++) {
			if (!srs[i].isSuccess()) {
				Database.Error er = srs[i].getErrors()[0];
				//Id planId = (Id)sobjs[i].get(planLookupField);
				if (er != null) {
					planErrors.put(i, er.getMessage());
				}
			}
		}
	}

	private void processPlanErrorsForOLIs(List<Database.SaveResult> srs, List<SObject> sobjs, Map<Id,Asset> mapInsertedSkus) {
		System.debug('akong: processPlanErrorsForOLIs: srs: ' + srs);
		System.debug('akong: processPlanErrorsForOLIs: sobjs: ' + sobjs);
		System.debug('akong: processPlanErrorsForOLIs: mapInsertedSkus: ' + mapInsertedSkus);
		for (Integer i=0; i<srs.size(); i++) {
			if (!srs[i].isSuccess()) {
				Database.Error er = srs[i].getErrors()[0];
				if (er != null) {
					planErrors.put(i, er.getMessage());
				}
			}
		}
	}

	private void processTriggerErrors() {
		if (!planErrors.isEmpty()) {
			for (Integer i=0; i < trigger.new.size(); i++) {
				if (planErrors.get(i) != null) {
					trigger.new[i].addError(planErrors.get(i));
				}
			}
		}
	}
}