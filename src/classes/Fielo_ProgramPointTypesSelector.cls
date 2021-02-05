public with sharing class Fielo_ProgramPointTypesSelector extends Fielo_SObjectSelector{

    public Fielo_ProgramPointTypesSelector(Set<String> fields){
		super(fields);
	}

	public Fielo_ProgramPointTypesSelector(){
		super(new Set<String>{'FieloPLT__ActualPointCost__c','FieloPLT__AuditPoints__c','FieloPLT__Program__c','FieloPLT__PointType__c','FieloPLT__RequestPointApproval__c','FieloPLT__ExpirationMode__c','FieloPLT__DefaultExpirationMode__c','FieloPLT__DefaultExpirationValue__c','FieloPLT__DefaultExpirationDate__c','FieloPLT__PointType__r.Name','FieloPLT__PointType__r.FieloPLT__MemberBalanceField__c','FieloPLT__PointType__r.FieloPLT__TransactionBalanceField__c','FieloPLT__PointType__r.FieloPLT__RedemptionBalanceField__c','FieloPLT__PointType__r.FieloPLT__RedemptionItemBalanceField__c','FieloPLT__PointType__r.FieloPLT__RewardBalanceField__c','FieloPLT__PointType__r.FieloPLT__ConversionModeField__c','FieloPLT__PointType__r.FieloPLT__PointExpirationModeField__c',
		'FieloPLT__PointType__r.FieloPLT__ConversionValueField__c','FieloPLT__PointType__r.FieloPLT__MonthsUntilExpirationField__c','FieloPLT__PointType__r.FieloPLT__PointExpirationDateField__c', 'FieloPLT__PointType__r.FieloPLT__PointReflectionField__c','FieloPLT__PointType__r.FieloPLT__RecordFieldNameField__c','FieloPLT__PointType__r.FieloPLT__GeneratePayout__c'});
    }
    
    public List<FieloPLT__ProgramPointType__c> selectByProgramWithoutPayouts(Set<Id> programIds){
		return (List<FieloPLT__ProgramPointType__c>) Database.query(
				String.format(
				'select {0} ' +
				  'from {1} ' +
				  'where Fielo__Program__c in : programIds AND FieloPLT__PointType__r.GeneratePayout__c = false ' +
				  '{2}',
				new List<String> {
					getFieldListString(),
					getSObjectName(),
					getOrderBy() } ) );
    }
    
    public Schema.SObjectType getSObjectType(){
		return FieloPLT__ProgramPointType__c.sObjectType;
    }
    
    public List<Schema.SObjectField> getSObjectFieldList(){
		return new List<Schema.SObjectField> {
				FieloPLT__ProgramPointType__c.Id,
				FieloPLT__ProgramPointType__c.FieloPLT__Program__c,
				FieloPLT__ProgramPointType__c.FieloPLT__PointType__c,
				FieloPLT__ProgramPointType__c.FieloPLT__RequestPointApproval__c,
				FieloPLT__ProgramPointType__c.FieloPLT__ExpirationMode__c,
				FieloPLT__ProgramPointType__c.FieloPLT__AuditPoints__c
			};
	}

}