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
            whereClause += ' AND ' + getDynamicWhereCondition(dynamicFilter, 'fieloplt__payout__c', '');
        }           

        // Order By
        if (orderBy == null){
            orderBy = 'LastModifiedDate DESC';
        }
        
        // Limit
        if (quantity == null) {
            quantity = 10;
        }

        if (!payoutDescribe.isAccessible()) throw new FieloPLT.FieloException(String.format('is not Accessible', new List<String>{'FieloPLT__Payout__c'}));
        if (!pointDescribe.isAccessible()) throw new FieloPLT.FieloException(String.format('is not Accessible', new List<String>{'FieloPLT__Point__c'}));

        for(String f : fieldsPayoutSet) {
            if (payoutFields.containsKey(f) && !payoutFields.get(f).getDescribe().isAccessible()) {
                throw new FieloPLT.FieloException(String.format('is not Accessible', new List<String>{'FieloPLT__Payout__c',f}));
            }
        }

        for(String f : fieldsPayoutItem) {
            if (pointFields.containsKey(f) && !pointFields.get(f).getDescribe().isAccessible()) {
                throw new FieloPLT.FieloException(String.format('is not Accessible', new List<String>{'FieloPLT__Point__c',f}));
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
    private static Integer deepLevel = 0;
    public static String getDynamicWhereCondition(String jsonCondition, String objectName, String relatedField){
        List<FilterWrapper> filterWrappers;
        try{
            filterWrappers = (List<FilterWrapper>)JSON.deserializeStrict(jsonCondition, List<FilterWrapper>.class);
        }catch(Exception e){
            throw new FieloPLT.FieloException('InvalidJSONFormat');
        }

        if(filterWrappers.isEmpty()){
            return '';
        }

        Map<String,String> operatorsMap = new Map<String,String>{'equals'=>'=','equal'=>'=','eq'=>'=','='=>'=','not equals'=>'!=','not equal'=>'!=','not eq'=>'!=','!='=>'!=','<>'=>'!=','greater than'=>'>','gt'=>'>','>'=>'>','greater or equal'=>'>=','qe'=>'>=','>='=>'>=','less than'=>'<','lt'=>'<','<'=>'<','less or equal'=>'<=','le'=>'<=','<='=>'<=','in'=>'','like'=>'like'};
        Set<String> andoroperators = new Set<String>{'and','or'};
        Set<String> nonQuotedTypes = new Set<String>{'DOUBLE','DATETIME','DATE','CURRENCY','INTEGER','BOOLEAN','PERCENT','TIME'};
        Map<String,Schema.SObjectField> fieldsTypeMap = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe().fields.getMap();

        if(!String.isBlank(filterWrappers[0].andOrOperator)){
            throw new FieloPLT.FieloException('JsonInvalidOperator');
        }

        List<String> filterFields = new List<String>();
        for(FilterWrapper filter : filterWrappers){
            if(String.isNotBlank(filter.field))
                filterFields.add(filter.field);
        }


        deepLevel = 0;
        return getWhereCondition(filterWrappers, operatorsMap, andoroperators, nonQuotedTypes, fieldsTypeMap, relatedField);
    }

    private static String getWhereCondition(List<FilterWrapper> filterWrappers, Map<String,String> operatorsMap, Set<String> andoroperators, Set<String> nonQuotedTypes, Map<String,Schema.SObjectField> fieldsTypeMap, String relatedField){
        deepLevel++;
        String whereCondition = '';
        Integer position = 0;
        Integer parCounter = 0;
        Boolean hasOrConditions = false;
        Boolean hasInConditions = false;

        if (String.isBlank(relatedField) ){
            relatedField = '';
        } else {
            relatedField = relatedField + '.';
        }

        for(FilterWrapper filter : filterWrappers){
            if(!String.isBlank(filter.andOrOperator)){
                filter.andOrOperator = filter.andOrOperator.toLowerCase();
                if(!andoroperators.contains(filter.andOrOperator)){
                    throw new FieloPLT.FieloException(String.format('AndOrOperatorNotFound', new List<String>{filter.andOrOperator}));
                }
            }else if(position != 0){
                filter.andOrOperator = 'and';
            }

            if(String.isBlank(filter.field) || (!filter.field.contains('.') && !fieldsTypeMap.containsKey(filter.field))){
                throw new FieloPLT.FieloException(String.format('FieldNoFound', new List<String>{filter.field}));
            }

            if(!String.isBlank(filter.operator)){
                filter.operator      = filter.operator.toLowerCase();
                if(!operatorsMap.containsKey(filter.operator)){
                    throw new FieloPLT.FieloException(String.format('OperatorNotFound', new List<String>{filter.operator}));
                }
            }else{
                filter.operator = 'equals';
            }

            if(filter.operator == 'in' && filter.SubQueryFilter == null){
                throw new FieloPLT.FieloException('SubQueryFilterRequired');
            }

            if(!String.isBlank(filter.andOrOperator)){
                whereCondition += ' ' + filter.andOrOperator + ' ';

                if(filter.andOrOperator == 'or'){
                    hasOrConditions = true;
                }
            }

            if(String.isNotBlank(filter.openPars)){
                Integer i = 0;
                while(i < filter.openPars.length()){
                    if(filter.openPars.substring(i,i+1) != '('){
                        throw new FieloPLT.FieloException(String.format('IncorrectCaractOpenPars', new List<String>{filter.openPars}));
                    }else{
                        parCounter++;
                    }
                    i++;
                }
                whereCondition += filter.openPars;
            }

            if(filter.operator != 'in'){
                String fieldType = filter.field.contains('.') ? '' : fieldsTypeMap.get(filter.field).getDescribe().getType().name();
                if(filter.value == null){
                    whereCondition += relatedField + filter.field + ' ' + operatorsMap.get(filter.operator) + ' null ';
                }else if(nonQuotedTypes.contains(fieldType)){
                    whereCondition += relatedField + filter.field + ' ' + operatorsMap.get(filter.operator) + ' ' + filter.value;
                } else if(filter.operator == 'like'){
                    whereCondition += relatedField + filter.field + ' ' + operatorsMap.get(filter.operator) + ' \'%' + filter.value + '%\'';
                }else{
                    whereCondition += relatedField + filter.field + ' ' + operatorsMap.get(filter.operator) + ' \'' + filter.value + '\'';
                }
            }else{
                hasInConditions = true;
                if(deepLevel > 1){
                    throw new FieloPLT.FieloException('SubqueryNotSupported');
                }

                Schema.DescribeSobjectResult objDescribe = ((sObject)Type.forName(filter.subQueryFilter.objectName).newInstance()).getSObjectType().getDescribe();
                if(objDescribe == null){
                    throw new FieloPLT.FieloException(String.format('InvalidObjectSubQuery', new List<String>{filter.subQueryFilter.objectName}));
                }

                Map<String,Schema.SObjectField> fieldsTypeMapSubQuery = objDescribe.fields.getMap();
                if(String.isBlank(filter.subQueryFilter.field) || !fieldsTypeMapSubQuery.containsKey(filter.subQueryFilter.field)){
                    throw new FieloPLT.FieloException(String.format('FieldNoFound', new List<String>{filter.field}));
                }

                whereCondition += filter.field + ' in (SELECT ' + filter.subQueryFilter.field + ' FROM ' + filter.subQueryFilter.objectName + ' WHERE ' + getWhereCondition(filter.subQueryFilter.filters, operatorsMap, andoroperators, nonQuotedTypes, fieldsTypeMapSubQuery, '') + ')';
            }

            if(String.isNotBlank(filter.closePars)){
                Integer i = 0;
                while(i < filter.closePars.length()){
                    if(filter.closePars.substring(i,i+1) != ')'){
                        throw new FieloPLT.FieloException(String.format('IncorrectCaractClosePars', new List<String>{filter.closePars}));
                    }else{
                        parCounter--;
                    }
                    i++;
                }
                whereCondition += filter.closePars;
            }

            position++;
        }

        if(parCounter != 0){
            throw new FieloPLT.FieloException('ParenthesisError');
        }

        if(hasOrConditions){
            if(hasInConditions){
                throw new FieloPLT.FieloException('InvalidCondition');
            }else{
                return '(' + whereCondition + ')';
            }
        }else{
            return whereCondition;
        }
    }

    private class FilterWrapper{
        public String andOrOperator;
        public String openPars;
        public String field;
        public String operator;
        public String value;
        public String closePars;
        public SubQueryFilter subQueryFilter;
    }

    private class SubQueryFilter{
        public String field;
        public String objectName;
        public List<FilterWrapper> filters;
    }
    
}