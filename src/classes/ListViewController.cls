public with sharing class ListViewController {
    
    @auraEnabled
    public static List<sObject> getRecords(String fieldset, String objectType, String whereCondition){
        try{
  
            if( !SecurityUtils.canRead(objectType, fieldset.split(',')) ){
                throw new FieloException(String.format(Label.security_error_field_not_readable, new List<String>{objectType, fieldset}));
            }
  
            whereCondition = String.isNotBlank(whereCondition) ? ' WHERE ' + String.escapeSingleQuotes(whereCondition) : '';
            return database.query('SELECT ' + fieldset + ' FROM ' + objectType + whereCondition);            
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }  
    }
    @auraEnabled
    public static map<String, String> getFieldLabels(String objectAPIName){ 
        DescribeSObjectResult objectDescribe = Schema.describeSObjects(new String[]{objectAPIName})[0];        
        map<String, String> mapFieldLabels = new map<String, String>();
        mapFieldLabels.put('objectLabelPlural', objectDescribe.getLabelPlural());
        mapFieldLabels.put('objectLabelSingular', objectDescribe.getLabel());
        for(Schema.SObjectField sfield: Schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().Values()){
            mapFieldLabels.put(sfield.getDescribe().getName(), sfield.getDescribe().getLabel());
        }
        return mapFieldLabels;
    }
    @auraEnabled
    public static string getFieldData(String objectAPIName, String fieldNames){ 
        return AuraService.getFieldData( objectAPIName, fieldNames, false );
    }   
  }