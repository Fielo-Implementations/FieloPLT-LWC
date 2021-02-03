public with sharing class MyBadgesController {
    
    @auraEnabled
    public static String getMemberBadges(List<String> fieldsBadge, List<String> fieldsBadgeMember, List<String> fieldsRule, List<String> fieldsChallengeReward, List<Id> badgesIds, Id memberId, String status, Integer quantity, Integer offset, String orderBy, String dynamicFilter){
        try{  

            Set<String> fieldsBadgeSet = new Set<String>(fieldsBadge);
            Set<String> fieldsBadgeMemberSet = new Set<String>(fieldsBadgeMember);
            Set<String> fieldsRuleSet = new Set<String>(fieldsRule);
            Set<String> fieldsChallengeRewardSet = new Set<String>(fieldsChallengeReward);            
            Set<Id> badgesIdsSet = new Set<Id>(badgesIds);    
            List<FieloPLT.BadgeService.BadgeWrapper> result = FieloPLT.BadgeService.getBadgesMap(
                  fieldsBadgeSet,
                  fieldsBadgeMemberSet,
                  fieldsRuleSet,
                  fieldsChallengeRewardSet,
                  badgesIdsSet.size() == 0 ? null : badgesIdsSet,
                  memberId,
                  status,
                  true,
                  orderBy,
                  quantity,
                  offset,
                  dynamicFilter,
                  true);       
            return JSON.serialize(result);                  
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }                        
    }           

    @auraEnabled    
    public static map<String, map<String, String>> getPicklistsValues(List<String> listPicklistsToTranslate){
        if(listPicklistsToTranslate == null || listPicklistsToTranslate.isEmpty()){return null;}

        map<String, map<String, String>> mapPicklistsValues = new map<String, map<String, String>>();

        for(String picklistAPIName: listPicklistsToTranslate){
            if(FieloPLT__Badge__c.sObjectType.getDescribe().fields.getMap().containsKey(picklistAPIName.toLowerCase())){
                Schema.Describefieldresult dfield = (FieloPLT__Badge__c.sObjectType.getDescribe().fields.getMap().get(picklistAPIName.toLowerCase())).getDescribe();
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
    @auraEnabled
    public static map<String, String> fieldLabels() {
        return Fielo_AuraService.getFieldLabels('BadgeMember');
    }    
}