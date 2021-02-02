public class MemberSelectorController {
    @auraEnabled
    public static List<FieloPLT__Member__c> getMembers(String fieldset){        
        try{                  
        	String userId = UserInfo.getUserId();
            Set<Id> idsPrograms = new Set<Id>();
            Set<Id> idsLevels = new Set<Id>();
            system.debug('fieldset: ' + fieldset);
        	String query = 'SELECT FieloPLT__CurrentLevelMember__c, FieloPLT__CurrentLevelMember__r.FieloPLT__Level__c, ' + fieldset + ' FROM FieloPLT__Member__c WHERE FieloPLT__User__C =: userId AND FieloPLT__Status__c != \'Merged\' AND FieloPLT__Status__c != \'Pending Merge\' AND FieloPLT__Status__c != \'Pending User\' AND FieloPLT__Status__c != \'Rejected\' AND FieloPLT__Status__c != \'Banned\'';
            List<FieloPLT__Member__c> members = database.query(query);
            String languageCode = UserInfo.getLanguage();
            List<FieloPLT__Language__c> language = [SELECT Id FROM FieloPLT__Language__c WHERE FieloPLT__Language__c =: languageCode AND FieloPLT__Status__c = 'Active'];
            
            if(!members.isEmpty() && !language.isEmpty()){
                for(FieloPLT__Member__c member: members){
                    idsPrograms.add(member.FieloPLT__Program__c);
                    if(member.FieloPLT__CurrentLevelMember__c != null && member.FieloPLT__CurrentLevelMember__r.FieloPLT__Level__c != null){
                        idsLevels.add(member.FieloPLT__CurrentLevelMember__r.FieloPLT__Level__c);
                    }
                }

                Map<Id, FieloPLT__Program__c> mapPrograms = new Map<Id, FieloPLT__Program__c>([SELECT Id, Name FROM FieloPLT__Program__c WHERE Id IN: idsPrograms]);
                Map<Id, FieloPLT__Level__c> mapLevels = new Map<Id, FieloPLT__Level__c>([SELECT Id, Name FROM FieloPLT__Level__c WHERE Id IN: idsLevels]);

                languageCode = UserInfo.getLanguage();
                TranslationService.getTranslations(mapPrograms.values(), languageCode);
                if(!mapLevels.isEmpty()){
                    TranslationService.getTranslations(mapLevels.values(), languageCode);
                }
                
                for(FieloPLT__Member__c member: members){
                    if(mapPrograms.containsKey(member.FieloPLT__Program__c)){
                        member.FieloPLT__Program__r.Name = mapPrograms.get(member.FieloPLT__Program__c).Name;
                    }
                    if(member.FieloPLT__CurrentLevelMember__c != null && mapLevels.containsKey(member.FieloPLT__CurrentLevelMember__r.FieloPLT__Level__c)){
                        member.FieloPLT__CurrentLevelMember__r.FieloPLT__Level__r.Name = mapLevels.get(member.FieloPLT__CurrentLevelMember__r.FieloPLT__Level__c).Name;
                    }
                }
                
            }
            return members;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @auraEnabled
    public static map<String, String> getFieldLabels(){
        map<String, String> mapFieldLabels = new map<String, String>();
        DescribeSObjectResult objectDescribe = Schema.describeSObjects(new String[]{'FieloPLT__Member__c'})[0];		
		mapFieldLabels.put('objectLabel', objectDescribe.getLabel());

        for(Schema.SObjectField sfield: Member__c.sObjectType.getDescribe().fields.getMap().Values()){
            Schema.Describefieldresult dfield = sfield.getDescribe();
            mapFieldLabels.put(dfield.getName(), dfield.getLabel());
        }

        return mapFieldLabels;
    }
    
}
