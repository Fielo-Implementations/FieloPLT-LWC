public with sharing class MyRedemptionsController {
    @auraEnabled
    public static List<FieloPLT__Redemption__c> getMemberRedemptions(List<String> fieldsRedemption, List<String> fieldsRedemptionItem, List<Id> redemptionIds, Id memberId, Integer quantity, Integer offset, String dynamicFilter, String orderBy){
        try{
            Set<String> fieldsRedemptionSet = new Set<String>(fieldsRedemption);
            Set<String> fieldsRedemptionItemSet = new Set<String>(fieldsRedemptionItem);
            Set<Id> redemptionIdsSet = new Set<Id>(redemptionIds);

            List<FieloPLT__Redemption__c> redemptions = FieloPLT.RedemptionService.getRedemptions(
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
        FieloPLT__Program__c program = getActiveProgram();
        Id programId = program.Id;//new MembersSelector(new Set<String>{'FieloPLT__Program__c'}).selectById(new Set<Id>{memberId})[0].Program__c;

        //Busco primero el program del member
        List<FieloPLT__ProgramPointType__c> ppts = new Fielo_ProgramPointTypesSelector(new Set<String>{'FieloPLT__PointType__r.FieloPLT__RewardBalanceField__c'}).selectByProgramWithoutPayouts(new Set<Id>{programId});

        Schema.DescribeSObjectResult objectDescribe = describeSObjects (new List<String>{'FieloPLT__Reward__c'})[0];

        Map<String, Schema.SObjectField> mapFieldDescribe = objectDescribe.fields.getMap();

        for(FieloPLT__ProgramPointType__c ppt: ppts){
        result.put(ppt.FieloPLT__PointType__r.FieloPLT__RewardBalanceField__c, mapFieldDescribe.get(ppt.FieloPLT__PointType__r.FieloPLT__RewardBalanceField__c).getDescribe().getLabel());
        }

    return result;
    }

    public static FieloPLT__Program__c getActiveProgram(){
        // Busca el id del Program Activo
        FieloPLT__Settings__c settings = FieloPLT__Settings__c.getInstance(UserInfo.getUserId());
        if(!String.isEmpty(settings.FieloPLT__CurrentProgramId__c)){
            try{
                FieloPLT__Program__c program = getProgram(settings.FieloPLT__CurrentProgramId__c);
                if(program != null){
                    return program;
                }
            }catch(Exception e){
                // Si falla por que el Id esta mal guardado continua

            }
        }
        // Si el usuario no tiene ninguno activo entonces activa el primero
        FieloPLT__Program__c program;
        if(hasPrograms()){
            program = hasPrograms() ? getPrograms().values().get(0) : null;
            settings.FieloPLT__CurrentProgramId__c = program.Id;
        }
        return program;
    }

    public static FieloPLT__Program__c getProgram(Id programId){
        if(programId != null && getPrograms().containsKey(programId)){
            return getPrograms().get(programId);
        }
        return null;
    }
    private static Map<Id, FieloPLT__Program__c> programMap;
    public static Map<Id,FieloPLT__Program__c> getPrograms(){

        if(programMap == null){
            programMap = new Map<Id, FieloPLT__Program__c>([SELECT Id, Name FROM FieloPLT__Program__c Limit 10000]);
        }
        return programMap;
    }
    public static Boolean hasPrograms(){
        return getPrograms().size() > 0;
    }

    public static List<Schema.DescribeSObjectResult> describeSObjects(List<String> objectNames){
		//poner todo toLowercase para evitar duplicados
		List<Schema.DescribeSObjectResult> result = new List<Schema.DescribeSObjectResult>();

		Set<String> conflictedObjects = new Set<String>();
		Set<String> allNames = new Set<String>();
		for(String name : objectNames){
			String toLowercase = name.toLowerCase();
			allNames.add(toLowercase);
			if(fieloObjects.contains(toLowerCase)){
				conflictedObjects.add(toLowerCase);
			}
		}

		if(conflictedObjects.isEmpty()){//no hay conflictivos
			result = Schema.describeSObjects(new List<String>(allNames));
		}else{
			for(String name : allNames){
				result.add(mapGlobalDescribe.get(name).getDescribe());
			}
		}

		return result;
    }
    
    private static Map<String, Schema.SObjectType> mapGlobalDescribe{
		get{
			if(mapGlobalDescribe == null){
				mapGlobalDescribe = Schema.getGlobalDescribe();
			}	
			return mapGlobalDescribe;
		}
		set;
    }
    
    private static Set<String> fieloObjects{
		get{
			if(fieloObjects == null){
				fieloObjects = new Set<String>{'action__c','action__share','action__tag','action__changeevent','adminpermission__c','adminpermission__tag','adminpermission__changeevent','agreement__c','agreement__history','agreement__tag','agreement__changeevent','auditpermission__c','auditpermission__tag','auditpermission__changeevent','badgemember__c','badgemember__tag','badgemember__changeevent','badge__c','badge__tag','badge__changeevent','capdomain__c','capdomain__share','capdomain__tag','capdomain__changeevent','cap__c','cap__share','cap__tag','cap__changeevent','challengemember__c','challengemember__tag','challengemember__changeevent','challengereward__c','challengereward__tag','challengereward__changeevent','challenge__c','challenge__history','challenge__tag','challenge__changeevent','consent__c','consent__share','consent__tag','consent__changeevent','criteriongroup__c','criteriongroup__share','criteriongroup__tag','criteriongroup__changeevent','criterion__c','criterion__share','criterion__tag','criterion__changeevent','emailalert__c','emailalert__share','emailalert__tag','emailalert__changeevent','emailcampaign__c','emailcampaign__share','emailcampaign__tag','emailcampaign__changeevent','emailtemplate__c','emailtemplate__share','emailtemplate__tag','emailtemplate__changeevent','errorlog__c','errorlog__share','errorlog__tag','errorlog__changeevent','event__c','event__tag','event__changeevent','kpidomain__c','kpidomain__share','kpidomain__tag','kpidomain__changeevent','kpi__c','kpi__share','kpi__tag','kpi__changeevent','levelmember__c','levelmember__tag','levelmember__changeevent','level__c','level__history','level__tag','level__changeevent','library__c','library__share','library__tag','library__changeevent','memberagreement__c','memberagreement__tag','memberagreement__changeevent','memberconsent__c','memberconsent__tag','memberconsent__changeevent','membersegment__c','membersegment__tag','membersegment__changeevent','member__c','member__share','member__tag','member__changeevent','missionmember__c','missionmember__share','missionmember__tag','missionmember__changeevent','mission__c','mission__share','mission__tag','mission__changeevent','model__c','model__share','model__tag','model__changeevent','pagesettings__c','pagesettings__share','pagesettings__tag','pagesettings__changeevent','pointtype__c','pointtype__tag','pointtype__changeevent','point__c','point__tag','point__changeevent','pointsusage__c','pointsusage__tag','pointsusage__changeevent','programassignment__c','programassignment__tag','programassignment__changeevent','programconsent__c','programconsent__tag','programconsent__changeevent','programpointtype__c','programpointtype__tag','programpointtype__changeevent','program__c','program__tag','program__changeevent','promotion__c','promotion__share','promotion__history','promotion__tag','promotion__changeevent','providerorder__c','providerorder__share','providerorder__tag','providerorder__changeevent','publicsettings__c','publicsettings__tag','publicsettings__changeevent','restsettings__c','restsettings__tag','restsettings__changeevent','redemptionitem__c','redemptionitem__tag','redemptionitem__changeevent','redemption__c','redemption__tag','redemption__changeevent','rewarditem__c','rewarditem__history','rewarditem__tag','rewarditem__changeevent','reward__c','reward__history','reward__tag','reward__changeevent','ruletrigger__c','ruletrigger__tag','ruletrigger__changeevent','rule__c','rule__history','rule__tag','rule__changeevent','segment__c','segment__history','segment__tag','segment__changeevent','settings__c','settings__tag','settings__changeevent','tracker__c','tracker__tag','tracker__changeevent','transaction__c','transaction__share','transaction__tag','transaction__changeevent','triggers__c','triggers__tag','triggers__changeevent'};
				/*for(Schema.SObjectType objType : mapGlobalDescribe.values()) {
					if(!objType.getDescribe().getName().contains('__history') && objType.getDescribe().getName().toLowercase().startsWith('fieloplt__')) {
						fieloObjects.add(objType.getDescribe().getName().toLowercase().removeStart('fieloplt__'));
					}
				}*/
				
        	}
			return fieloObjects;
		}
		set;
	}
}