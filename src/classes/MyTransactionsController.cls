public class MyTransactionsController {
    
    @auraEnabled
    public static List<FieloPLT__Transaction__c> getTransactions(List<String> fieldsTransactions,
                                                                 List<String> fieldsPoint,
                                                                 List<String> fieldsRedemption,
                                                                 List<String> fieldsBadgeMember,
                                                                 List<String> fieldsRevertedTransaction,
                                                                 List<Id> transactionIds,
                                                                 Id memberId,
                                                                 Integer quantity,
                                                                 Integer offset,
                                                                 String orderBy,
                                                                 String dynamicFilter
                                                                ){
        try{
            Set<String> fieldsTransactionsSet = new Set<String>(fieldsTransactions);
            Set<String> fieldsPointSet = new Set<String>(fieldsPoint);
            Set<String> fieldsRedemptionSet = new Set<String>(fieldsRedemption);
            Set<String> fieldsBadgeMemberSet = new Set<String>(fieldsBadgeMember);
            Set<String> fieldsRevertedTransactionSet = new Set<String>(fieldsRevertedTransaction);
            Set<Id> transactionIdsSet = new Set<Id>(transactionIds);
            
            List<FieloPLT__Transaction__c> myTransactions = FieloPLT.TransactionService.getTransactions(fieldsTransactionsSet,
                                                                                               memberId,
                                                                                               orderBy,
                                                                                               quantity,
                                                                                               offset,
                                                                                               dynamicFilter);
            return myTransactions;     
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }

    }            

    @auraEnabled    
    public static map<String, map<String, String>> getPicklistsValues(List<String> listPicklistsToTranslate){
        if(listPicklistsToTranslate == null || listPicklistsToTranslate.isEmpty()){return null;}

        map<String, map<String, String>> mapPicklistsValues = new map<String, map<String, String>>();

        for(String picklistAPIName: listPicklistsToTranslate){
            if(FieloPLT__Transaction__c.sObjectType.getDescribe().fields.getMap().containsKey(picklistAPIName.toLowerCase())){
                Schema.Describefieldresult dfield = (FieloPLT__Transaction__c.sObjectType.getDescribe().fields.getMap().get(picklistAPIName.toLowerCase())).getDescribe();
                if(String.ValueOf(dfield.getType()).toLowerCase() == 'picklist'){
                    mapPicklistsValues.put(picklistAPIName, new map<String, String>());
                    for (Schema.PicklistEntry pValues: dfield.getPicklistValues()) {
                        mapPicklistsValues.get(picklistAPIName).put(pValues.getValue(), pValues.getLabel());
                    }
                }
            }
        }

        return mapPicklistsValues;
    }
    
}