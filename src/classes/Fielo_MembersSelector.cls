public without sharing class MembersSelector extends FieloPLT.SObjectSelector{

    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            FIeloPLT__Member__c.Id,
            FIeloPLT__Member__c.Name,
            FIeloPLT__Member__c.Email__c,
            FIeloPLT__Member__c.Program__c,
            FIeloPLT__Member__c.User__c,
            FIeloPLT__Member__c.Account__c,
            FIeloPLT__Member__c.Status__c,
            FIeloPLT__Member__c.OrganizationAccount__c,
            FIeloPLT__Member__c.Contact__c,
            FIeloPLT__Member__c.IsManager__c,
            FIeloPLT__Member__c.Type__c
        };
    }

    public MembersSelector(Set<String> fields){
        super(fields);
    }

    public MembersSelector(){
        super();
    }

    public Schema.SObjectType getSObjectType(){
        return FIeloPLT__Member__c.SObjectType;
    }

    public List<FIeloPLT__Member__c> selectById(Set<Id> memberIds){
        return (List<FIeloPLT__Member__c>) selectSObjectsById(memberIds);
    }

    /*
    * Durante el procesamiento este metodo se llama por lo menos 4 veces
    * Se usan variables estaticas para reducir cantidad de queries
    */
    private static Set<Id> memberStaticIds;
    public static List<FIeloPLT__Member__c> memberStaticList;
    public List<FIeloPLT__Member__c> selectActiveByIdForEngine(Set<Id> memberIds){
        Set<String> invalidStatus = Members.invalidStatus;
        String invalidType = 'Team';
        if( memberStaticIds == null ){
            memberStaticIds = memberIds;
        }
        if(  memberStaticList == null || memberStaticIds != memberIds ){
            memberStaticList = (List<FIeloPLT__Member__c>) Database.query(
                    String.format(
                    'select {0} ' +
                      'from {1} ' +
                      'where Id In: memberIds AND FieloPLT__Type__c !=: invalidType AND FieloPLT__Status__c NOT IN: invalidStatus ' +
                      '{2}',
                    new List<String> {
                        getFieldListString(),
                        getSObjectName(),
                        getOrderBy() } ) );
        }
        return memberStaticList;
    }

    public List<FIeloPLT__Member__c> selectActiveByIdForRedemption(Set<Id> memberIds){
        //Set<String> invalidStatus = Members.invalidStatus;
        Set<String> invalidStatus = Members.invalidStatusForRedemptions;
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Id In: memberIds AND FieloPLT__Status__c NOT IN: invalidStatus ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectActiveById(Set<Id> memberIds){
        Set<String> invalidStatus = Members.invalidStatus;
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Id In: memberIds AND FieloPLT__Status__c NOT IN: invalidStatus ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectOrgAccByAccountAndProgram(Set<Id> accountIds, Set<Id> programIds){
        assertIsAccessible();
        String stringType = 'Organization Account';
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Account__c In: accountIds AND Program__c IN: programIds AND Type__c =: stringType ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectIndividualAndContributorByAccount(Set<Id> accountIds){
        assertIsAccessible();
        String stringType = 'Organization Account';
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Account__c In: accountIds AND Type__c !=: stringType ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectByAccount(Set<Id> accountIds){
        assertIsAccessible();
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Account__c In: accountIds ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectOrgAccountByAccount(Set<Id> accountIds){
        assertIsAccessible();
        String stringType = 'Organization Account';
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Account__c In: accountIds AND Type__c =: stringType ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectIndividualAccountByAccount(Set<Id> accountIds){
        assertIsAccessible();
        String stringType = 'Individual Account';
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Account__c In: accountIds AND Type__c =: stringType ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectOrgAccountByIdWithChildrenCount(Set<Id> idSet){
        assertIsAccessible();
        String stringType = 'Organization Account';
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0}, (select {0} from FieloAccounts__r) ' +
                  'from {1} ' +
                  'where Id In: idSet AND Type__c =: stringType ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectByEmailAndProgram(Set<String> emails, Id programId){
        assertIsAccessible();
        Set<String> status = new Set<String>{'New','Approved'};
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Email__c In : emails AND Program__c =: programId AND Status__c in : status ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectTeamByName(Set<String> names){
        assertIsAccessible();
        String stringType = 'Team';
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Name In : names AND Type__c =: stringType ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectByEmail(Set<String> emails){
        assertIsAccessible();
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Email__c In: emails ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectOrganizationAccountByIdWithManager(Set<Id> orgAccountIds){
        assertIsAccessible();
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0}, (select Id from FieloAccounts__r where IsManager__c = TRUE) ' +
                  'from {1} ' +
                  'where Id In: orgAccountIds ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectOrganizationAccountByIdOrAccountWithManager(Set<Id> orgAccountIds, Set<Id> accountIds){
        assertIsAccessible();
        String stringType = 'Organization Account';
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'select {0}, (select Id from FieloAccounts__r where IsManager__c = TRUE) ' +
                  'from {1} ' +
                  'where (Id In: orgAccountIds OR Account__c In: accountIds) AND Type__c =: stringType ' +
                  '{2}',
                new List<String> {
                    getFieldListString(),
                    getSObjectName(),
                    getOrderBy() } ) );
    }

    public List<FIeloPLT__Member__c> selectFieloAccountByUser(Set<Id> userId){
        assertIsAccessible();
        Set<String> invalidStatus = Members.invalidStatus;
        return (List<FIeloPLT__Member__c>) Database.query(
                String.format(
                'SELECT {0}, {1} ' +
                  'FROM {2} ' +
                  'WHERE User__c IN: userId AND Status__c NOT IN: invalidStatus',
                new List<String> {
                    getFieldListString(),
                    getRelatedParentFieldListStringToLabel('FieloPLT__OrganizationAccount__r'),
                    getSObjectName()} ) );
    }

    public List<FIeloPLT__Member__c> selectByContact(Set<Id> contactIds){
        assertIsAccessible();
        String query = String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Contact__c In: contactIds ',
                new List<String> { getFieldListString(), getSObjectName() });

        return (List<FIeloPLT__Member__c>) Database.query(query);
    }

    public List<FIeloPLT__Member__c> selectByContactAndProgram(Set<Id> contactIds, Id programId){
        assertIsAccessible();
        String query = String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Contact__c In: contactIds AND Program__c =: programId',
                new List<String> { getFieldListString(), getSObjectName() });

        return (List<FIeloPLT__Member__c>) Database.query(query);
    }

    public List<FIeloPLT__Member__c> selectByOrganizationAccount(Id orgAccountId){
        assertIsAccessible();
        Set<String> invalidStatus = Members.invalidStatus;
        String query = String.format(
                'select {0} ' +
                  'from {1} ' +
                  'where Status__c NOT IN: invalidStatus AND OrganizationAccount__c =: orgAccountId {2} {3}',
                new List<String> {getFieldListString(),getSObjectName(),getLimitCondition(), getOffsetCondition()});

        return (List<FIeloPLT__Member__c>) Database.query(query);
    }

    public List<FIeloPLT__Member__c> selectByIdWithAvailablePoints(Set<Id> memberIds){
        assertIsAccessible();
        String statusString = 'Approved';
        String query = String.format(
                'select {0} ' +
                ' ,(SELECT Balance__c, PointType__c FROM Points__r WHERE Balance__c > 0 AND Status__c =: statusString) ' +
                  'from {1} ' +
                  'where Id In: memberIds {2} {3}',
                new List<String> {getFieldListString(),getSObjectName(),getLimitCondition(), getOffsetCondition()});

        return (List<FIeloPLT__Member__c>) Database.query(query);
    }

    public List<FIeloPLT__Member__c> selectByIdWithAvailablePointsByPointType(Set<Id> memberIds, Id pointType){
        assertIsAccessible();
        String statusString = 'Approved';
        String query = String.format(
                'select {0} ' +
                ' ,(SELECT Balance__c, PointType__c FROM Points__r WHERE Balance__c > 0 AND PointType__c =: pointType AND Status__c =: statusString) ' +
                  'from {1} ' +
                  'where Id In: memberIds {2} {3}',
                new List<String> {getFieldListString(),getSObjectName(),getLimitCondition(), getOffsetCondition()});

        return (List<FIeloPLT__Member__c>) Database.query(query);
    }

}