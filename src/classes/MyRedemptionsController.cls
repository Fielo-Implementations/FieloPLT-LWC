public with sharing class MyRedemptionsController {
    @auraEnabled
    public static List<FieloPLT__Redemption__c> getMemberRedemptions(List<String> fieldsRedemption, List<String> fieldsRedemptionItem, List<Id> redemptionIds, Id memberId, Integer quantity, Integer offset, String dynamicFilter, String orderBy){
        try{
            Set<String> fieldsRedemptionSet = new Set<String>(fieldsRedemption);
            Set<String> fieldsRedemptionItemSet = new Set<String>(fieldsRedemptionItem);
            Set<Id> redemptionIdsSet = new Set<Id>(redemptionIds);

            List<FieloPLT__Redemption__c> redemptions = RedemptionService.getRedemptions(
                fieldsRedemptionSet,
                fieldsRedemptionItemSet,
                redemptionIdsSet.size() == 0 ? null : redemptionIdsSet,
                memberId,
                orderBy,
                quantity,
                offset,
                dynamicFilter
                );
            return  redemptions;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @auraEnabled
    public static Map<String, String> getPointTypes(String memberId){
        Map<String, String> result = new Map<String, String>();
        Id programId = new MembersSelector(new Set<String>{'FieloPLT__Program__c'}).selectById(new Set<Id>{memberId})[0].Program__c;

        //Busco primero el program del member
        List<ProgramPointType__c> ppts = new ProgramPointTypesSelector(new Set<String>{'FieloPLT__PointType__r.FieloPLT__RewardBalanceField__c'}).selectByProgramWithoutPayouts(new Set<Id>{programId});

        Schema.DescribeSObjectResult objectDescribe = FieloPLT.SObjectDescribe.describeSObjects (new List<String>{'FieloPLT__Reward__c'})[0];

        Map<String, Schema.SObjectField> mapFieldDescribe = objectDescribe.fields.getMap();

        for(ProgramPointType__c ppt: ppts){
        result.put(ppt.PointType__r.RewardBalanceField__c, mapFieldDescribe.get(ppt.PointType__r.RewardBalanceField__c).getDescribe().getLabel());
        }

    return result;
    }
}