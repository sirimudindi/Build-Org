/**
 * @author Ryan Draper - Traction on Demand
 * @date   2017-05-18
 * @description Handles OLI to SKU syncing for New, Renewal and Expansion Opps
 */
public without sharing class trac_OpportunityPlanHandler {
	
    @testVisible private static final String OPP_FINANCE_REVIEVED_STATUS = 'Finance Reviewed';
    @testVisible private static final String OPP_CLOSED_STATUS = 'OpsCon Activated';
    @testVisible public static final String SKUS_PROCESSED_STATUS = 'SKUs Processed';
    @testVisible private static final String FAT_FINGER_ERROR_MESSAGE = 'Plan already exists, please verify Parent Payment Profile ID is correct. For more information, please ask your Salesforce Administrator.';
    @testVisible private static final String PENDING_INTEGRATION_STATUS = 'Pending';
    @testVisible private static final String INACTIVE_STATUS = 'Inactive';

    @TestVisible public static final String newRTId =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('New').getRecordTypeId();
    @TestVisible public static final String renewalRTId =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Renewal').getRecordTypeId();
    @TestVisible public static final String expansionRTId =
            Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Expansion').getRecordTypeId();

    private Map<Id, Opportunity> oppUpdateMap = new Map<Id, Opportunity>();
    private List<Opportunity>       newList;
    private Map<Id, Opportunity>    newMap;
    private Map<Id, Opportunity>    oldMap;

    public trac_OpportunityPlanHandler( List<Opportunity> newList, 
                                        Map<Id, Opportunity> newMap, 
                                        Map<Id, Opportunity> oldMap ){
		this.newList = newList;
        this.newMap = newMap;
        this.oldMap = oldMap;
	}

    public void manageSKUs( List<Opportunity> approvedOpps ){

        List<Opportunity> newOpps = filterOppsByType( approvedOpps, newRTId );
        List<Opportunity> renewalOpps = filterOppsByType( approvedOpps, renewalRTId );
        List<Opportunity> expansionOpps = filterOppsByType( approvedOpps, expansionRTId );

        Set<Id> oppIds = new Set<Id>();
        Set<String> contractIds = new Set<String>();

        for( Opportunity opp : newOpps ){
            oppIds.add( opp.Id );
            if( String.isNotBlank( opp.Parent_Payment_Profile_ID__c ) )
            	contractIds.add( opp.Parent_Payment_Profile_ID__c );
        }

        for( Opportunity opp : renewalOpps ){
            oppIds.add( opp.Id );
            if( String.isNotBlank( opp.Parent_Payment_Profile_ID__c ) )
            	contractIds.add( opp.Parent_Payment_Profile_ID__c );
        }

        for( Opportunity opp : expansionOpps ){
            oppIds.add( opp.Id );
            if( String.isNotBlank( opp.Parent_Payment_Profile_ID__c ) )
            	contractIds.add( opp.Parent_Payment_Profile_ID__c );
        }

        if( !oppIds.isEmpty() && !contractIds.isEmpty() ){

            Map<Id, Opportunity> allOppsMap = queryOpps( oppIds );
            Map<String, Contract> contractMap = queryContracts( contractIds );
            
            List<Asset> assetsToInsertList = new List<Asset>();
            List<Asset> assetsToUpdateList = new List<Asset>();
            List<OpportunityLineItem> olisToUpdate = new List<OpportunityLineItem>();
            Map<Id, Integer> oliToSkuInsertIndex = new Map<Id, Integer>();

            mapLineItemsToSKUs( allOppsMap, contractMap, assetsToInsertList, assetsToUpdateList, olisToUpdate, oliToSkuInsertIndex );

            if( !assetsToInsertList.isEmpty() )
                insert assetsToInsertList;

            if( !assetsToUpdateList.isEmpty() )
                update assetsToUpdateList;

            for( Id oliId : oliToSkuInsertIndex.keySet() ){
                Integer i = oliToSkuInsertIndex.get( oliId );
                olisToUpdate.add( 
                    new OpportunityLineItem( 
                        Id = oliId, 
                        Related_SKU__c = assetsToInsertList[i].Id 
                    ) 
                );
            }

            if( !olisToUpdate.isEmpty() )
                update olisToUpdate;

            if( !oppUpdateMap.isEmpty() )
                update oppUpdateMap.values();

        }

    }

    private void mapLineItemsToSKUs(    Map<Id, Opportunity> allOppsMap, 
                                        Map<String, Contract> contractMap,
                                        List<Asset> assetsToInsert,
                                        List<Asset> assetsToUpdate,
                                        List<OpportunityLineItem> olisToUpdate,
                                        Map<Id, Integer> oliToSkuInsertIndex ){

        trac_Dispatcher.countExecuted('mapLineItemsToSKUs');
        Integer exeCount =  trac_Dispatcher.numTimesExecuted('mapLineItemsToSKUs');

        //need to limit this code to only run once due to workflow firing and the logic 
        //still thinking that Bill_to_status__c just changed
        //see last bullet point in this article: 
        //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_triggers_order_of_execution.htm
        if(execount > 1)
            return;

        List<Opportunity_Plan_Mapping__mdt> mappings = queryOpportunityPlanMappings();

        Integer assetInsertIndex = 0;
        for( Opportunity opp : allOppsMap.values() ){

            Set<Id> oliExistingSkuIds = new Set<Id>();
            for( OpportunityLineItem  oli : opp.OpportunityLineItems ){
                oliExistingSkuIds.add( oli.Related_SKU__c );
            }
            oliExistingSkuIds.remove( null );
            Contract contract = contractMap.get( opp.Parent_Payment_Profile_ID__c );

            if( contract != null ){

                List<Asset> skuList = contract.SKUs__r;

                if( opp.RecordTypeId == renewalRTId ){

                    for( OpportunityLineItem  oli : opp.OpportunityLineItems ){

                        Boolean foundAsset = false;

                        if( oli.Related_SKU__c != null ){
                            
                            for( Asset sku : skuList ){
                                
                                if( oli.Related_SKU__c == sku.Id ){
                                    sku.Price_Book__c = opp.Pricebook2Id;
                                    sku.Primary_Subscription__c = oli.Product2.Primary_Subscription__c;
                                    foundAsset = true;

                                    for( Opportunity_Plan_Mapping__mdt mapping : mappings ){    
                                        mapLineItemToSKU( oli, sku, mapping, opp.RecordTypeId, false );
                                    }

                                    assetsToUpdate.add( sku );
                                    break;
                                
                                }
                            
                            }
                        
                        } else if( oli.Related_SKU__c == null ){

                            if( oli.Product2.Is_Recurring__c || oli.Subscription_Discount__c == true ){
                                Asset newSku 
                                    = new Asset( 
                                        Plan__c                 = contract.Id,
                                        Name                    = oli.Product2.Name,
                                        Price_Book__c           = opp.Pricebook2Id,
                                        AccountId               = contract.AccountId,
                                        Primary_Subscription__c = oli.Product2.Primary_Subscription__c
                                    );

                                for( Opportunity_Plan_Mapping__mdt mapping : mappings ){
                                    mapLineItemToSKU( oli, newSku, mapping, opp.RecordTypeId, true );
                                }

                                assetsToInsert.add( newSku );
                                oliToSkuInsertIndex.put( oli.Id, assetInsertIndex );
                                assetInsertIndex++;
                            }
                            
                        }
                    
                    }

                    for( Asset sku : skuList ){

                        if( !oliExistingSkuIds.contains( sku.Id ) ){
                            assetsToUpdate.add( new Asset( Id = sku.Id, Status = INACTIVE_STATUS ) );
                        }

                    }

                    opp.Plan_Integration_Status__c = SKUS_PROCESSED_STATUS;
                    oppUpdateMap.put( opp.Id, opp);

                } else if( opp.RecordTypeId == expansionRTId ){
                    Asset primarySku = null;
                    OpportunityLineItem primaryOLI = null;
                    Boolean primaryProductChanged = false;
                    Set<Id> processedSkuIds = new Set<Id>();

                    for( Asset sku : skuList ){
                        if( sku.Product2.Primary_Subscription__c == true && sku.Status != INACTIVE_STATUS )
                            primarySku = sku;
                    }
                    
                    for( OpportunityLineItem  oli : opp.OpportunityLineItems ){
                        if( oli.Product2.Primary_Subscription__c == true )
                            primaryOLI = oli;
                    }

                    if( primarySku != null && primaryOLI != null ){
                        if( primaryOLI.Product2Id != primarySku.Product2Id ){
                            primarySku.Status = INACTIVE_STATUS;
                            assetsToUpdate.add( primarySku );
                            primaryProductChanged = true;
                            processedSkuIds.add( primarySku.Id );
                        }
                    }

                    for( OpportunityLineItem  oli : opp.OpportunityLineItems ){
                        Boolean foundAssetForProduct = false;
                        for( Asset sku : skuList ){
                        	if( processedSkuIds.contains( sku.Id ) )
                        		continue;

                            if( oli.Product2Id == sku.Product2Id && oli.UnitPrice == sku.Per_Unit_Price__c && sku.Status != INACTIVE_STATUS && oli.Product2.Is_Recurring__c ){
                            	sku.Primary_Subscription__c = oli.Product2.Primary_Subscription__c;
                                for( Opportunity_Plan_Mapping__mdt mapping : mappings ){
                                    mapLineItemToSKU( oli, sku, mapping, opp.RecordTypeId, false );
                                }
                                assetsToUpdate.add( sku );
                                if( oli.Related_SKU__c != sku.Id ){
                                    oli.Related_SKU__c = sku.Id;
                                    olisToUpdate.add( oli );
                                    processedSkuIds.add( sku.Id );
                                }
                                foundAssetForProduct = true;
                                break;
                            } else if( primaryProductChanged && sku.Product2.Licensing__c == true && sku.Id != primarySku.Id ){
								sku.Status = INACTIVE_STATUS;
                            	assetsToUpdate.add( sku );
                                processedSkuIds.add( sku.Id );
                            }
                            
                        }
                        if( !foundAssetForProduct ){
                            //Alec - change this to product.isRecurring
                            if( oli.Product2.Is_Recurring__c || oli.Subscription_Discount__c == true ){

                                Asset newSku
                                        = new Asset(
                                        Plan__c                 = contract.Id,
                                        Name                    = oli.Product2.Name,
                                        Price_Book__c           = opp.Pricebook2Id,
                                        AccountId               = contract.AccountId,
                                        Product2Id              = oli.Product2Id,
                                        Primary_Subscription__c = oli.Product2.Primary_Subscription__c
                                        );

                                for( Opportunity_Plan_Mapping__mdt mapping : mappings ){
                                    mapLineItemToSKU( oli, newSku, mapping, opp.RecordTypeId, true );
                                }

                                assetsToInsert.add( newSku );
                                oliToSkuInsertIndex.put( oli.Id, assetInsertIndex );
                                assetInsertIndex++;
                            }

                        }
                    }

                    opp.Plan_Integration_Status__c = SKUS_PROCESSED_STATUS;
                    oppUpdateMap.put( opp.Id, opp);

                } else if( opp.RecordTypeId == newRTId ){
                    // build skus
                    // There should only be a Plan(Contract) with no Assets(SKUs)
                    // create a new SKU for all OLIs but only if the OLI is recurring product
                    
                    for( OpportunityLineItem  oli : opp.OpportunityLineItems ){
                        if( oli.Product2.Is_Recurring__c || oli.Subscription_Discount__c == true ){
                            Asset newSku 
                                = new Asset( 
                                    Plan__c                 = contract.Id,
                                    Name                    = oli.Product2.Name,
                                    Price_Book__c           = opp.Pricebook2Id,
                                    AccountId               = contract.AccountId,
                                    Product2Id              = oli.Product2Id,
                                    Primary_Subscription__c = oli.Product2.Primary_Subscription__c
                                );

                            for( Opportunity_Plan_Mapping__mdt mapping : mappings ){
                                mapLineItemToSKU( oli, newSku, mapping, opp.RecordTypeId, true );
                            }

                            assetsToInsert.add( newSku );
                            oliToSkuInsertIndex.put( oli.Id, assetInsertIndex );
                            assetInsertIndex++;
                        }
                    }

                    opp.Plan_Integration_Status__c = SKUS_PROCESSED_STATUS;
                    opp.ContractId = contract.Id;
                    oppUpdateMap.put( opp.Id, opp);

                }

            }

        }

    }

    private void mapLineItemToSKU(  OpportunityLineItem oli, 
                                    Asset sku, 
                                    Opportunity_Plan_Mapping__mdt mapping, 
                                    String oppType, 
                                    Boolean creatingNew ){

        String sourceApi = mapping.Source_Field__c;
        String destApi = mapping.Destination_Field__c;
        String action = '';
        if( oppType == renewalRTId )
            action = mapping.Renewal_Type_Action__c;
        
        if( oppType == expansionRTId )
            action = mapping.Expansion_Type_Action__c;

        if( creatingNew )
            action = mapping.New_Type_Action__c;

        if( action == 'Add' ){
            Double currentValue = sku.get( destApi ) == null ? 0 : Double.valueOf( sku.get( destApi ) );
            Double sourceValue = oli.get( sourceApi ) == null ? 0 : Double.valueOf( oli.get( sourceApi ) );
            Double addedValue = currentValue + sourceValue;
            sku.put( destApi, addedValue );
        } else if( action == 'Replace' || action == 'Insert' ){
            sku.put( destApi, oli.get( sourceApi) );
        }

    }


    /**
     * 'Fat Finger validation' to prevent the creation of duplicate Contracts due to manual inputting of the PPPId on the
     * Opportunity
     * @param oppsToValidate list of Opportuntities to validate
     */
    public void validatePPPIds( List<Opportunity> oppsToValidate ){

        if( trac_KillSwitchUtils.isDisabled('trac_OpportunityPlanHandler_validatePPPIds') )
            return;

        Set<String> pppIds = new Set<String>();
        List<Opportunity> filteredOpps = filterNewApprovedPlanOpps( oppsToValidate );
        for( Opportunity opp : filteredOpps ){
            pppIds.add( opp.Parent_Payment_Profile_ID__c );
        }

        List<Contract> contractList = [
            SELECT  Id, CreatedDate, Name, Payment_Profile_ID__c 
            FROM    Contract
            WHERE   Payment_Profile_ID__c in: pppIds
        ];    

        Map<String, Contract> contractsByPPPId = new Map<String, Contract>();

        for( Contract cont : contractList ){
            contractsByPPPId.put( cont.Payment_Profile_ID__c, cont );            
        }

        for( Opportunity opp : filteredOpps ){

            if( opp.Override_Fat_Finger_Validation__c )
                continue;

            Contract existingContract = contractsByPPPId.get( opp.Parent_Payment_Profile_ID__c );
            if( existingContract == null)
                continue;

            // If contract already exists
            //     It must have been created less than two days ago

            Datetime createdDT = existingContract.CreatedDate;
            Datetime nowDT = Datetime.now();

            Long createTime = createdDT.getTime();
            Long nowTime = nowDT.getTime();
            Long difference = ( nowTime - createTime ) / 1000 / 60 / 60;

            if( difference >= 48 )
                opp.addError( FAT_FINGER_ERROR_MESSAGE );

        }

    }

    public void flagOpportunitiesForIntegration( List<Opportunity> oppsToFlag ){

        for( Opportunity opp : oppsToFlag ){
            opp.Plan_Integration_Status__c = PENDING_INTEGRATION_STATUS;
        }

    }


    public List<Opportunity> filterApprovedPlanOpps( Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap ){
        
        List<Opportunity> filteredList = new List<Opportunity>();
        
        for( Opportunity newOpp : newMap.values() ){

            Opportunity oldOpp = oldMap.get( newOpp.Id );

            if( newOpp.Bill_To_Status__c != oldOpp.Bill_To_Status__c 
                    &&  newOpp.Bill_To_Status__c == OPP_CLOSED_STATUS
                    &&  newOpp.Plan_Integration_Status__c != SKUS_PROCESSED_STATUS ){
                filteredList.add( newOpp );
            }
        }

        return filteredList;
    
    }

    public List<Opportunity> filterNewApprovedPlanOpps( List<Opportunity> oppList ){

        List<Opportunity> filteredList = new List<Opportunity>();

        for( Opportunity newOpp : oppList ){
            if( newOpp.RecordTypeId == newRTId && String.isNotBlank( newOpp.Parent_Payment_Profile_ID__c ) ){
                filteredList.add( newOpp );                
            }
        }

        return filteredList;
    
    }

    private List<Opportunity> filterOppsByType( List<Opportunity> approvedOpps, String oppType ){
        List<Opportunity> filteredOpps = new List<Opportunity>();
        for( Opportunity opp : approvedOpps ){
            if( opp.RecordTypeId == oppType ){
                filteredOpps.add( opp );
            }
        }
        return filteredOpps;
    }

    private List<Opportunity_Plan_Mapping__mdt> queryOpportunityPlanMappings(){
        return [
            SELECT  Source_Field__c, Destination_Field__c, New_Type_Action__c, Renewal_Type_Action__c, Expansion_Type_Action__c
            FROM    Opportunity_Plan_Mapping__mdt
            WHERE 	Mapping_Type__c = 'OLI_to_SKU'
        ];
    }

    private Map<Id, Opportunity> queryOpps( Set<Id> oppIds ){
        
        return new Map<Id, Opportunity>([
            SELECT  Id, Pricebook2Id, Parent_Payment_Profile_ID__c, Contract.AccountId, Type, AccountId, RecordTypeId, (
                    SELECT  Id, Is_Recurring_Checkbox__c, Netsuite_Line_Item_ID__c, Netsuite_SO_ID__c, Product_Is_Recurring__c, 
                            Related_SKU__c, Rev_Rec_End_Date__c, Rev_Rec_Start_Date__c, ListPrice, Product2Id, Quantity, UnitPrice,
                            TotalPrice, Product2.Name, Discount__c, Primary_Subscription__c, CurrencyIsoCode, 
                            Product2.Primary_Subscription__c, Product2.Is_Recurring__c, Subscription_Discount__c
                    FROM    OpportunityLineItems
                )
            FROM    Opportunity
            WHERE   Id in :oppIds
        ]);

    }

    private Map<String, Contract> queryContracts( Set<String> pppIds ){
        
        List<Contract> contractList = [
            SELECT  Id, Payment_Profile_ID__c, AccountId, (   
                    SELECT  Id, Name, Product2Id, Quantity, Price, Discount__c, Netsuite_Line_Item_ID__c, Netsuite_SO_ID__c,
                            Rev_Rec_End_Date__c, Rev_Rec_Start_Date__c, Status, Primary_Subscription__c, CurrencyIsoCode,
                            Product2.Licensing__c, Per_Unit_Price__c, Product2.Primary_Subscription__c, Product2.Is_Recurring__c
                    FROM    SKUs__r
                )
            FROM    Contract
            WHERE   Payment_Profile_ID__c in :pppIds
        ];

        Map<String, Contract> contractMap = new Map<String, Contract>();
        for( Contract cont : contractList ){
        	contractMap.put(cont.Payment_Profile_ID__c, cont);
        }
        return contractMap;

    }

}