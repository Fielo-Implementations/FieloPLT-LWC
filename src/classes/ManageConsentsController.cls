public with sharing class ManageConsentsController {

	@auraEnabled
    public static String getConsents(Id recordId){
        try {            
            return  JSON.serialize(SObjectService.getConsents(recordId));
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @auraEnabled
    public static String getActiveConsents(Id recordId){
        try {            
            return  JSON.serialize(getActiveConsents(recordId));
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
        
    @auraEnabled
    public static String saveConsents(Id recordId, Map<Id, Boolean> consents){
        Savepoint sp;
        try {
            sp = Database.setSavepoint();
	        sObjectService.setConsents(recordId, consents);
            return  'success';
        } catch(DMLException e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getDMLMessage(0));
        } catch(Exception e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<FieloPLT__Consent__c> getActiveConsents(Id programId){
        Set<Id> consentIds = new Set<Id>();
        for(FieloPLT__ProgramConsent__c pc : [SELECT Id, FieloPLT__Consent__c FROM FieloPLT__ProgramConsent__c WHERE FieloPLT__Program__c =: programId]){
            if( pc.Consent__c != null ){
                consentIds.add(pc.Consent__c);
            }
        }
        return new ConsentsSelector(new Set<String>{'Name','FieloPLT__Description__c', 'FieloPLT__Code__c', 'FieloPLT__MemberText__c'}).selectById(consentIds);
    }
}