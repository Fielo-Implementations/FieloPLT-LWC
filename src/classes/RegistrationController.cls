public with sharing class RegistrationController {
    String labelValidEmail = 'Valid Email';
    
    @auraEnabled    
    public static List<FieloPLT__Program__c> getProgramsList(List<String> fields, List<Id> programIds, Integer quantity, Integer offset, String orderBy, String dynamicFilter){
        try{
            Set<String> fieldsSet = new Set<String>(fields);
            Set<Id> programIdsSet = new Set<Id>(programIds);
            List<FieloPLT__Program__c> result = getPrograms(
                  fieldsSet,
                  programIdsSet.size() == 0 ? null : programIdsSet,
                  orderBy,
                  quantity,
                  offset,
                  dynamicFilter);
            return result;            
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    @auraEnabled
    public static FieloPLT__Member__c registerMember(Id programId, Id agreementId){
        try{             
            String userId = UserInfo.getUserId();
            String userName = UserInfo.getName();
            String userEmail = UserInfo.getUserEmail();
            FieloPLT__Member__c member = new FieloPLT__Member__c(Name = userName, FieloPLT__Email__c = userEmail, FieloPLT__Program__c = programId, FieloPLT__User__c = userId, FieloPLT__Type__c = 'Individual Account', FieloPLT__Agreement__c = agreementId);
            //Members.communityRegistration = false;
            insert member;
            //Members.communityRegistration = true;
            return member;
        } catch(DMLException e) {
            throw new AuraHandledException(e.getDMLMessage(0));
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    @auraEnabled
    public static FieloPLT__Program__c getProgramInfo(String fields, Id programId){
        try{
            FieloPLT__Program__c programInfo = Database.query('SELECT ' + fields + ' FROM FieloPLT__Program__c WHERE Id = \'' + programId + '\'');
            return programInfo;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @auraEnabled
    public static String getObjectData(){                
        try{                                                        
            return Fielo_AuraService.getObjectData('FieloPLT__Program__c');            
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
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
    public static List<FieloPLT__Program__c> getPrograms(Set<String> fields, Set<Id> programIds, String orderBy, Integer quantity, Integer offset, String dynamicFilter){

        //seteo valores default si vienen nulos o vacios
        if(offset == null) offset = 0;
        if(orderBy == null) orderBy = 'createdDate DESC';
        if(fields == null || fields.isEmpty()){
            fields = new Set<String>{'id','name'};
        }

        //query de programs 
        String query = '';
        query += 'SELECT ' + String.join(new List<String>(fields), ',');
        query += ' FROM fieloplt__program__c';

        if(programIds != null){
            query += ' WHERE id IN: programIds';
        }
        if(String.isNotBlank(dynamicFilter)){
            query += programIds == null ? ' WHERE ' : ' AND ';
            query += getDynamicWhereCondition(dynamicFilter, 'fieloplt__program__c', '');
        }           
        query += ' ORDER BY ' + orderBy;
        query += quantity != null ? ' LIMIT ' + quantity : '';
        query += ' OFFSET ' + offset;
        
        List<FieloPLT__Program__c> programs;   
        try{
            system.debug('## query: ' + query);
            programs = Database.query(query);
        }catch(QueryException e){
            throw new FieloPLT.FieloException('Unable To PerfomQuery' + ' ' + e.getMessage());
        }
        return programs;
    }  
    public static String getDynamicWhereCondition(String jsonCondition, String objectName, String relatedField){
        List<FilterWrapper> filterWrappers;
        try{
            filterWrappers = (List<FilterWrapper>)JSON.deserializeStrict(jsonCondition, List<FilterWrapper>.class);
        }catch(Exception e){
            throw new FieloPLT.FieloException('Invalid JSON Format');
        }

        if(filterWrappers.isEmpty()){
            return '';
        }

        Map<String,String> operatorsMap = new Map<String,String>{'equals'=>'=','equal'=>'=','eq'=>'=','='=>'=','not equals'=>'!=','not equal'=>'!=','not eq'=>'!=','!='=>'!=','<>'=>'!=','greater than'=>'>','gt'=>'>','>'=>'>','greater or equal'=>'>=','qe'=>'>=','>='=>'>=','less than'=>'<','lt'=>'<','<'=>'<','less or equal'=>'<=','le'=>'<=','<='=>'<=','in'=>'','like'=>'like'};
        Set<String> andoroperators = new Set<String>{'and','or'};
        Set<String> nonQuotedTypes = new Set<String>{'DOUBLE','DATETIME','DATE','CURRENCY','INTEGER','BOOLEAN','PERCENT','TIME'};
        Map<String,Schema.SObjectField> fieldsTypeMap = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe().fields.getMap();

        if(!String.isBlank(filterWrappers[0].andOrOperator)){
            throw new FieloPLT.FieloException('Json Invalid Operator');
        }

        List<String> filterFields = new List<String>();
        for(FilterWrapper filter : filterWrappers){
            if(String.isNotBlank(filter.field))
                filterFields.add(filter.field);
        }

        deepLevel = 0;
        return getWhereCondition(filterWrappers, operatorsMap, andoroperators, nonQuotedTypes, fieldsTypeMap, relatedField);
    }

    private static Integer deepLevel = 0;
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
}