public with sharing class MyPayoutsController {
    @auraEnabled
    public static List<FieloPLT__Payout__c> getMemberPayouts(List<String> fieldsPayout, List<String> fieldsPayoutItem, List<Id> payoutIds, Id memberId, Integer quantity, Integer offset, String dynamicFilter, String orderBy){
        Schema.DescribeSObjectResult payoutDescribe = ((sObject)Type.forName('FieloPLT__Payout__c').newInstance()).getSObjectType().getDescribe();
        Schema.DescribeSObjectResult pointDescribe = ((sObject)Type.forName('FieloPLT__Point__c').newInstance()).getSObjectType().getDescribe();
        Map<String, Schema.SObjectField> payoutFields = payoutDescribe.fields.getMap();
        Map<String, Schema.SObjectField> pointFields = pointDescribe.fields.getMap();

        Set<String> selectClauseItems = new Set<String>();
        Set<String> fieldsPayoutSet = new Set<String>(fieldsPayout);
        Set<String> fieldsPayoutItemSet = new Set<String>(fieldsPayoutItem);
        Set<Id> payoutIdsSet = new Set<Id>(payoutIds);

        selectClauseItems.addAll(fieldsPayoutSet);
        if (!fieldsPayoutItemSet.isEmpty()) {
            selectClauseItems.add('(SELECT ' + String.join(new List<String>(fieldsPayoutItemSet), ',') + ' FROM FieloPLT__Points__r) ');
        }

        String whereClause = ' WHERE FieloPLT__Member__c =: memberId ';
        if(String.isNotBlank(dynamicFilter)){
            whereClause += ' AND ' + SObjectService.getDynamicWhereCondition(dynamicFilter, 'fieloplt__payout__c', '');
        }           

        // Order By
        if (orderBy == null){
            orderBy = 'LastModifiedDate DESC';
        }
        
        // Limit
        if (quantity == null) {
            quantity = 10;
        }

        if (!payoutDescribe.isAccessible()) throw new FieloException(String.format(Label.security_error_object_not_readable, new List<String>{'FieloPLT__Payout__c'}));
        if (!pointDescribe.isAccessible()) throw new FieloException(String.format(Label.security_error_object_not_readable, new List<String>{'FieloPLT__Point__c'}));

        for(String f : fieldsPayoutSet) {
            if (payoutFields.containsKey(f) && !payoutFields.get(f).getDescribe().isAccessible()) {
                throw new FieloException(String.format(Label.security_error_field_not_readable, new List<String>{'FieloPLT__Payout__c',f}));
            }
        }

        for(String f : fieldsPayoutItem) {
            if (pointFields.containsKey(f) && !pointFields.get(f).getDescribe().isAccessible()) {
                throw new FieloException(String.format(Label.security_error_field_not_readable, new List<String>{'FieloPLT__Point__c',f}));
            }
        }

        String query = String.format('SELECT {0} FROM {1} {2} {3} {4} {5}',
            new List<string>{
                String.join(new List<String>(selectClauseItems), ','),
                'FieloPLT__Payout__c',
                String.isNotBlank(whereClause) ? whereClause : '',
                String.isNotBlank(orderBy) ? ('ORDER BY ' + orderBy) : '',
                ' LIMIT ' + (quantity != null ? String.valueOf(quantity) :  '10'),
                String.isNotBlank(String.valueOf(offset)) ? (' OFFSET ' + String.valueOf(offset)) :  ''
            }
        );

        System.debug(query);

        return (List<FieloPLT__Payout__c>) Database.query(query);
    }

    @auraEnabled
    public static String getFilterFields(String objectName, String fieldNames){
        try{        
            String fields = Fielo_AuraService.getFieldData(objectName, fieldNames, true);			
            return  fields;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
    }
}