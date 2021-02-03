public with sharing class FilterController {
	@auraEnabled
    public static String getFilterFields(String objectName, String fieldNames){
        try{        
            String fields = Fielo_AuraService.getFieldData(objectName, fieldNames,true);			
            return  fields;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
    }
}