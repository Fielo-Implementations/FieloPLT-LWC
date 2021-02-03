public class Fielo_AuraService {

/*    // Code used Backend
    // Get the List of Incentives available for a specific Budget
    @AuraEnabled
    public static List<Map<String,Object>> getIncentivesForBudget( String budgetId ){
        return getIncentivesForBudget( budgetId, null );
    }

    @AuraEnabled
    public static List<Map<String,Object>> getIncentivesForBudget( String budgetId, String earmarkId ){
        Map<Id, Map<String,Object>> incentives = new Map<Id, Map<String,Object>>();
        if( String.isBlank(budgetId) ){
            throw new AuraHandledException(Label.InvalidValue);
        }
        Budget__c budget = [SELECT Program__c, StartDate__c, EndDate__c FROM Budget__c WHERE Id = :budgetId];
        if( budget == null ){
            throw new AuraHandledException(Label.InvalidValue);
        }

        // Make the Where Condition to Filter Rules and Missions With a Budget Reward
        String rulesFilter = '';
        for ( ProgramPointType__c ppt : [SELECT ActualPointCost__c, PointType__r.ConversionModeField__c FROM ProgramPointType__c WHERE Program__c = :budget.Program__c AND ActualPointCost__c > 0] ) {
            if ( ppt.PointType__r.ConversionModeField__c != null ) {
                rulesFilter +=  ' OR ' + ppt.PointType__r.ConversionModeField__c + ' <> NULL ';
            }
        }
        // If there are no point types for budget in the program return an empty list
        if( rulesFilter == '' ){
            return incentives.values();
        }
        rulesFilter = rulesFilter.substring(3);
        // Create a Set of Promotions, Challenges, Rules and Missions already in the Budget
        Set<Id> filterIncentives = new Set<Id>();
        List<EarmarkDomain__c> budetEarmarkDomains = [SELECT Earmark__c, Promotion__c, Promotion__r.Name, Promotion__r.Period__c,  Challenge__c, Challenge__r.Name, Challenge__r.Period__c, Rules__c  FROM EarmarkDomain__c  WHERE Earmark__r.Budget__c = :budgetId] ;
        for ( EarmarkDomain__c earmarkDomain : budetEarmarkDomains ) {
            if ( earmarkDomain.Rules__c == 'ALL' || earmarkDomain.Rules__c == null || earmarkDomain.Rules__c == '' ) {
                if ( earmarkDomain.Challenge__c != null ) {
                    filterIncentives.add( earmarkDomain.Challenge__c );
                } else if ( earmarkDomain.Promotion__c != null ) {
                    filterIncentives.add( earmarkDomain.Promotion__c );
                }
            } else {
                for (  String rule: earmarkDomain.Rules__c.split(';') ) {
                    if ( rule InstanceOf Id ) {
                        filterIncentives.add( (Id) rule );
                    }
                }
            }
        }
        system.debug('filterIncentives: ' + filterIncentives);

        // If argument earmarkId is not null (Edit Mode)
        // Returns the incentives Map of the Earmark with selected = true
        if ( earmarkId != null ) {
            Set<Id> ruleIds = new Set<Id> ();
            Set<Id> missionIds = new Set<Id> ();
            Map<Id, String> mapNames = new Map<Id, String>();
            for ( EarmarkDomain__c earmarkDomain : budetEarmarkDomains ) {
                if ( earmarkDomain.Rules__c != 'All' && earmarkDomain.Rules__c != '' && earmarkDomain.Rules__c !=  null ) {
                    if ( earmarkDomain.Promotion__c != null ) {
                        for ( String r :earmarkDomain.Rules__c.split(';') ) {
                            if ( r InstanceOf Id ) {
                                ruleIds.add( r );
                            }
                        }
                    } else if ( earmarkDomain.Challenge__c != null ) {
                        for ( String r :earmarkDomain.Rules__c.split(';') ) {
                            if ( r InstanceOf Id ) {
                                missionIds.add( r );
                            }
                        }
                    }
                }
            }
            if ( !ruleIds.isEmpty() ) {
                for ( Rule__c r : [SELECT Id, Name FROM Rule__c WHERE Id IN :ruleIds] ) {
                    mapNames.put( r.Id, r.Name );
                }
            }
            if ( !missionIds.isEmpty() ) {
                for(Id mission : missionIds){
                    String mType = getObjectNameByRecordId(mission);
                    if(mType == 'FieloPLT__Challenge__c'){
                        Challenge__c m = [SELECT Id, Name FROM Challenge__c WHERE Id = :missionIds];
                        mapNames.put( m.Id, m.Name );
                    } else {
                        Mission__c m = [SELECT Id, Name FROM Mission__c WHERE Id = :missionIds];
                        mapNames.put( m.Id, m.Name );
                    }
                }
            }

            for ( EarmarkDomain__c earmarkDomain : budetEarmarkDomains ) {
                if ( earmarkDomain.Earmark__c == earmarkId ) {
                    List<Map<String,Object>> options = new List<Map<String,Object>>();
                    if ( earmarkDomain.Rules__c != 'All' && earmarkDomain.Rules__c != '' && earmarkDomain.Rules__c !=  null ) {
                        for ( String r :earmarkDomain.Rules__c.split(';') ) {
                            if ( r InstanceOf Id ) {
                                options.add( new Map<String, Object>{ 'selected'=> true, 'value' => r, 'label' =>  mapNames.get(r) } );
                            }
                        }
                    }

                    if ( earmarkDomain.Promotion__c != null ){
                        incentives.put( earmarkDomain.Promotion__c, new Map<String,Object>{ 'selected' => true,
                            'type' => 'Promotion' ,
                            'value' => earmarkDomain.Promotion__c,
                            'label' => earmarkDomain.Promotion__r.Name,
                            'period' =>  earmarkDomain.Promotion__r.Period__c,
                            'options' => options } );
                    } else if ( earmarkDomain.Challenge__c != null ){
                        incentives.put( earmarkDomain.Challenge__c, new Map<String,Object>{ 'selected' => true,
                            'type' => 'Challenge' ,
                            'value' => earmarkDomain.Challenge__c,
                            'label' => earmarkDomain.Challenge__r.Name,
                            'period' => earmarkDomain.Challenge__r.Period__c,
                            'options' => options } );
                    }
                }
            }
        }

        List<String> activeStatus =  new List<String>{ 'Active' , 'Scheduled' } ;
        Id programId = budget.Program__c;
        Date startDate = budget.StartDate__c;
        Date endDate = budget.EndDate__c;
        // Add Promotions
        List<Promotion__c> promotions = Database.query( 'SELECT Id, Name, Period__c, ' +
                            ' (SELECT Id, Name FROM Rules__r WHERE ' + rulesFilter + ' ) ' +
                            ' From Promotion__c ' +
                            ' WHERE  Program__c = :programId ' +
                            (earmarkId == null ? ' AND ID NOT IN  :filterIncentives ' : '') +
                            ' AND Status__c in :activeStatus ' +
                            ' AND ( StartDate__c <= :endDate OR StartDate__c = NULL ) ' +
                            ' AND ( EndDate__c >=  :startDate OR EndDate__c = NULL )' );
        for ( Promotion__c promotion: promotions) {
            // Add options List
            List<Map<String,Object>> options = new List<Map<String,Object>>();
            for ( Rule__c rule: promotion.Rules__r ){
                if ( !filterIncentives.contains(rule.Id) ) {
                    options.add( new Map<String, Object>{ 'selected' => false, 'value' => rule.Id, 'label' =>  rule.Name } );
                }
            }

            if (!options.isEmpty()  ) {
                if ( incentives.containsKey(promotion.Id)  ) {
                    ((List<Map<String,Object>>)incentives.get(promotion.Id).get('options')).addAll(options);
                } else {
                    incentives.put( promotion.Id, new Map<String,Object> { 'selected' => false, 'type' => 'Promotion' ,
                        'value' => promotion.Id,
                        'label' => promotion.Name,
                        'period' =>  promotion.Period__c,
                        'options' => options  } );
                }
            }
        }

        // Add Challenges
        List<Challenge__c> challenges = Database.query( 'SELECT Id, Name, Period__c, ' +
                            ' (SELECT Id, Mission__c, Mission__r.Name FROM ChallengeRewards__r WHERE ' + rulesFilter + ' ) ' +
                            ' From Challenge__c ' +
                            ' WHERE  Program__c = :programId ' +
                            (earmarkId == null ? ' AND ID NOT IN  :filterIncentives ' : '') +
                            ' AND Status__c in :activeStatus ' +
                            ' AND ( StartDate__c <= :endDate OR StartDate__c = NULL ) ' +
                            ' AND ( EndDate__c >=  :startDate OR EndDate__c = NULL )' );
        for ( Challenge__c challenge: challenges) {
            // Add options List
            Map<String, String> missions = new Map<String, String>();
            for ( ChallengeReward__c challengeReward: challenge.ChallengeRewards__r ) {
                if ( challengeReward.Mission__c != null && !filterIncentives.contains(challengeReward.Mission__c) ) {
                    missions.put( challengeReward.Mission__c, challengeReward.Mission__r.Name );
                } else {
                    missions.put( challenge.id, challenge.Name );
                }
            }

            if ( !missions.isEmpty() ) {
                List<Map<String,Object>> options = new List<Map<String,Object>>();
                for ( String missionId  :missions.keySet() ) {
                    options.add( new Map<String, Object>{ 'selected'=> false, 'value' => missionId, 'label' =>  missions.get(missionId) } );
                }

                if ( incentives.containsKey(challenge.Id)  ) {
                    ((List<Map<String,Object>>)incentives.get(challenge.Id).get('options')).addAll(options);
                } else {
                    incentives.put( challenge.Id, new Map<String,Object>{ 'selected' => false, 'type' => 'Challenge' ,
                        'value' => challenge.Id,
                        'label' => challenge.Name,
                        'period' =>  challenge.Period__c,
                        'options' => options } );
                }
            }
        }
        return incentives.values();
    }
*/
    // Code used by communities
    @AuraEnabled
    public static Map<String, String> getFieldLabels(String objectAPIName){
        DescribeSObjectResult objectDescribe = Schema.describeSObjects(new String[]{objectAPIName})[0];
        Map<String, String> mapFieldLabels = new Map<String, String>();
        mapFieldLabels.put('objectLabelPlural', objectDescribe.getLabelPlural());
        mapFieldLabels.put('objectLabelSingular', objectDescribe.getLabel());
        for(Schema.SObjectField sfield: objectDescribe.fields.getMap().Values()){
            mapFieldLabels.put(sfield.getDescribe().getName(), sfield.getDescribe().getLabel());
        }
        return mapFieldLabels;
    }
/*
    // Code used by communities
    public static Map<String, DescribeFieldResult> getFieldsDescribe(String objectName, List<String> fieldNames) {
        DescribeSObjectResult objectDescribe = Schema.describeSObjects(new String[]{objectName})[0];
        Map<String,Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        Map<String, DescribeFieldResult> result = new Map<String, DescribeFieldResult>();
        for(String fieldName: fieldNames) {
            if (fieldMap.containsKey(fieldName)) {
                result.put(fieldName, fieldMap.get(fieldName).getDescribe());
            }
        }
        return result;
    }
    @AuraEnabled(cacheable=true)
    public static String getLabel(String labelName, String language){
        if (String.isNotBlank(labelName)) {
            Pagereference r = Page.CcLabelTranslator;
            r.getParameters().put('label_lang', language);
            r.getParameters().put('label', labelName);
            String labelValue = r.getContent().toString();
            return labelValue;
        }
        return '';
    }
    // Code used by communities
    @AuraEnabled
    public static String getCommunitySuffix(){
        String pref = '';
        if(Network.getNetworkId() != null){
            Id networkId = Id.valueOf(Network.getNetworkId());
            try{
                //List<Network> lst = new SObjectsSelector().queryCommunitySuffix(networkId);
                List<Sobject> lst = new SObjectsSelector().queryCommunitySuffix(networkId);
                if(!lst.isEmpty()){
                    pref = (String) (lst.get(0)).get('urlPathPrefix');
                }
            }catch(QueryException e){
                throw new FieloException(label.UnableToPerfomQuery + ' ' + e.getMessage());
            }
        }
        return pref;
    }

    // Code used by communities and backend
    @AuraEnabled
    public static String getObjectData(String objectName) {
        DescribeSObjectResult objectDescribe = Schema.describeSObjects(new String[]{objectName})[0];
        Map<String, Object> objectInfo = new Map<String, Object>();
        objectInfo.put('label', (Object) objectDescribe.getLabel());
        objectInfo.put('labelplural', (Object) objectDescribe.getLabelPlural());
        objectInfo.put('name', (Object) objectDescribe.getName());
        objectInfo.put('prefix', (Object) objectDescribe.getKeyPrefix());

        // To Be Used in the BeList when it is a Related List
        Map<String,String> relationshipsInfo = new Map<String,String>();
        for(Schema.sObjectField fieldObj : objectDescribe.fields.getMap().values()) {
            if(fieldObj.getDescribe().getType().name() == 'reference' && String.isNotBlank(fieldObj.getDescribe().getRelationshipName())) {
                relationshipsInfo.put(fieldObj.getDescribe().getRelationshipName(), fieldObj.getDescribe().getName());
            }
        }
        objectInfo.put('parentRelationships', (Object) relationshipsInfo);

        return JSON.serialize(objectInfo);
    }
*/
    // Code used by communities and backend
    @AuraEnabled(cacheable=true)
    public static String getFieldData(String objectName, String fieldNames, Boolean enableDependentPicklist) {
        if(String.isBlank(objectName)) return '';
        Boolean isRank = false;
        if( objectName == 'FieloPLT__RankMember__c' ){
            isRank = true;
            objectName = 'FieloPLT__LevelMember__c';
        } else if( objectName == 'FieloPLT__Rank__c' ){
            isRank = true;
            objectName = 'FieloPLT__Level__c';
        }

        DescribeSObjectResult objectDescribe = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe();
        Map<String, Object> objectInfo = new Map<String, Object>();
        String objectLabel = String.valueOf(objectDescribe.getLabel());
        String objectLabelPlural = String.valueOf(objectDescribe.getLabelPlural());
        String objectApiName = String.valueOf(objectDescribe.getName());
        if( isRank ){
            objectLabel = objectLabel.replace('Level', 'Rank');
            objectLabelPlural = objectLabelPlural.replace('Level', 'Rank');
            objectApiName = objectApiName.replace('Level', 'Rank');
        }

        //Object
        objectInfo.put('label', objectLabel);
        objectInfo.put('labelplural', objectLabelPlural);
        objectInfo.put('name', objectApiName);
        objectInfo.put('prefix', (Object) objectDescribe.getKeyPrefix());

        //Get fields
        Set<String> fieldNamesSet = new Set<String>();
        if( fieldNames != null && fieldNames != '' ){
            fieldNamesSet.addAll( fieldNames.split(',') );
        }
        Map<String,Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        List<String> labels = new List<String>();
        Map<String, Schema.SObjectField> fieldsMap = new Map<String, Schema.SObjectField>();
        Map<String,String> objectNameByrelationship = new Map<String,String>();

        for(String s : fieldMap.keySet()){
            String campo = fieldMap.get(s).getDescribe().getName();
            if( isRank ){
                campo = campo.replace('Level', 'Rank');
            }
            if (fieldMap.get(s).getDescribe().getType().name().toLowerCase() == 'reference') {
                objectNameByrelationship.put( fieldMap.get(s).getDescribe().getRelationshipName(),
                    fieldMap.get(s).getDescribe().getReferenceTo().get(0).getDescribe().getName()
                );
            }
            if( fieldNamesSet.isEmpty() || (fieldNamesSet.contains(campo) && fieldMap.get(s).getDescribe().isAccessible()) ){
                String label = fieldMap.get(s).getDescribe().getLabel();
                if( isRank && label.contains('Level') ){
                    label = label.replace('Level', 'Rank');
                }
                if(labels.contains(label)){
                    label = label + ' (1)';
                }
                labels.add( label );
                fieldsMap.put(label, fieldMap.get(s));
            }
        }

        Map<String,Set<String>> relatedFields = new Map<String,Set<String>>();
        for (String fName : fieldNamesSet) {
            if (fName.contains('.')) {
                List<String> objectFieldArray = fName.split('\\.', 2);
                if (relatedFields.containsKey(objectFieldArray[0]) ) {
                    relatedFields.get(objectFieldArray[0]).add(objectFieldArray[1]);
                } else {
                    relatedFields.put(objectFieldArray[0], new Set<String>{objectFieldArray[1]});
                }
            }
        }
        labels.sort();

        DescribeSObjectResult relatedObjectDescribe;
        List<Map<String, Object>> fieldsInfo = new List<Map<String, Object>>();
        Map<String, Object> fieldAttributes;
        List<Map<String, String>> picklistEntries;
        DescribeFieldResult fieldDescribe;
        for( String l: labels ){
            fieldsInfo.add(new Map<String, Object>());
            fieldDescribe = fieldsMap.get(l).getDescribe();
            fieldAttributes = new Map<String, Object>();
            fieldAttributes.put('objectName', objectDescribe.getName());
            fieldAttributes.put('objectLabel', objectDescribe.getLabel());
            fieldAttributes.put('label', l);
            String fieldName = fieldDescribe.getName();
            if( isRank ){
                fieldName = fieldDescribe.getName().replace('Level', 'Rank');
            }
            fieldAttributes.put('name', fieldName);
            fieldAttributes.put('type', fieldDescribe.getType().name().toLowerCase());
            fieldAttributes.put('inputType', inputTypeMap.get(fieldDescribe.getType().name().toLowerCase()));
            fieldAttributes.put('jsType', jsPrimitiveTypeMap.get((String) fieldAttributes.get('type')));
            fieldAttributes.put('isQuoted', isQuoted.get((String) fieldAttributes.get('type')));
            fieldAttributes.put('soaptype', fieldDescribe.getSOAPType().name().toLowerCase());
            fieldAttributes.put('scale', String.valueOf(fieldDescribe.getScale()));
            fieldAttributes.put('precision', String.valueOf(fieldDescribe.getPrecision()));
            fieldAttributes.put('tooltip', fieldDescribe.getInlineHelpText());
            fieldAttributes.put('isAccessible', String.valueOf(fieldDescribe.isAccessible()));
            fieldAttributes.put('isCreateable', String.valueOf(fieldDescribe.isCreateable()));
            fieldAttributes.put('isUpdateable', String.valueOf(fieldDescribe.isUpdateable()));
            fieldAttributes.put('isIdLookup', String.valueOf(fieldDescribe.isIdLookup()));
            fieldAttributes.put('isNillable', String.valueOf(fieldDescribe.isNillable()));
            if (fieldDescribe.getScale()!=null) {
                if(fieldDescribe.getScale() == 0){
                    fieldAttributes.put('step', '1' );
                }else{
                    fieldAttributes.put('step', '0.' + '0'.repeat(fieldDescribe.getScale()-1) + '1' );
                }
            }
            fieldAttributes.put('helpText', fieldDescribe.getInlineHelpText());
            fieldAttributes.put('id', fieldDescribe.getName().replace('_',''));
            if ( fieldAttributes.get('type') == 'picklist' || fieldAttributes.get('type') == 'multipicklist' ) {
                picklistEntries = new List<Map<String, String>>();
                fieldAttributes.put('defaultValue', '');
                fieldAttributes.put('isDependentPicklist', String.valueOf(fieldDescribe.isDependentPicklist()));
                if(!enableDependentPicklist){
                    fieldAttributes.put('isDependentPicklist', String.valueOf(false));
                }
                if (enableDependentPicklist && fieldDescribe.isDependentPicklist()) {
                    fieldAttributes.put('controllerField', String.valueOf(fieldDescribe.getController()));
                    Map<String, Object> validPicklistOptions = (Map<String, Object>) JSON.deserializeUntyped(Fielo_FormController.getDependentOptions(
                                fieldDescribe.getController().getDescribe().getPicklistValues(),
                                fieldDescribe.getPicklistValues()
                            ) );

                    fieldAttributes.put('validPicklistOptions', (Object) validPicklistOptions);
                }


                for (Schema.PicklistEntry pValues: fieldDescribe.getPicklistValues()) {
                    picklistEntries.add(new Map<String, String>{'value' => pValues.getValue(),'label'=> pValues.getLabel()});
                    if (pValues.isDefaultValue()) {
                        fieldAttributes.put('defaultValue', pValues.getValue());
                    }
                }
                if (!picklistEntries.isEmpty()) {
                    fieldsInfo.get(fieldsInfo.size()-1).put('picklistentries', (Object) picklistEntries);
                }
            }
            if (fieldAttributes.get('type') == 'date') {
                fieldAttributes.put('timeZone', UserInfo.getTimeZone().getID());
            }
            if (fieldAttributes.get('type') == 'currency') {
                fieldAttributes.put('currencyCode', UserInfo.getDefaultCurrency());
                fieldAttributes.put('formatter', 'currency');
            }
            if (fieldAttributes.get('type') == 'percent') {
                fieldAttributes.put('formatter', 'percent');
            }
            if (fieldAttributes.get('type') == 'reference') {
                relatedObjectDescribe = fieldDescribe.getReferenceTo()[0].getDescribe();
                fieldAttributes.put('referenceToNameField', getNameField(relatedObjectDescribe));
                if( isRank ){
                    fieldAttributes.put('referenceTo', relatedObjectDescribe.getName().replace('Level', 'Rank'));
                    fieldAttributes.put('referenceToLabel', relatedObjectDescribe.getLabel().replace('Level', 'Rank'));
                    fieldAttributes.put('relationshipName', fieldDescribe.getRelationshipName().replace('Level', 'Rank'));
                } else {
                    fieldAttributes.put('referenceTo', relatedObjectDescribe.getName());
                    fieldAttributes.put('referenceToLabel', relatedObjectDescribe.getLabel());
                    fieldAttributes.put('relationshipName', fieldDescribe.getRelationshipName());
                }
            }
            fieldsInfo.get(fieldsInfo.size()-1).put('attributes', (Object) fieldAttributes);
        }

        if (!relatedFields.isEmpty()) {
            for (String obj: relatedFields.keySet()) {
                try{
                    Map<String, Object> relFieldAttributes;
                    Map<String, Object> relFieldInfo;
                    Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(getFieldData(objectNameByrelationship.get(obj), String.join(new List<String>(relatedFields.get(obj)),','), enableDependentPicklist));
                    for (Object relField : ((List<Object>)data.get('fields'))) {
                        relFieldInfo = new Map<String, Object>((Map<String, Object>)relField);
                        relFieldAttributes = (Map<String, Object>) relFieldInfo.get('attributes');
                        relFieldAttributes.put('name', (object) obj + '.' + String.valueOf(relFieldAttributes.get('name')) );
                        if(relFieldAttributes.containsKey('labelPath')){
                            relFieldAttributes.put('labelPath', (object) String.valueOf(objectInfo.get('label')) + ' > ' + String.valueOf(relFieldAttributes.get('labelPath')) );
                        }else{
                            relFieldAttributes.put('labelPath', (object) String.valueOf(objectInfo.get('label')) + ' > ' + String.valueOf(relFieldAttributes.get('objectLabel'))  + ' > ' + String.valueOf(relFieldAttributes.get('label')) );
                        }

                        relFieldInfo.put('attributes', (object) relFieldAttributes);
                        fieldsInfo.add(relFieldInfo);
                    }
                } catch(Exception e) {
                    System.debug(e.getMessage());
                }
            }
        }
        objectInfo.put('fields', (Object) fieldsInfo);
        return JSON.serialize(objectInfo);
    }
/*
    @AuraEnabled(cacheable=true)
    public static String getWiredFieldData(String objectName, String fieldNames, Boolean enableDependentPicklist) {
        return getFieldData(objectName, fieldNames, enableDependentPicklist);
    }
*/
    // Code used by communities and backend
    public static Map<String, String> inputTypeMap {get{
        if (inputTypeMap == null) {
            inputTypeMap = new Map<String,String>{
                'address' => 'text',
                'anytype' => 'none',
                'base64' => 'text',
                'boolean' => 'checkbox',
                'combobox' => 'checkbox',
                'currency' => 'number',
                'datacategorygroupreference' => 'none',
                'date' => 'date',
                'datetime' => 'datetime',
                'double' => 'number',
                'email' => 'email',
                'encryptedstring' => 'text',
                'id' => 'text',
                'integer' => 'text',
                'multipicklist' => 'text',
                'percent' => 'number',
                'phone' => 'text',
                'picklist' => 'picklist',
                'reference' => 'reference',
                'string' => 'text',
                'textarea' => 'text',
                'time' => 'time',
                'url' => 'url'
            };
        }
        return inputTypeMap;
    } set;}

    // Code used by communities and backend
    public static Map<String, String> isQuoted {get{
        if (isQuoted == null) {
            isQuoted = new Map<String,String>{
                'address' => 'true',
                'anytype' => 'true',
                'base64' => 'true',
                'boolean' => 'false',
                'combobox' => 'false',
                'currency' => 'false',
                'datacategorygroupreference' => 'false',
                'date' => 'false',
                'datetime' => 'false',
                'double' => 'false',
                'email' => 'true',
                'encryptedstring' => 'true',
                'id' => 'true',
                'integer' => 'false',
                'multipicklist' => 'true',
                'percent' => 'false',
                'phone' => 'true',
                'picklist' => 'true',
                'reference' => 'true',
                'string' => 'true',
                'textarea' => 'true',
                'time' => 'false',
                'url' => 'true'
            };
        }
        return isQuoted;
    } set;}

    // Code used by communities and backend
    public static Map<String, String> jsPrimitiveTypeMap {get{
        if (jsPrimitiveTypeMap == null) {
            jsPrimitiveTypeMap = new Map<String,String>{
                'address' => 'string',
                'anytype' => 'object',
                'base64' => 'string',
                'boolean' => 'boolean',
                'combobox' => 'boolean',
                'currency' => 'number',
                'datacategorygroupreference' => 'object',
                'date' => 'string',
                'datetime' => 'string',
                'double' => 'number',
                'email' => 'string',
                'encryptedstring' => 'string',
                'id' => 'string',
                'integer' => 'number',
                'multipicklist' => 'string',
                'percent' => 'number',
                'phone' => 'string',
                'picklist' => 'string',
                'reference' => 'string',
                'string' => 'string',
                'textarea' => 'string',
                'time' => 'number',
                'url' => 'string'
            };
        }
        return jsPrimitiveTypeMap;
    } set; }
/*
    @AuraEnabled
	public static List<Map<String,String>> getRelatedLists(String objectName, String context) {
        List<Map<String,String>> lista = new List<Map<String,String>>();
        Schema.DescribeSObjectResult describeResult = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe();
        List<String> labels = new List<String>();
        Map<String, Schema.ChildRelationship> childRelationshipsMap = new Map<String, Schema.ChildRelationship>();
        Map<String,Boolean> labelsMap = new Map<String,Boolean>();
        for(Schema.ChildRelationship thisChild : describeResult.getChildRelationships()){
            if(thisChild.getRelationshipName() != null){
                String relatedObject = String.valueOf(thisChild.getChildSObject());
                    if( objectName == 'FieloPLT__Member__c' && relatedObject == 'FieloPLT__LevelMember__c'){
                        labels.add( 'Rank Member' );
                    }
                    if( objectName == 'FieloPLT__Member__c' && relatedObject == 'FieloPLT__Member__c' && String.valueOf(thisChild.getField()) == 'FieloPLT__OrganizationAccount__c'){
                        if(context != 'Behavior'){
                            labels.add('Contributor');
                            childRelationshipsMap.put('Contributor', thisChild);
                            continue; //Avoid put the member label in the map below
                        }
                    }else if(objectName == 'FieloPLT__Member__c' && relatedObject == 'FieloPLT__Member__c' && String.valueOf(thisChild.getField()) == 'FieloPLT__MergedTo__c'){
                        //Do nothing, because a Merged or Pending Merge member can't be part of a Segment or be evaluated for the rule engine. So there is no sense to have this option
                        continue;
                    }

                String lab = ((sObject)Type.forName(relatedObject).newInstance()).getSObjectType().getDescribe().getLabel();
                if(!labelsMap.containsKey(lab)){
                    labelsMap.put(lab,true);
                    labels.add( lab );
                }
                childRelationshipsMap.put(((sObject)Type.forName(relatedObject).newInstance()).getSObjectType().getDescribe().getLabel(), thisChild);
            }
        }

        labels.sort();
        for(String s : labels){
            Map<String,String> aux = new Map<String,String>();
            if( s == 'Rank Member' ){
                aux.put('label', s);
                aux.put('name', 'FieloPLT__RankMember__c');
                aux.put('relationshipName', 'FieloPLT__RankMembers__r');
            } else {
                if(childRelationshipsMap.get(s).getRelationshipName() != null){
                    aux.put('label', s);
                    aux.put('name', String.valueOf(childRelationshipsMap.get(s).getChildSObject()));
                    aux.put('relationshipName', String.valueOf(childRelationshipsMap.get(s).getRelationshipName()));
                }
            }
            lista.add( aux );
        }
		return lista;
	}

    @AuraEnabled(cacheable=true)
	public static List<Map<String, String>> getWiredPicklistEntries(String objectName, String fieldName) {
        return getPicklistEntries(objectName, fieldName);
    }

    @AuraEnabled
	public static List<Map<String,String>> getBehaviorObjectList() {
        List<Map<String,String>> lista = new List<Map<String,String>>();
        Set<String> objects = new Set<String>();
        Set<String> referencedObjects = new Set<String>();
        Map<String,String> result;
        Map<String, List<String>> behaviorConfig = getBehaviorConfiguration();
        Set<String> ignoreObjects = new Set<String>();

        if (behaviorConfig != null && behaviorConfig.containsKey('exclude') && !behaviorConfig.get('exclude').isEmpty()) {
            ignoreObjects.addAll(behaviorConfig.get('exclude'));
        }

        for(Schema.SObjectType objType : Schema.getGlobalDescribe().values()) {
            if (!ignoreObjects.contains(objType.getDescribe().getName())) {
                result = new Map<String,String>();
                if (objType.getDescribe().isAccessible() && objType.getDescribe().isCreateable() && objType.getDescribe().isUpdateable()) {
                    if(objType.getDescribe().getName() == 'FieloPLT__LevelMember__c'){
                        result.put('label', 'Rank Member');
                    } else {
                        result.put('label', objType.getDescribe().getLabel());
                    }
                    result.put('name', objType.getDescribe().getName());
                    lista.add(result);
                }
            }
        }

		return lista;
    }

    @AuraEnabled
    public static Map<String, List<String>> getBehaviorConfiguration() {
        Map<String, List<String>> behaviorConfig = new Map<String, List<String>>();

        List<StaticResource> resources = [SELECT Id, body FROM StaticResource WHERE Name = 'behaviorObjects'];
        if (!resources.isEmpty()) {
            behaviorConfig = (Map<String, List<String>>) JSON.deserialize(resources.get(0).body.toString(), Map<String, List<String>>.class);
        }
        return behaviorConfig;
    }

	@AuraEnabled
	public static List<Map<String, String>> getPicklistEntries(String objectName, String fieldName) {
		List<Map<String, String>> values = new List<Map<String, String>>();
		List<Schema.DescribeSobjectResult> results = Schema.describeSObjects(new List<String>{objectName});
		for(Schema.DescribeSobjectResult res : results) {
			for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
				if (entry.isActive()) {
					Map<String,String> aux = new Map<String,String>();
					aux.put('label', entry.getLabel());
					aux.put('value', entry.getValue());
					values.add( aux );
				}
			}
		}
		return values;
	}


    // Code used by backend
    // Moved the cache control to the BeUtils to be able to enable/disable
    // on the client side. Some components need this case.
    @AuraEnabled
    public static List<SObject> getRecords(String fields, String objectName, String dataFilters, String orderBy, String recordsPerPage, String offset) {

        Boolean isRank = false;
        if( objectName == 'FieloPLT__Rank__c' ){
            isRank = true;
            objectName = 'FieloPLT__Level__c';

            Map<String,Object> filter = (Map<String, Object>) JSON.deserializeUntyped(dataFilters);
            if (!filter.containsKey('FieloPLT__Challenge__c') || filter.get('FieloPLT__Challenge__c') == null) {
                filter.put('FieloPLT__Challenge__c', '!null');
            }
            dataFilters = JSON.serialize(filter);
        }else if( objectName == 'FieloPLT__Level__c' ){
            Map<String,Object> filter = (Map<String, Object>) JSON.deserializeUntyped(dataFilters);
            if (!filter.containsKey('FieloPLT__Challenge__c') || filter.get('FieloPLT__Challenge__c') == null) {
                filter.put('FieloPLT__Challenge__c', 'null');
            }
            dataFilters = JSON.serialize(filter);
        }
        Schema.DescribeSObjectResult objectDescribe = Schema.describeSObjects(new List<String>{objectName})[0];
        //Security Check
        if(!objectDescribe.isAccessible()){
            throw new FieloException(String.format(Label.security_error_object_not_readable, new List<String>{objectName}));
        }
        Set<String> picklistTypes = new Set<String>{'PICKLIST','MULTIPICKLIST'};
        List<String> fieldset = new List<String>();

        List<String> listFields = fields != null ? fields.deleteWhitespace().split(',') : new List<String>();
        for( Integer i = 0; i < listFields.size(); i++ ){
            if ( listFields.get(i) == 'RecordType') {
                listFields.remove(i);
                listFields.add('RecordTypeId');
            }
        }
        Map<String,Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        for(String fieldName: listFields){
            Schema.DescribeFieldResult fieldDescribe = fieldMap?.get(fieldName)?.getDescribe();
            if(fieldDescribe?.isAccessible() == false){
                throw new FieloException(String.format(Label.security_error_field_not_readable, new List<String>{objectName, fieldName}));
            }
            else if (fieldDescribe != null) {
                if(fieldMap.containskey(fieldName) && picklistTypes.contains(fieldDescribe.getType().name())){
                    fieldset.add('toLabel(' + fieldName + ') '+fieldName.toLowerCase()+'_label');
                } else if(fieldMap.containskey(fieldName) && fieldDescribe?.getType().name().tolowercase() == 'REFERENCE') {
                    Schema.DescribeFieldResult dfr = fieldDescribe;
                    String relatedObjNameField = getNameField( dfr.getReferenceTo()[0].getDescribe() );
                    if (String.isNotBlank(relatedObjNameField)) {
                        fieldset.add(dfr.getRelationshipName() + '.' + relatedObjNameField );
                    }
                }
            }
            fieldset.add(fieldName);
        }

        return new SObjectsSelector().queryPickListRecords(new List<String>(new Set<String>(fieldset)), fields, objectName, dataFilters, orderBy, recordsPerPage, offset);
    }

    // Code used by backend
    // Moved the cache control to the BeUtils to be able to enable/disable
    // on the client side. Some components need this case.
    @AuraEnabled
    public static List<SObject> getRecordById(String fields, List<String> ids) {
        if (ids.isEmpty() || ids.get(0) == null) {
            throw new FieloException('Ids parameter cannot be null');
        }

        Schema.DescribeSObjectResult objectDescribe = Id.valueOf(ids.get(0)).getSObjectType().getDescribe();

        Set<String> picklistTypes = new Set<String>{'PICKLIST','MULTIPICKLIST'};
        List<String> fieldset = new List<String>();

        List<String> listFields = fields != null ? fields.deleteWhitespace().split(',') : new List<String>{'Id'};
        for( Integer i = 0; i < listFields.size(); i++ ){
            if ( listFields.get(i) == 'RecordType') {
                listFields.remove(i);
                listFields.add('RecordTypeId');
            }
        }

        for(String fieldName: listFields){
            if(objectDescribe.fields.getMap().containskey(fieldName) && picklistTypes.contains(objectDescribe.fields.getMap().get(fieldName).getDescribe().getType().name())){
                fieldset.add('toLabel(' + fieldName + ') '+fieldName.toLowerCase()+'_label');
            } else if(objectDescribe.fields.getMap().containskey(fieldName) && objectDescribe.fields.getMap().get(fieldName).getDescribe().getType().name().tolowercase() == 'REFERENCE') {
                Schema.DescribeFieldResult dfr = objectDescribe.fields.getMap().get(fieldName).getDescribe();
                String relatedObjNameField = getNameField( dfr.getReferenceTo()[0].getDescribe() );
                if (String.isNotBlank(relatedObjNameField)) {
                    fieldset.add(dfr.getRelationshipName() + '.' + relatedObjNameField );
                }
            }
            fieldset.add(fieldName);
        }

        String query = String.format('SELECT {0} FROM {1} WHERE Id IN :ids',new List<String>{String.join(listFields, ','),objectDescribe.getName()});

        return Database.query(query);
    }

    // Code used by backend
    // LwcVersion to use with wire
    @AuraEnabled(cacheable=true)
    public static List<SObject> getWiredRecords(String fields, String objectName, String dataFilters, String orderBy, String recordsPerPage, String offset) {
        return getRecords(fields, objectName, dataFilters, orderBy, recordsPerPage, offset);
    }

    @AuraEnabled(cacheable=true)
    public static List<Map<String,String>> getWiredProgramPoints(String programId) {
        return getPointTypes(programId);
    }

    // Code used by backend
    // LwcVersion to use with wire
    @AuraEnabled(cacheable=true)
    public static Object getWiredRecordsWithCounter(String fields, String objectName, String dataFilters, String orderBy, String recordsPerPage, String offset) {
        return getRecordsWithCounter(fields, objectName, dataFilters, orderBy, recordsPerPage, offset);
    }

    // Code used by backend
    @AuraEnabled
    public static Object getRecordsWithCounter(String fields, String objectName, String dataFilters, String orderBy, String recordsPerPage, String offset) {
        Schema.DescribeSObjectResult objectDescribe = Schema.describeSObjects(new List<String>{objectName})[0];
        if(!objectDescribe.isAccessible()){
            throw new FieloException(String.format(Label.security_error_object_not_readable, new List<String>{objectName}));
        }
        Set<String> picklistTypes = new Set<String>{'PICKLIST','MULTIPICKLIST'};
        List<String> fieldset = new List<String>();

        List<String> listFields = fields != null ? fields.deleteWhitespace().split(',') : new List<String>();
        for(String fieldName: listFields){
            if(objectDescribe.fields.getMap().containskey(fieldName) && picklistTypes.contains(objectDescribe.fields.getMap().get(fieldName).getDescribe().getType().name())){
                fieldset.add('toLabel(' + fieldName + ') '+fieldName.toLowerCase()+'_label');
            } else if(objectDescribe.fields.getMap().containskey(fieldName) && objectDescribe.fields.getMap().get(fieldName).getDescribe().getType().name().tolowercase() == 'REFERENCE') {
                Schema.DescribeFieldResult dfr = objectDescribe.fields.getMap().get(fieldName).getDescribe();
                String relatedObjNameField = getNameField( dfr.getReferenceTo()[0].getDescribe() );
                if (String.isNotBlank(relatedObjNameField)) {
                    fieldset.add(dfr.getRelationshipName() + '.' + relatedObjNameField );
                }
            }
            fieldset.add(fieldName);
        }

        return new SObjectsSelector().queryRecordsWithCounter(fieldset, fields, objectName, dataFilters, orderBy, recordsPerPage, offset);
    }
    // Code used by backend
    @AuraEnabled
    public static List<SObject> getRecordsWithRelated(String fields, String objectName, Map<String, List<String>> fieldsByRelationShipName, String dataFilters, Map<String, String> dataFiltersByRelationshipName, String orderBy, String recordsPerPage, String offset) {
        try{
            Schema.DescribeSObjectResult objectDescribe = SObjectDescribe.getDescribe(objectName).getDescribe(); // Cached like describe

            Set<String> picklistTypes = new Set<String>{'PICKLIST','MULTIPICKLIST'};
            List<String> fieldset = new List<String>();
            List<String> relatedFieldset = new List<String>();

            List<String> listFields = String.isNotBlank(fields) && String.isNotBlank(fields.deleteWhitespace()) && fields.contains(',') ?
                fields.deleteWhitespace().split(',') :
                (String.isNotBlank(fields) && String.isNotBlank(fields.deleteWhitespace()) ? new List<String>{fields} : new List<String>{'Id'});

            for(String fieldName: listFields){
                if(objectDescribe.fields.getMap().containskey(fieldName) && picklistTypes.contains(objectDescribe.fields.getMap().get(fieldName).getDescribe().getType().name())){
                    fieldset.add('toLabel(' + fieldName + ') '+fieldName.toLowerCase()+'_label');
                } else if(objectDescribe.fields.getMap().containskey(fieldName) && objectDescribe.fields.getMap().get(fieldName).getDescribe().getType().name().tolowercase() == 'REFERENCE') {
                    Schema.DescribeFieldResult dfr = objectDescribe.fields.getMap().get(fieldName).getDescribe();
                    String relatedObjNameField = getNameField( dfr.getReferenceTo()[0].getDescribe() );
                    if (String.isNotBlank(relatedObjNameField)) {
                        fieldset.add(dfr.getRelationshipName() + '.' + relatedObjNameField );
                    }
                }
                fieldset.add(fieldName);
            }

            // FOR CHILD RELATIONSHIPS
            List<ChildRelationship> childRels = objectDescribe.getChildRelationships();
            Schema.DescribeSObjectResult childObjectDescribe;
            Map<String, List<String>> safeFieldsByRelationShipName = new Map<String, List<String>>();
            for (String relationShipName : fieldsByRelationShipName.keySet()) {
                for (ChildRelationship cr : childRels) {
                    if (cr.getRelationshipName() != null ) {
                        if (cr.getRelationshipName().toLowerCase() == relationshipName.toLowerCase()) {
                            childObjectDescribe = cr.getChildSObject().getDescribe();
                            safeFieldsByRelationShipName.put(relationShipName, new List<String>());
                            break;
                        }
                    }
                }
                List<String> fieldPath;
                Boolean hasAccess = true;
                String currentField;
                if (childObjectDescribe != null) {
                    if (!fieldsByRelationShipName.containsKey(relationShipName) || fieldsByRelationShipName.get(relationShipName).isEmpty()) {
                        safeFieldsByRelationShipName.get(relationShipName).addAll(childObjectDescribe.fields.getMap().keySet());
                    } else {
                        for(String fieldName : new Set<String>(fieldsByRelationShipName.get(relationShipName))) {
                            if( String.isNotBlank(fieldName) && canAccess(childObjectDescribe, fieldName) ) {
                                safeFieldsByRelationShipName.get(relationShipName).add(fieldName);
                            }
                        }
                    }
                } else {
                    throw new FieloException(String.format(Label.QueryErrorInvalidCall, new List<String>{relationshipName, objectName}));
                }
            }
            return new SObjectsSelector().querySObjectWithRelated(fieldset, objectName, safeFieldsByRelationShipName, dataFilters, dataFiltersByRelationshipName, orderBy, recordsPerPage, offset);
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Code used by backend
    @AuraEnabled
    public static Integer countRecords( String objectName, String dataFilters ) {
        return new SObjectsSelector().queryCountRecords(objectName, dataFilters);
    }

    // Code used by backend
    @AuraEnabled
    public static Integer countPayoutRecords(String dataFilters) {
        return new SObjectsSelector().countPayoutRecords(dataFilters);
    }

    // Code used by backend
    @AuraEnabled
    public static String getComponentConfig(String staticResourceName) {
        String result = '[';

        String resourceNames = '%' + staticResourceName + '_extended%';

        for(StaticResource sr : [SELECT Id, body FROM StaticResource WHERE Name =: staticResourceName OR Name Like: resourceNames]){
            for(Object o: (List<Object>) JSON.deserializeUntyped(sr.body.toString())) {
                result += JSON.serialize(o) + ',';
            }
        }

        result = result.removeEnd(',');
        result += ']';
        return result;
    }

    // Code use by backend
    @AuraEnabled
    public static String getIconName(String sObjectName){
        String u ='';
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

        for(Schema.DescribeTabSetResult tsr : tabSetDesc) {
            tabDesc.addAll(tsr.getTabs());
        }


        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sObjectName == tr.getSobjectName() ) {
                if( tr.isCustom() == true ) {
                    iconDesc.addAll(tr.getIcons());
                }
                else {
                    u = 'standard:' + sObjectName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                u = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
        return u;
    }

    // Code used by backend
	@AuraEnabled
	public static String saveRecord(sObject record, List<Criterion__c> criterias, List<Id> segmentIds, List<Map<String, Object>> criterionGroups) {
        //Exceptions
		List<Schema.SObjectType> objectType = new List<Schema.SObjectType>();
        Set<String> objectTypes = new Set<String>();
		if( record == null ){
			throw new FieloException('Record: invalid parameter.');
		} else {
			objectType.add( record.getSobjectType() );

            //If record is a Segment
            if( segmentIds != null && !segmentIds.isEmpty() && record.getSobjectType().getDescribe().getName() != Segment__c.SObjectType.getDescribe().getName() ){
			    objectType.add( Segment__c.SObjectType );
            }
		}
		Savepoint sp = Database.setSavepoint();
		SObjectUnitOfWork uow = new SObjectUnitOfWork(objectType);
		String result = null;
		try {
			//Add Record to uow
			if( record.Id == null ){
				uow.registerNew(record);
			} else {
				uow.registerDirty(record);
			}

            //Set the Segment
			if( segmentIds != null && !segmentIds.isEmpty() ){
				//Search the Lookup to Segment
				Schema.SObjectField lookupFieldObjSegment;
				for( Schema.SObjectField fieldType : record.getSObjectType().getDescribe().fields.getMap().values() ){
					if( fieldType.getDescribe().getType().name() == 'REFERENCE' && fieldType.getDescribe().getReferenceTo()[0].getDescribe().getName() == 'FieloPLT__Segment__c') {
						lookupFieldObjSegment = fieldType;
						break;
					}
				}
				if( lookupFieldObjSegment == null ){
					throw new AuraHandledException('Error');
				}

				Id segmentId = SegmentService.getMetasegmentId(new Set<Id>(segmentIds));
				uow.registerRelationship(record, lookupFieldObjSegment, new Segment__c(Id = segmentId));
			}

			// Security Review
			if( !record.getSobjectType().getDescribe().isCreateable() || !record.getSobjectType().getDescribe().isUpdateable() ){
				throw new FieloException(String.format(Label.security_error_object_not_insertable, new List<String>{record.getSObjectType().getDescribe().name}));
			}else{
				Map<String, Object> fieldsToVerify = record.getPopulatedFieldsAsMap();
				Map<String, SObjectField> fieldsMapByName = record.getSobjectType().getDescribe().fields.getMap();
				for (String fieldName : fieldsToVerify.keySet()){
					if(fieldsMapByName.containsKey(fieldName.toLowerCase())){
						SObjectField desiredSobjField = fieldsMapByName.get(fieldName.toLowerCase());
						if(fieldName != 'Id' &&  desiredSobjField != null && !desiredSobjField.getDescribe().isCreateable() && !desiredSobjField.getDescribe().isUpdateable()){
							throw new FieloException(String.format(Label.security_error_field_not_insertable, new List<String>{record.getSObjectType().getDescribe().getName(),fieldName}));
						}
					}
				}
            }
            if( record.getSobjectType().getDescribe().getName() == 'FieloPLT__Model__c' ){
                validateModel(record);
            }
			//Update
            //Criteria.validateAdminFields = false;
			uow.commitWork();
            //Criteria.validateAdminFields = true;
			result = record.Id;
        } catch (DmlException e) {
            system.debug(e.getDMLMessage(0));
            Database.rollback(sp);
            if( Test.isRunningTest() ){
                throw new FieloException(e.getDMLMessage(0));
            }
            throw new AuraHandledException(e.getDMLMessage(0));
        } catch(Exception e){
            system.debug(e.getMessage());
            Database.rollback(sp);
            if( Test.isRunningTest() ){
                throw new FieloException(e.getMessage());
            }
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    // Code used by backend
	@AuraEnabled
	public static String saveRecordWithCriterias(sObject record, List<Criterion__c> criterias, List<Id> segmentIds, List<Map<String, Object>> criterionGroups) {
        //Exceptions
		List<Schema.SObjectType> objectType = new List<Schema.SObjectType>();
        Set<String> objectTypes = new Set<String>();
		if( record == null ){
			throw new FieloException('Record: invalid parameter.');
		} else {
			objectType.add( record.getSobjectType() );

            //If record is a Segment
            if( segmentIds != null && !segmentIds.isEmpty() && record.getSobjectType().getDescribe().getName() != Segment__c.SObjectType.getDescribe().getName() ){
			    objectType.add( Segment__c.SObjectType );
            }

            //For criterion group and criterias
            objectType.addAll( new List<Schema.SObjectType>{CriterionGroup__c.SObjectType, Criterion__c.SObjectType} );
		}
		Savepoint sp = Database.setSavepoint();
		SObjectUnitOfWork uow = new SObjectUnitOfWork(objectType);
		String result = null;
		try {
			//Add Record to uow
			if( record.Id == null ){
				uow.registerNew(record);
			} else {
				uow.registerDirty(record);
			}
			// Get Lookup field
    		Schema.SObjectField lookupFieldObjCriteria = getLookupFieldFromChild(record, 'FieloPLT__Criterion__c');
			//Set Criterias
            Set<Id> criteriaIds = new Set<Id>();
			if( criterias != null && !criterias.isEmpty() ){
				//If does not have Criteria lookup field
				if( lookupFieldObjCriteria == null ){
					throw new AuraHandledException('Record: invalid parameter.');
				} else {
					//Add of criteria
					for(Criterion__c c : criterias) {
						if( c.Id != null ){
							uow.registerDirty(c);
							criteriaIds.add(c.Id);
						} else {
							uow.registerNew(c, lookupFieldObjCriteria, record);
						}
					}
				}
			}

			//If it is edit record, check if other criterias should be deleted
			if( criterias != null && lookupFieldObjCriteria != null && record.Id != null ){
                String recordId = String.valueOf(record.Id);
				String query = 'SELECT Id FROM Criterion__c WHERE ' + String.valueOf(lookupFieldObjCriteria) + ' =: recordId';
                if( criteriaIds.size() > 0 ){
                    query += ' AND Id not In: criteriaIds';
                }
                List<Criterion__c> toDelete = (List<Criterion__c>)Database.query(query);
                if( !toDelete.isEmpty() ){
                    uow.registerDeleted(toDelete);
                }
			}

			//Set the Segment
			if( segmentIds != null && !segmentIds.isEmpty() ){
				//Search the Lookup to Segment
				Schema.SObjectField lookupFieldObjSegment;
				for( Schema.SObjectField fieldType : record.getSObjectType().getDescribe().fields.getMap().values() ){
					if( fieldType.getDescribe().getType().name() == 'REFERENCE' && fieldType.getDescribe().getReferenceTo()[0].getDescribe().getName() == 'FieloPLT__Segment__c') {
						lookupFieldObjSegment = fieldType;
						break;
					}
				}
				if( lookupFieldObjSegment == null ){
					throw new AuraHandledException('Error');
				}

				Id segmentId = SegmentService.getMetasegmentId(new Set<Id>(segmentIds));
				uow.registerRelationship(record, lookupFieldObjSegment, new Segment__c(Id = segmentId));
			}

			//Set Criterion Group
            Schema.SObjectField lookupCriterionGroup = getLookupFieldFromChild(record, 'FieloPLT__CriterionGroup__c');
            Set<Id> criterionGroupIds = new Set<Id>();
            Set<Id> criterionGroupCriteriasIds = new Set<Id>();

			if( criterionGroups != null && !criterionGroups.isEmpty() ){
				Map<String, Schema.SObjectField> criteriaFieldsMap = Schema.SObjectType.Criterion__c.fields.getMap();
				Map<String, Schema.SObjectField> criteriaGroupFieldsMap = Schema.SObjectType.CriterionGroup__c.fields.getMap();

				for(Integer i = 0; i < criterionGroups.size(); i++){
                    Boolean isRank = false;
					CriterionGroup__c cg = new CriterionGroup__c();
					for(String cgKey : criterionGroups.get(i).keySet()){
						if(cgKey == 'FieloPLT__Criteria__r'){
							List<Object> elements = (List<Object>)criterionGroups.get(i).get('FieloPLT__Criteria__r');
							for(Object o : elements){
								Criterion__c crit = new Criterion__c();
								Map<Object,Object> mapa = (Map<Object,Object>)o;
								for(Object apiName : mapa.keySet()){
									String campo = String.valueOf(apiName);
									String tipo = String.valueOf(criteriaFieldsMap.get(campo).getDescribe().getType());
									if( tipo == 'Date' ){
                                        String fecha = String.valueOf(mapa.get(campo)).replace('T', ' ');
                                        try{
                                            Datetime dt1 = Datetime.valueOfGmt(fecha);
										    crit.put(campo, Date.newinstance(dt1.year(), dt1.month(), dt1.day()));
                                        } catch(Exception e){
                                            Date dt1 = Date.valueOf(fecha);
										    crit.put(campo, dt1);
                                        }
									} else if( tipo == 'Boolean' ){
										crit.put(campo, Boolean.valueOf(mapa.get(campo)));
									} else if( tipo == 'Double' || tipo == 'Decimal' ){
										String valor = String.valueOf(mapa.get(campo));
										crit.put(campo, Decimal.valueOf(valor));
									} else {
                                        String valor = String.valueOf(mapa.get(campo));
                                        if( campo == 'FieloPLT__FieldName__c' ){
                                            valor = valor.replace('Rank', 'Level');
                                        }
										crit.put(campo, valor);
									}
								}
                                if( crit.Id == null ){
								    uow.registerNew(crit, Criterion__c.CriterionGroup__c, cg);
                                } else {
								    uow.registerDirty(crit);
                                    criterionGroupCriteriasIds.add(crit.Id);
                                }
							}
						} else {
                            if( cgKey == 'Id' && criterionGroups.get(i).get(cgKey) != '' ){
                                cg.put(cgKey, String.valueOf(criterionGroups.get(i).get(cgKey)));
                            } else if( String.valueOf(criteriaGroupFieldsMap.get(cgKey).getDescribe().getType()) == 'Decimal' || String.valueOf(criteriaGroupFieldsMap.get(cgKey).getDescribe().getType()) == 'DOUBLE' ){
                                if( criterionGroups.get(i).get(cgKey) != '' && criterionGroups.get(i).get(cgKey) != null ){
                                    String valor = String.valueOf(criterionGroups.get(i).get(cgKey));
                                    cg.put(cgKey, Decimal.valueOf(valor));
                                } else {
                                    cg.put(cgKey, null);
                                }
                            } else {
                                if( criterionGroups.get(i).get(cgKey) != null ){
                                    String valor = String.valueOf(criterionGroups.get(i).get(cgKey));
                                    if( valor.contains('Rank') ){
                                        isRank = true;
                                    }
                                    valor = valor.replace('Rank', 'Levels');
                                    cg.put(cgKey, valor);
                                } else {
                                    cg.put(cgKey, null);
                                }
                            }
						}
					}
                    if( isRank ){
                        cg.Type__c = 'Rank';
                    }
                    if( cg.Id == null ){
    					uow.registerNew(cg, lookupCriterionGroup, record);
                    } else {
					    uow.registerDirty(cg);
                        criterionGroupIds.add(cg.Id);
                    }
				}
			}
            //If it is edit record, check if other criterias should be deleted
			if( criterionGroups != null && lookupCriterionGroup != null && record.Id != null ){
                String recordId = String.valueOf(record.Id);
				String query = 'SELECT Id FROM CriterionGroup__c WHERE ' + String.valueOf(lookupCriterionGroup) + ' =: recordId';
                if( criterionGroupIds.size() > 0 ){
                    query += ' AND Id not In: criterionGroupIds';
                }
                List<CriterionGroup__c> toDelete = (List<CriterionGroup__c>)Database.query(query);
                if( !toDelete.isEmpty() ){
                    uow.registerDeleted(toDelete);
                }

                if( criterionGroupIds.size() > 0 && criterionGroupCriteriasIds.size() > 0 ){
                    //For criterias related to CriterionGroup check if there are some to be deleted
				    String queryCriterion = 'SELECT Id FROM Criterion__c WHERE CriterionGroup__c In: criterionGroupIds AND Id not In: criterionGroupCriteriasIds';
                    List<Criterion__c> toDeleteCriterion = (List<Criterion__c>)Database.query(queryCriterion);
                    if( !toDeleteCriterion.isEmpty() ){
                        uow.registerDeleted(toDeleteCriterion);
                    }
                }

			}

			// Security Review
			if( !record.getSobjectType().getDescribe().isCreateable() || !record.getSobjectType().getDescribe().isUpdateable() ){
				throw new FieloException(String.format(Label.security_error_object_not_insertable, new List<String>{record.getSObjectType().getDescribe().name}));
			}else{
				Map<String, Object> fieldsToVerify = record.getPopulatedFieldsAsMap();
				Map<String, SObjectField> fieldsMapByName = record.getSobjectType().getDescribe().fields.getMap();
				for (String fieldName : fieldsToVerify.keySet()){
					if(fieldsMapByName.containsKey(fieldName.toLowerCase())){
						SObjectField desiredSobjField = fieldsMapByName.get(fieldName.toLowerCase());
						if(fieldName != 'Id' &&  desiredSobjField != null && !desiredSobjField.getDescribe().isCreateable() && !desiredSobjField.getDescribe().isUpdateable()){
							throw new FieloException(String.format(Label.security_error_field_not_insertable, new List<String>{record.getSObjectType().getDescribe().getName(),fieldName}));
						}
					}
				}
			}
            if( record.getSobjectType().getDescribe().getName() == 'FieloPLT__Model__c' ){
                validateModel(record);
            }
			//Update
            Criteria.validateAdminFields = false;
			uow.commitWork();
            Criteria.validateAdminFields = true;
			result = record.Id;
        } catch (DmlException e) {
            system.debug(e.getDMLMessage(0));
            system.debug(e.getStackTraceString());
            Database.rollback(sp);
            if( Test.isRunningTest() ){
                throw new FieloException(e.getDMLMessage(0));
            }
            throw new AuraHandledException(e.getDMLMessage(0));
        } catch(Exception e){
            system.debug(e.getMessage());
            Database.rollback(sp);
            if( Test.isRunningTest() ){
                throw new FieloException(e.getMessage());
            }
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    private static void validateModel(sObject record){
        //If it is a model, check if its name is unique
        String name = String.valueOf(record.get('Name')).normalizeSpace();
        String query = 'SELECT Name FROM Model__c WHERE Name=:name';
        List<Model__c> models = (List<Model__c>)Database.query(query);
        if( !models.isEmpty() ){
            throw new FieloException(label.ModelWithSameName);
        }
    }

    @TestVisible
	private static Schema.SObjectField getLookupFieldFromChild(sObject record, String objectName){
		Schema.SObjectField relatedToParentField = null;

		List<Schema.ChildRelationship> childRels = record.getSobjectType().getDescribe().getChildRelationships();
		for(Schema.ChildRelationship childRel : childRels){
			if( childRel.getChildSObject().getDescribe().getName() == objectName ){
				relatedToParentField = childRel.getField();
				break;
			}
		}
		return relatedToParentField;
	}

    public static Schema.SObjectField getLookupField(sObject objectSon, String apiNameObjectFather){
        Schema.SObjectField lookupField;
        for( Schema.SObjectField fieldObj : objectSon.getSObjectType().getDescribe().fields.getMap().values() ){
            if( fieldObj.getDescribe().getType().name() == 'REFERENCE' && fieldObj.getDescribe().getReferenceTo()[0].getDescribe().getName() == apiNameObjectFather) {
                lookupField = fieldObj;
                break;
            }
        }
        return lookupField;
    }

	@AuraEnabled
	// Code used by backend
	public static List<SObject> getListViews(String sObjectName, String listDeveloperName) {
  		return new SObjectsSelector().queryListViews(sObjectName, listDeveloperName);
    }

    @AuraEnabled
	// Code used by backend
	public static List<String> setCapStatus(Id recordId) {
        List<string> result = new List<string>();
        try{
            Cap__c record = (new CapsSelector(new Set<String>{'FieloPLT__Status__c','FieloPLT__CappingSummary__c','FieloPLT__ScopeOfApplication__c'}).selectById(new Set<Id>{recordId}))[0];
            String status = record.Status__c == 'Active' ? 'Inactive' : 'Active';
            SObjectUnitOfWork uow = new SObjectUnitOfWork( new List<Schema.SObjectType>{Cap__c.SObjectType});

            uow.registerDirty(new Cap__c(Id=recordId, Status__c = status));
            uow.commitWork();
            result.add(record.Id);
            result.add(status);
        }catch(DMLException e){
            throw new AuraHandledException(e.getDMLMessage(0));
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
  		return result;
    }

    @TestVisible
    private static Schema.SObjectField getLookupFieldObjCriteria(sObject record){
        Schema.SObjectField relatedToParentField = null;

        List<Schema.ChildRelationship> childRels = record.getSobjectType().getDescribe().getChildRelationships();
        for(Schema.ChildRelationship childRel : childRels){
            if( childRel.getChildSObject().getDescribe().getName() == 'FieloPLT__Criterion__c' ){
                relatedToParentField = childRel.getField();
                break;
            }
        }
        return relatedToParentField;
    }

    // Code use by backend
    @AuraEnabled
    public static String getRecordObject(String recordId){
        //get sobjecttype by sobject prefix (3 chars)
        try{
            DescribeSObjectResult objectDescribe = ((Id)recordId).getSObjectType().getDescribe();
            String keyPrefix = (String) objectDescribe.getKeyPrefix();
            if( keyPrefix != null && keyPrefix.equals(recordId.substring(0,3)) ){
                return objectDescribe.getName();
            }
        } catch( Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return '';
    }

    //Duvida
    // Code used by backend
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getPrograms() {
        List<Map<String, String>> programsMap = new List<Map<String, String>>();
        for( SelectOption s : ProgramService.getProgramsLandingSelectOptions() ){
            programsMap.add( new Map<String, String>{'label' => s.getLabel(), 'value' => s.getValue()} );
        }
        return programsMap;
    }

    // Code used by backend lightning
    @AuraEnabled
    public static Program__c getActiveProgram (){
        return ProgramService.getActiveProgram();
    }

    // Code used by backend lightning
    @AuraEnabled
    public static void setProgram(Id programId){
        if (String.isNotBlank(programId)) {
            try{
                if ( programId != ProgramService.getActiveProgram().Id ) {
                    ProgramService.selectProgram(programId);
                }
            } catch(DmlException e){
            }
        }
    }
*/
    public static string getNameField(Schema.DescribeSObjectResult dsr) {
        if (dsr != null) {
            for(Schema.SObjectField field : dsr.fields.getMap().values()) {
                if (field.getDescribe().isNameField()) {
                    return field.getDescribe().getName();
                }
            }
        }
        return null;
    }
    /*
    // Code used by backend lightning
	// Return list of filers based on the Members
	@AuraEnabled
	public static List<Map<String, String>> getMemberTypes() {
		List<Map<String, String>> allTypes = new List<Map<String, String>>();
		Set<String> added = new Set<String>();
		Schema.DescribeSObjectResult objectDescribe = ((sObject)Type.forName('FieloPLT__Member__c').newInstance()).getSObjectType().getDescribe();
        if( objectDescribe.fields.getMap().containskey('FieloPLT__Type__c')) {
            for( Schema.PicklistEntry entry : objectDescribe.fields.getMap().get('FieloPLT__Type__c').getDescribe().getPicklistValues() ){
                if( entry.isActive() && !added.contains( entry.getValue() )){
                    added.add( entry.getValue() );
                    allTypes.add( new map<String, String>{'value' => entry.getValue(), 'label' => entry.getLabel()} );
                }
            }
        }

		return allTypes;
	}

	// Code used by backend lightning
	@AuraEnabled
    public static string getOrgDomainUrl(){
        try {
            return System.Url.getOrgDomainUrl().toExternalForm();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Code used by backend lightning
    @AuraEnabled
    public static string getFileUrl(String fileId){
        if( String.isBlank(fileId) ){
            throw new AuraHandledException(Label.InvalidValue);
        }

        List<ContentVersion> cv = [SELECT Id FROM ContentVersion WHERE ContentDocumentId =: fileId];
        if( cv.isEmpty() ){
            throw new AuraHandledException('There are no files');
        }

        ContentDistribution cd = new ContentDistribution();
        cd.Name = 'Fielo-Public-URL-' + fileId;
        cd.ContentVersionId = cv.get(0).Id;
        cd.PreferencesAllowViewInBrowser = true;
        cd.PreferencesLinkLatestVersion = true;
        cd.PreferencesNotifyOnVisit = false;
        cd.PreferencesPasswordRequired = false;
        cd.PreferencesAllowOriginalDownload = true;
        insert cd;

        String externalURL = '';
        if (!Test.isRunningTest()) {
            List<ContentDistribution> cds = [SELECT ContentDownloadUrl, DistributionPublicUrl FROM ContentDistribution WHERE Id =: cd.Id limit 1];
            if (!cds.isEmpty()) {
                cd = cds.get(0);
                externalURL = cd.ContentDownloadUrl;
                externalURL = externalURL.replace('download', 'renditionDownload');
                externalURL = externalURL.replace('ids', 'versionId');
                externalURL = externalURL.replace('&asPdf=false', '');
                externalURL = externalURL.replace('%2F', '/');
                externalURL += '&rendition=ORIGINAL_Jpg';
            }
        }
        return externalURL;
    }

    // Code used by backend lightning
    @AuraEnabled(cacheable=true)
    public static String getUserTimeZone(){
        return  String.valueOf(UserInfo.getTimeZone().getID());
    }

    // Code used by backend lightning
    @AuraEnabled
    public static List<Map<String,String>> getPointTypes(String programId){
        if( String.isBlank(programId) ){
            throw new AuraHandledException(Label.InvalidValue);
        }

        List<Map<String,String>> result = new List<Map<String,String>>();
        for(ProgramPointType__c ppt : new ProgramPointTypesSelector().selectByProgram(new Set<Id>{programId})){
            //Set Map to return PointType
            Map<String, String> fields = new Map<String, String>{
                'Id' => ppt.PointType__c,
                'Name' => ppt.PointType__r.Name,
                'programPointTypeId' => ppt.Id,
                'pptExpirationMode' => ppt.ExpirationMode__c,
                'convertionMode' => ppt.PointType__r.ConversionModeField__c, // legacy
                'conversionMode' => ppt.PointType__r.ConversionModeField__c,
                'convertionValue' => ppt.PointType__r.ConversionValueField__c, // legacy
                'conversionValue' => ppt.PointType__r.ConversionValueField__c,
                'recordFieldName' => ppt.PointType__r.RecordFieldNameField__c,
                'expirationMode' => ppt.PointType__r.PointExpirationModeField__c,
                'monthsUntilExpiration' => ppt.PointType__r.MonthsUntilExpirationField__c,
                'expirationDate' => ppt.PointType__r.PointExpirationDateField__c,
                'recurrentDate' => ppt.PointType__r.PointReflectionField__c,
                'memberBalanceField' => ppt.PointType__r.FieloPLT__MemberBalanceField__c,
                'redemptionBalanceField' => ppt.PointType__r.FieloPLT__RedemptionBalanceField__c,
                'redemptionItemBalanceField' => ppt.PointType__r.FieloPLT__RedemptionItemBalanceField__c,
                'rewardBalanceField' => ppt.PointType__r.FieloPLT__RewardBalanceField__c,
                'transactionBalanceField' => ppt.PointType__r.FieloPLT__TransactionBalanceField__c,
                'generatePayout' => String.valueOf(ppt.PointType__r.FieloPLT__GeneratePayout__c)
            };

            //Check if there is default expiration set on ProgramPointType
            if( ppt.DefaultExpirationMode__c != null ){
                fields.put('defaultExpirationMode', ppt.DefaultExpirationMode__c);
                if( ppt.DefaultExpirationMode__c == 'Days' || ppt.DefaultExpirationMode__c == 'Months' ){
                    fields.put('defaultExpirationValue', String.valueOf(ppt.DefaultExpirationValue__c));
                } else if( ppt.DefaultExpirationMode__c == 'Recurrent Date' ){
                    String fechaString = ppt.DefaultExpirationDate__c;
                    List<String> recurrenceDate = fechaString.split('/');
                    Integer day = Integer.valueOf(recurrenceDate.get(0));
                    Integer month = Integer.valueOf(recurrenceDate.get(1));
                    fields.put('defaultExpirationDate', String.valueOf(day+'/'+month));
                }
            }
            result.add(fields);
        }
        return result;
    }

    // Code used by backend lightning
    @AuraEnabled
    public static Map<String, List<Map<String, String>>> getRelatedFields(String objectName){
        try{
            List<String> objectNames = objectName.split('-');
            Schema.DescribeSObjectResult objectDescribe = ((sObject)Type.forName(objectNames.get(0)).newInstance()).getSObjectType().getDescribe();
            Map<String, List<Map<String, String>>> relatedFieldsMap = new Map<String, List<Map<String, String>>>();

            List<Map<String,String>> numericFields = new List<Map<String,String>>();
            List<Map<String,String>> rewardRelatedFields = new List<Map<String,String>>();
            List<Map<String,String>> badgeRelatedFields = new List<Map<String,String>>();
            Map<String,String> lookupFields = new Map<String,String>();

            for(Schema.SObjectField field : objectDescribe.fields.getMap().values()){
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                if( SobjectService.getType(fieldDescribe.getType().name()) == 'Number'){
                    numericFields.add( new Map<String,String>{'label' => fieldDescribe.getLabel(), 'value' => fieldDescribe.getName()} );
                }else if( fieldDescribe.getType().name() == 'REFERENCE' ){
                    if(String.ValueOf(fieldDescribe.getReferenceTo()) == '(FieloPLT__Reward__c)'){
                        rewardRelatedFields.add( new Map<String,String>{'label' => fieldDescribe.getLabel(), 'value' => fieldDescribe.getName()} );
                    }else if( String.ValueOf(fieldDescribe.getReferenceTo()) == '(FieloPLT__Badge__c)' ){
                        badgeRelatedFields.add( new Map<String,String>{'label' => fieldDescribe.getLabel(), 'value' => fieldDescribe.getName()} );
                    }else{
                        lookupFields.put(fieldDescribe.getName(),fieldDescribe.getLabel());
                    }
                }
            }

            if(!lookupFields.isEmpty()){
                //Verify if some Lookup field of the action object have relation with badge or reward to add in the options
                for(Schema.DescribeSobjectResult objectDescribe1: FieloPLT.SObjectDescribe.describeSObjects(new List<String>{'FieloPLT__Badge__c','FieloPLT__Reward__c'})){
                    for(Schema.ChildRelationship childRel : objectDescribe1.getChildRelationships()){
                        String childObject = childRel.getChildSObject().getDescribe().getName();
                        if( lookupFields.containsKey(childObject)){
                            String label = lookupFields.get(childObject) + ' > ' + childRel.getField().getDescribe().getLabel();
                            String replaced = childObject.replace('__c', '__r.');
                            String value = replaced + childRel.getField().getDescribe().getName();
                            if(objectDescribe1.getName() == 'FieloPLT__Badge__c'){
                                badgeRelatedFields.add( new Map<String,String>{'label' => label, 'value' => value} );
                            }else if(objectDescribe1.getName() == 'FieloPLT__Reward__c'){
                                rewardRelatedFields.add( new Map<String,String>{'label' => label, 'value' => value} );
                            }
                        }
                    }
                }
            }

            relatedFieldsMap.put('recordFieldNameOptions', numericFields);
            relatedFieldsMap.put('instantRewardsFieldsOptions', rewardRelatedFields);
            relatedFieldsMap.put('instantBadgeFieldsOptions', badgeRelatedFields);

            // get member fields that are numeric
            List<Map<String,String>> memberNumericFields = new List<Map<String,String>>();
            objectDescribe = ((sObject)Type.forName('FieloPLT__Member__c').newInstance()).getSObjectType().getDescribe();
            for(Schema.SObjectField field : objectDescribe.fields.getMap().values()){
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                if( SobjectService.getType(fieldDescribe.getType().name()) == 'Number'){
                    memberNumericFields.add( new Map<String,String>{'label' => fieldDescribe.getLabel(), 'value' => fieldDescribe.getName()} );
                }
            }

            relatedFieldsMap.put('memberNumericComparisonFieldOptions', memberNumericFields);

            return relatedFieldsMap;
        }catch(Exception e){
            throw new AuraHandledException(Label.InvalidValue);
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, List<Map<String, String>>> getWiredRelatedFields(String objectName) {
        return getRelatedFields(objectName);
    }

    // Code used by backend lightning
    @AuraEnabled
    public static String deleteRecord(Id recordId){
		try{
			if( String.isBlank(recordId) ){
				throw new AuraHandledException(Label.InvalidValue);
			}
			String query = 'SELECT Id FROM ';

			DescribeSObjectResult objectDescribe = ((Id)recordId).getSObjectType().getDescribe();
			query += objectDescribe.getName() + ' WHERE Id =: recordId';
			List<SObject> records = Database.query(query);
			if(objectDescribe.isDeletable()){
				Criteria.validateAdminFields = false;
            		delete records;
            	Criteria.validateAdminFields = true;
			}else{
				throw new FieloException(String.format(Label.security_error_object_not_deletable,new List<String>{objectDescribe.getName()}));
			}
		}catch(DmlException e){
            throw new AuraHandledException(e.getDMLMessage(0));
        }catch(Exception e){
			throw new AuraHandledException(e.getMessage());
		}
		return 'Ok';
	}

    // Code used by backend lightning
    @AuraEnabled
    public static String saveRanks(String challengeId, List<Map<String,Object>> ranks){
        try{
            LevelService.createRanks(challengeId, ranks);
        }catch(DmlException e){
            throw new AuraHandledException(e.getDMLMessage(0));
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return 'Ok';
    }

    // Code used by backend lightning
    @AuraEnabled
    public static List<Map<String,Object>> getRanks(Id challengeId, List<String> fieldset){
        List<Map<String,Object>> ranks = new List<Map<String,Object>>();
        try{
            ranks = LevelService.getRanks(challengeId, new Set<String>(fieldset));
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return ranks;
    }

    // Code used by backend lightning
    @AuraEnabled(cacheable=true)
    public static Object getRanksHistory(String challengeMemberId){
        try{
            Map<Id, Object> rankHistory = (Map<Id, Object>)LevelService.getRanksHistory(new List<Id>{challengeMemberId});
            return rankHistory.containsKey(challengeMemberId) ? rankHistory.get(challengeMemberId) : ((Object) new Map<String, Object>());
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Object getWiredFieldSet(String objectApiName, String fieldSetName){
        Map<String,Object> fieldMap = new Map<String,Object>();
        List<String> fieldset = new List<String>();
        List<Map<String,Object>> columns = new List<Map<String,Object>>();

        Schema.DescribeSObjectResult objectDescribe = ((sObject)Type.forName(objectApiName).newInstance()).getSObjectType().getDescribe();
        Schema.DescribeFieldResult fieldDescribe;
        Map<String,Object> col;
        String fieldType;
        Map<String,Object> fieldMeta;
        if( objectDescribe != null &&  fieldSetName != null ){
            for ( Schema.FieldSetMember fieldSetMemberObj : objectDescribe.FieldSets.getMap().get(fieldSetName).getFields()) {
                //The list with the api names
                if( fieldSetMemberObj.getFieldPath() == 'RecordTypeId'){
                    fieldset.add('RecordType');
                } else {
                    fieldDescribe = fieldSetMemberObj.getSObjectField().getDescribe();
                    fieldType = fieldDescribe.getType().name().toLowerCase();

                    fieldset.add(fieldSetMemberObj.getFieldPath());

                    fieldMeta = new Map<String,Object>();
                    fieldMap.put(fieldSetMemberObj.getFieldPath(), fieldMeta);

                    fieldMeta.put('type', (Object) fieldType);
                    fieldMeta.put('label', (Object) fieldDescribe.getLabel());
                    fieldMeta.put('jsType', (Object) jsPrimitiveTypeMap.get(fieldDescribe.getType().name().toLowerCase()));
                    fieldMeta.put('scale', (Object) String.valueOf(fieldDescribe.getScale()));
                    fieldMeta.put('relationshipName', (Object) fieldDescribe.getRelationshipName());
                    fieldMeta.put('referenceToNameField', (Object) (fieldDescribe.getReferenceTo() != null && !fieldDescribe.getReferenceTo().isEmpty() ?
                            getNameField(fieldDescribe.getReferenceTo()[0].getDescribe()) :
                            ''));
                    fieldMeta.put('name', (Object) fieldSetMemberObj.getFieldPath());
                    fieldMeta.put('precision', (Object) fieldDescribe.getPrecision());
                    fieldMeta.put('referenceTo', (Object) fieldDescribe.getReferenceTo() != null && !fieldDescribe.getReferenceTo().isEmpty() ?
                        fieldDescribe.getReferenceTo().get(0).getDescribe().getName() :
                        '');
                    fieldMeta.put('referenceToLabel', (Object) (fieldDescribe.getReferenceTo() != null && !fieldDescribe.getReferenceTo().isEmpty() ?
                            fieldDescribe.getReferenceTo().get(0).getDescribe().getLabel() :
                            ''));
                    fieldMeta.put('className', fieldSetMemberObj.getFieldPath().replaceAll('__','').replaceAll('.',''));

                    col = new Map<String,Object>();
                    col.put('name', (Object) fieldSetMemberObj.getFieldPath());
                    col.put('fieldName', (Object) fieldSetMemberObj.getFieldPath());


                    if (fieldSetMemberObj.getFieldPath().contains('.')) {
                        col.put('label', getPathLabel(objectApiName, fieldSetMemberObj.getFieldPath()));
                    } else {
                        col.put('label', (Object) fieldDescribe.getLabel());
                    }

                    // Customizations
                    switch on fieldSetName {
                        when 'FieloPLT__ccPayoutItems' {
                            if (fieldSetMemberObj.getFieldPath()=='Name') {
                                col.put('label', (Object) Label.PayoutItemName);
                            }
                        }
                    }

                    switch on fieldType {
                        when 'text' {
                            col.put('type', (Object) 'text');
                            fieldMeta.put('isText', (Object) true);
                        }
                        when 'percent' {
                            col.put('type', (Object) 'percent');
                            fieldMeta.put('isPercent', (Object) true);
                        }
                        when 'currency' {
                            col.put('type', (Object) 'currency');
                            col.put('typeAttributes', (Object) new Map<String, String>{
                                'currencyCode' => 'USD'
                            });
                            col.put('cellAttributes', (Object) new Map<String, String>{
                                'alignment' => 'left'
                            });
                            fieldMeta.put('isCurrency', (Object) true);
                        }
                        when 'double','integer','decimal' {
                            col.put('type', (Object) 'number');
                            col.put('typeAttributes', (Object) new Map<String, String>{
                                'minimumFractionDigits' => String.valueOf(fieldDescribe.getScale())
                            });
                            col.put('cellAttributes', (Object) new Map<String, String>{
                                'alignment' => 'left'
                            });
                            fieldMeta.put('isNumber', (Object) true);
                        }
                        when 'reference' {
                            col.put('type', (Object) 'text');
                            col.put('fieldName', (Object) fieldDescribe.getRelationshipName() + '.' + String.valueOf( ((Map<String,Object>)fieldMap.get(fieldSetMemberObj.getFieldPath())).get('referenceToNameField')));
                            fieldMeta.put('isText', (Object) true);
                        }
                        when 'date' {
                            col.put('type', (Object) 'date');
                            col.put('typeAttributes', (Object) new Map<String, String>{
                                'timeZone' => 'UTC',
                                'year' => 'numeric',
                                'month' => 'numeric',
                                'day' => 'numeric'
                            });
                            fieldMeta.put('isDate', (Object) true);
                        }
                        when 'datetime' {
                            col.put('type', (Object) 'date');
                            col.put('typeAttributes', (Object) new Map<String, Object>{
                                'timeZone' => (Object) 'UTC',
                                'year' => (Object) 'numeric',
                                'month' => (Object) 'numeric',
                                'day' => (Object) 'numeric',
                                'hour' => (Object) '2-digit',
                                'minute' => (Object) '2-digit',
                                'hour12' => (Object) true
                            });
                            fieldMeta.put('isDatetime', (Object) true);
                        }
                        when else {
                            fieldMeta.put('isText', (Object) true);
                        }
                    }
                    columns.add(col);
                }
            }
        }

        return (Object) new Map<String,Object>{
            'fieldSet' => (Object) fieldset,
            'fieldMap' => (Object) fieldMap,
            'columns' => (Object) columns
        };
    }

    public static string getPathLabel(String objectName, String path) {
        Schema.DescribeSObjectResult describe = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe();

        if (path.contains('.')) {
            List<String> fieldPath = path.split('\\.');
            String relationShipName = fieldPath.remove(0);
            string fieldName = relationShipName.endsWith('__r') ? relationShipName.replace('__r','__c') : relationShipName + 'Id';
            return getPathLabel(
                describe.fields.getMap().get(fieldName).getDescribe().getReferenceTo().get(0).getDescribe().getName(),
                String.join(fieldPath,'.')
            );
        } else {
            if (!describe.fields.getMap().get(path).getDescribe().getLabel().trim().startsWith(describe.getLabel())) {
                return describe.getLabel() + ' ' + describe.fields.getMap().get(path).getDescribe().getLabel();
            } else {
                return describe.fields.getMap().get(path).getDescribe().getLabel();
            }
        }
    }

    //return the fieldset LandingList configured (api names) for the object.
    @AuraEnabled
    public static List<String> getFieldSet(String objectApiName, String fieldSetName){
        List<String> fielset = new List<String>();
        try{
            Schema.DescribeSObjectResult objectDescribe = ((sObject)Type.forName(objectApiName).newInstance()).getSObjectType().getDescribe();
            if( objectDescribe != null &&  fieldSetName != null ){
                for ( Schema.FieldSetMember fieldSetMemberObj : objectDescribe.FieldSets.getMap().get(fieldSetName).getFields()) {
                    //The list with the api names
					if( fieldSetMemberObj.getFieldPath() == 'RecordTypeId'){
					    fielset.add('RecordType');
					}else {
						fielset.add(fieldSetMemberObj.getFieldPath());
					}
                }
            }
        }catch(Exception e){
            return new List<String>{'Name','CreatedDate' };
        }
        return fielset;
    }


    // Code used by backend lightning
    // Return list of filers based on the Target Audience
    @AuraEnabled
    public static List<Map<String, String>> getFilters(String objectName, Map<String, Object> dataFilters) {
        List<Map<String, String>> allStatus = new List<Map<String, String>>();
        Set<String> added = new Set<String>();
        String filterValue = '';

        if (objectName != 'FieloPLT__Library__c' && objectName != 'FieloPLT__Payout__c') {
            allStatus.add( new map<String, String>{
                'value' => 'null',
                'label' => label.All,
                'count' =>  String.valueOf(new SObjectsSelector().queryCountRecords(objectName, JSON.serialize(dataFilters)))
             });
        }

        if(objectName == 'FieloPLT__Segment__c' || objectName == 'FieloPLT__Level__c'){
            Map<String, Object> filter = dataFilters;
            filter.put('FieloPLT__IsActive__c', 'BOOLEAN:true');
            allStatus.add( new map<String, String>{
                'value' => 'BOOLEAN:true',
                'label' => label.Active,
                'count' =>  String.valueOf(new SObjectsSelector().queryCountRecords(objectName, JSON.serialize(filter)))
            } );
            filter = dataFilters;
            filter.put('FieloPLT__IsActive__c', 'BOOLEAN:false');

            allStatus.add( new map<String, String>{
                'value' => 'BOOLEAN:false',
                'label' => label.Inactive,
                'count' =>  String.valueOf(new SObjectsSelector().queryCountRecords(objectName, JSON.serialize(filter)))
            } );
        } else if(objectName == 'FieloPLT__Promotion__c' || objectName == 'FieloPLT__Challenge__c' || objectName == 'FieloPLT__Member__c' || objectName == 'FieloPLT__Library__c' || objectName == 'FieloPLT__Language__c' || objectName == 'FieloPLT__Redemption__c' || objectName == 'FieloPLT__Budget__c' || objectName == 'FieloPLT__Payout__c'){
            Map<String, Object> filters = (Map<String, Object>) dataFilters;
            // TEAMS
            if ( objectName == 'FieloPLT__Member__c' && filters.containsKey('FieloPLT__Type__c') && String.valueOf(filters.get('FieloPLT__Type__c')) == 'Team') {

                Map<String, String> mapStatus = getStatusLabelForTeam();

                filters.put('FieloPLT__Status__c', 'Active');
                allStatus.add( new map<String, String>{
                    'value' => 'Active',
                    'label' => mapStatus.get('Active'),
                    'count' =>  String.valueOf(new SObjectsSelector().queryCountRecords(objectName, JSON.serialize(filters)))
                } );

                filters.put('FieloPLT__Status__c', 'Inactive');
                allStatus.add( new map<String, String>{
                    'value' => 'Inactive',
                    'label' => mapStatus.get('Inactive'),
                    'count' =>  String.valueOf(new SObjectsSelector().queryCountRecords(objectName, JSON.serialize(filters)))
                } );

                filters.put('FieloPLT__Status__c', 'Draft');
                allStatus.add( new map<String, String>{
                    'value' => 'Draft',
                    'label' => mapStatus.get('Draft'),
                    'count' =>  String.valueOf(new SObjectsSelector().queryCountRecords(objectName, JSON.serialize(filters)))
                } );
            } else if (objectName == 'FieloPLT__Library__c') {
                Integer activeLibraries = 0;
                Integer inactiveLibraries = 0;
                map<String, FieloPLT__Library__c> librariesOnDBMap = new map<String, FieloPLT__Library__c>();
                for(FieloPLT__Library__c l: new LibrariesSelector().selectLibraries()){
                    if(!librariesOnDBMap.containsKey(l.Name)){
                        librariesOnDBMap.put(l.Name, l);
                    }
                }
                for(StaticResource sr: [SELECT Id, Name, NamespacePrefix, SystemModStamp, Body FROM StaticResource WHERE Description Like '%FieloPLT-Library%']){
                    MigrationUtils.ImportJSON records;
                    try{
                        records = MigrationService.importGetRecords(sr.Body.toString());
                    }catch(DMLException e){
                        String errorMsge = '';
                        for(Integer i = 0; i < e.getNumDML(); i++){
                            errorMsge += e.getDMLMessage(i) + ' ';
                        }
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, String.format(label.AuditError, new List<String>{string.valueOf(errorMsge)})));
                    }

                    if(records != null && records.migrationRecords != null){
                        for(MigrationUtils.MigrationObject mo: records.migrationRecords){
                            if(mo.objectAPIName == 'fieloplt__library__c'){
                                for(MigrationUtils.MigrationRecord mr: mo.records){
                                    if(librariesOnDBMap.containsKey(mr.getField('name').value)){
                                        activeLibraries++;
                                    } else {
                                        inactiveLibraries++ ;
                                    }
                                }
                            }

                        }
                    }
                }
                allStatus.add( new map<String, String>{
                    'value' => 'null',
                    'label' => label.All,
                    'count' =>  String.valueOf(inactiveLibraries+activeLibraries)
                });
                filters.put('FieloPLT__Status__c', 'Active');
                allStatus.add( new map<String, String>{
                    'value' => 'Active',
                    'label' => label.Active,
                    'count' =>  String.valueOf(activeLibraries)
                } );

                filters.put('FieloPLT__Status__c', 'Inactive');
                allStatus.add( new map<String, String>{
                    'value' => 'Inactive',
                    'label' => label.Inactive,
                    'count' =>  String.valueOf(inactiveLibraries)
                } );
            } else if (objectName == 'FieloPLT__Payout__c') {

                allStatus.add( new map<String, String>{
                    'value' => 'null',
                    'label' => label.All,
                    'count' =>  String.valueOf(new SObjectsSelector().countPayoutRecords(JSON.serialize(dataFilters)))
                });

                filterValue = '';

                for( Schema.PicklistEntry entry : FieloPLT__Payout__c.FieloPLT__Status__c.getDescribe().getPicklistValues() ){
                    if( entry.isActive() && !added.contains( entry.getValue() )){
                        filterValue = '{"FieloPLT__Program__c":"'+dataFilters.get('FieloPLT__Program__c')+'","FieloPLT__Status__c":"'+entry.getValue()+'"}';
                        added.add( entry.getValue() );
                        allStatus.add( new map<String, String>{
                            'value' => entry.getValue(),
                            'label' => entry.getLabel(),
                            'count' => String.valueOf(new SObjectsSelector().countPayoutRecords(filterValue))
                        } );
                    }
                }
            } else {
                filterValue = '';
                Schema.DescribeSObjectResult objectDescribe = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe();
                if( objectDescribe.fields.getMap().containskey('FieloPLT__Status__c')) {
                    for( Schema.PicklistEntry entry : objectDescribe.fields.getMap().get('FieloPLT__Status__c').getDescribe().getPicklistValues() ){
                        if( entry.isActive() && !added.contains( entry.getValue() )){
                            if ( objectName != 'FieloPLT__Language__c' ){
                                filterValue = '{"FieloPLT__Program__c":"'+dataFilters.get('FieloPLT__Program__c')+'","FieloPLT__Status__c":"'+entry.getValue()+'"}';
                            }
                            if ( objectName == 'FieloPLT__Member__c' ) {
                                filterValue = '{"FieloPLT__Type__c":"!Team","FieloPLT__Program__c":"'+dataFilters.get('FieloPLT__Program__c')+'","FieloPLT__Status__c":"'+entry.getValue()+'"}';
                            }
                            if ( objectName == 'FieloPLT__Language__c'){
                                filterValue = '{"FieloPLT__Status__c":"'+entry.getValue()+'"}';
                            }

                            added.add( entry.getValue() );

                            List<String> invalidMemberStatus = new List<String>{'Draft', 'Inactive'};
                            if(objectName != 'FieloPLT__Member__c' || (objectName == 'FieloPLT__Member__c' && !invalidMemberStatus.contains(entry.getValue()))){
                                allStatus.add( new map<String, String>{
                                    'value' => entry.getValue(),
                                    'label' => entry.getLabel(),
                                    'count' => String.valueOf(new SObjectsSelector().queryCountRecords(objectName, filterValue))
                                } );
                            }
                        }
                    }
                }
            }
        }
        return allStatus;
    }
    @AuraEnabled
    public static List<Map<String, String>> getRecordTypes(String objectName) {
        List<Map<String, String>> recordTypeMapList = new List<Map<String, String>>();
        if (objectName != null) {
            if (String.isNotBlank(objectName)) {
                DescribeSObjectResult objectDescribe = Schema.describeSObjects(new String[]{objectName})[0];
                List<Schema.RecordTypeInfo> RecordTypes = objectDescribe.getRecordTypeInfos();
                for (Schema.RecordTypeInfo rt : RecordTypes) {
                    recordTypeMapList.add( new Map<String,String>{
                        'id' => rt.getRecordTypeId(),
                        'developerName' => rt.getDeveloperName()
                    });
                }
            }
        }
        return recordTypeMapList;
    }
	@AuraEnabled
    public static String saveJunctionObjectRecord(sObject master, List<Id> records, String apiNameJuctionObject) {
        String apiNameFirstFather;
        String apiNameSecondFather;
        String query = '';
        sObject JuctionObject;
        Schema.SObjectField lookupFirstFather;
        Schema.SObjectField lookupSecondFather;
        Map<String, Schema.SObjectType> mapObjectTypes = Schema.getGlobalDescribe();
		List<Schema.SObjectType> objectTypes = new List<Schema.SObjectType>();
		Savepoint sp = Database.setSavepoint();
		try{
			if( master == null || records == null || apiNameJuctionObject == null ){
				throw new AuraHandledException('the parameters cannot be null');
			} else {
				if(records != null && !records.isEmpty()){
					id myid = records.get(0);
					apiNameSecondFather = ((Id)myid).getSobjectType().getDescribe().getName();
				}
				JuctionObject = mapObjectTypes.get(apiNameJuctionObject).newSObject();
				apiNameFirstFather = master.getSobjectType().getDescribe().getName();
				objectTypes.add(master.getSobjectType());
				objectTypes.add(JuctionObject.getSobjectType());
				SObjectUnitOfWork uow = new SObjectUnitOfWork(objectTypes);
				String idMaster;
				//FirstTime only creation of master
				if(master.Id == null && records != null && records.isEmpty()){
					uow.registerNew(master);
				//Edit of master, insert/delete juctionObjects
				}else if(master.Id != null && !records.isEmpty()){
                    if (apiNameJuctionObject == 'FieloPLT__TeamMember__c') {
                        lookupFirstFather = Schema.TeamMember__c.sObjectType.fields.Team__c;
                        lookupSecondFather = Schema.TeamMember__c.sObjectType.fields.Member__c;
                    } else {
                        lookupFirstFather = getLookupField(JuctionObject, apiNameFirstFather);
                        lookupSecondFather = getLookupField(JuctionObject, apiNameSecondFather);
                    }
					idMaster = master.Id;
					Set<String> keys = new Set<String>();

                    if( !SecurityUtils.canRead(apiNameJuctionObject, new List<String>{String.valueOf(lookupFirstFather), String.valueOf(lookupSecondFather)}) ){
                        throw new FieloException(String.format(Label.security_error_field_not_readable, new List<String>{apiNameJuctionObject, String.valueOf(lookupFirstFather) + ', ' + String.valueOf(lookupSecondFather)}));
                    }

					//Delete juctionObjects
					query = 'SELECT Id FROM ' + apiNameJuctionObject + ' WHERE ' + lookupFirstFather + '=:idMaster' + ' AND ' + lookupSecondFather + ' NOT IN: records';
                    for(sObject obj: Database.query(query)){
						uow.registerDeleted(obj);
					}
					//Create juctionObjects
					query = 'SELECT Id,' + lookupFirstFather + ',' + lookupSecondFather + ' FROM ' + apiNameJuctionObject + ' WHERE ' + lookupFirstFather + '=:idMaster' + ' AND ' + lookupSecondFather + ' IN: records';
                    for(sObject obj: Database.query(query)){
						String key = (String)obj.get(lookupFirstFather) + (String)obj.get(lookupSecondFather);
						keys.add(key);
					}
					uow.registerDirty(master);
					for(Id idSecondFather: records){
						String key = (String)master.Id + (String)idSecondFather;
						if(!keys.contains(key)){
							sObject JuctionObj = mapObjectTypes.get(apiNameJuctionObject).newSObject();
							JuctionObj.put(lookupFirstFather, master.Id);
							JuctionObj.put(lookupSecondFather, idSecondFather);
							uow.registerNew(JuctionObj);
						}
					}
				//FirstTime insert of master and insert juctionObjects
				}else if(master.Id == null && records != null && !records.isEmpty()){
                    uow.registerNew(master);
                    if (apiNameJuctionObject == 'FieloPLT__TeamMember__c') {
                        lookupFirstFather = Schema.TeamMember__c.sObjectType.fields.Team__c;
                        lookupSecondFather = Schema.TeamMember__c.sObjectType.fields.Member__c;
                    } else {
					    lookupFirstFather = getLookupField(JuctionObject, apiNameFirstFather);
					    lookupSecondFather = getLookupField(JuctionObject, apiNameSecondFather);
                    }
					for(Id idSecondFather: records){
						sObject JuctionObj = mapObjectTypes.get(apiNameJuctionObject).newSObject();
						JuctionObj.put(lookupSecondFather, idSecondFather);
						uow.registerNew(JuctionObj, lookupFirstFather, master);
					}
				//Edit Master and Delete all juctionObjects
				}else if(master.Id != null && records != null && records.isEmpty()){
					idMaster = master.Id;
                    if (apiNameJuctionObject == 'FieloPLT__TeamMember__c') {
                        lookupFirstFather = Schema.TeamMember__c.sObjectType.fields.Team__c;
                        lookupSecondFather = Schema.TeamMember__c.sObjectType.fields.Member__c;
                    } else {
                        lookupFirstFather = getLookupField(JuctionObject, apiNameFirstFather);
                        lookupSecondFather = getLookupField(JuctionObject, apiNameSecondFather);
                    }
					uow.registerDirty(master);
					query = 'SELECT Id FROM ' + apiNameJuctionObject + ' WHERE ' + lookupFirstFather + '=:idMaster';
					for(sObject obj: Database.query(query)){
						uow.registerDeleted(obj);
					}
				}

				if( !master.getSobjectType().getDescribe().isCreateable() || !master.getSobjectType().getDescribe().isUpdateable() ){
                throw new FieloException(String.format(Label.security_error_object_not_insertable, new List<String>{master.getSObjectType().getDescribe().name}));
				}else{
					Map<String, Object> fieldsToVerify = master.getPopulatedFieldsAsMap();
					Map<String, SObjectField> fieldsMapByName = master.getSobjectType().getDescribe().fields.getMap();
					for (String fieldName : fieldsToVerify.keySet()){
						if(fieldsMapByName.containsKey(fieldName.toLowerCase())){
							SObjectField desiredSobjField = fieldsMapByName.get(fieldName.toLowerCase());
							if(fieldName != 'Id' &&  desiredSobjField != null && !desiredSobjField.getDescribe().isCreateable() && !desiredSobjField.getDescribe().isUpdateable()){
								throw new FieloException(String.format(Label.security_error_field_not_insertable, new List<String>{master.getSObjectType().getDescribe().getName(),fieldName}));
							}
						}

					}
				}
				uow.commitWork();
			}
		}
        catch (DmlException e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getDMLMessage(0));
        }
        catch(exception e){
			Database.rollback(sp);
			throw new AuraHandledException(e.getMessage());
		}
        return master.Id;


    }

    // Code used by backend

	public static List<Map<String, Object>> getObjectsInfo( String programId, String objApiNames, String fieloApp ) {
        Map<String, Map<String, Object>> objectInfoMap = new Map<String, Map<String, Object>>();
        if(String.isBlank(objApiNames) || fieloApp == null){
			return objectInfoMap.values();
        }
        try{
            List<Schema.DescribeSObjectResult> describes = Schema.describeSObjects(new List<String>(objApiNames.split(',')));
            Map<String, String> filter;
            for(Schema.DescribeSObjectResult describeResult: describes){
                String objectKey = describeResult.getName();
                objectInfoMap.put(objectKey, new Map<String, Object>());
                objectInfoMap.get(objectKey).put('apiName', objectKey);
                objectInfoMap.get(objectKey).put('objectKey', objectKey);
                objectInfoMap.get(objectKey).put('labelPlural', describeResult.getLabelPlural());
                objectInfoMap.get(objectKey).put('labelSingular', describeResult.getLabel());
                if (!String.isBlank(programId) && objectKey != 'FieloPLT__Library__c' && objectKey != 'FieloPLT__Language__c'){
                    objectInfoMap.get(objectKey).put('filter', new Map<String, String>{'FieloPLT__Program__c' => programId});
                }
                if (objectKey == 'FieloPLT__Level__c'){
                    objectInfoMap.get(objectKey).remove('filter');
                    objectInfoMap.get(objectKey).put('filter', new Map<String, String>{'FieloPLT__Program__c' => programId,'FieloPLT__Challenge__c'=>'' });
                }

                if(objectInfoMap.get(objectKey).containsKey('filter')){
                    if (objectKey == 'FieloPLT__Payout__c') {
                        objectInfoMap.get(objectKey).put('quantity', Fielo_AuraService.countPayoutRecords(JSON.serialize(objectInfoMap.get(objectKey).get('filter'))));
                    } else {
                        objectInfoMap.get(objectKey).put('quantity', Fielo_AuraService.countRecords(objectKey, JSON.serialize(objectInfoMap.get(objectKey).get('filter'))));
                    }
                }else{
                    if (objectKey == 'FieloPLT__Payout__c') {
                        objectInfoMap.get(objectKey).put('quantity', Fielo_AuraService.countPayoutRecords(null));
                    } else {
                        objectInfoMap.get(objectKey).put('quantity', Fielo_AuraService.countRecords(objectKey, null));
                    }
                }

                switch on objectKey {
                  //  when 'FieloPLT__Library__c' {
                  //      objectInfoMap.get(objectKey).put('quantity', 0);
                  //  }
                    when 'FieloPLT__Level__c' {
                        objectInfoMap.get(objectKey).put('fieldset', 'FieloPLT__LevelLanding');
                        objectInfoMap.get(objectKey).put('orderBy', 'FieloPLT__Order__c ASC');
                    }
                    when 'FieloPLT__Payout__c' {
                        // objectInfoMap.get(objectKey).put('fieldset', 'FieloPLT__PayoutLanding');
                        objectInfoMap.get(objectKey).put('orderBy', 'FieloPLT__PayoutDate__c ASC');
                        objectInfoMap.get(objectKey).put('icon', 'standard:partner_fund_request');
                    }
                    when 'FieloPLT__Redemption__c' {
                        objectInfoMap.get(objectKey).put('fieldset', 'FieloPLT__RedemptionLanding');
                        objectInfoMap.get(objectKey).put('orderBy', 'Name ASC');
                    }
                    when 'FieloPLT__Promotion__c' {
                        objectInfoMap.get(objectKey).put('fieldset', 'FieloPLT__PromotionLanding');
                    }
                    when 'FieloPLT__Language__c' {
                        objectInfoMap.get(objectKey).put('fieldset', 'FieloPLT__LanguageLanding');
                    }
                    when 'FieloPLT__Challenge__c' {
                        objectInfoMap.get(objectKey).put('fieldset', 'FieloPLT__ChallengeLanding');
                    }
                    when 'FieloPLT__Member__c' {
                        if(fieloApp == 'Target Audience'){
                            filter = new Map<String, String>((Map<String, String>) objectInfoMap.get(objectKey).get('filter'));
                            filter.put('FieloPLT__Type__c', '!Team');
                            objectInfoMap.get(objectKey).put('filter', (Object) filter);
                            objectInfoMap.get(objectKey).put('icon', 'standard:customers');
                            objectInfoMap.get(objectKey).put('fieldset', 'FieloPLT__MemberLanding');
                            objectInfoMap.get(objectKey).put('quantity', Fielo_AuraService.countRecords(objectKey, JSON.serialize(objectInfoMap.get(objectKey).get('filter'))));

                            // Teams
                            String teamObjKey = objectKey+'-Team';
                            objectInfoMap.put(teamObjKey, new Map<String, Object>());
                            objectInfoMap.get(teamObjKey).put('apiName', objectKey);
                            objectInfoMap.get(teamObjKey).put('objectKey', teamObjKey);
                            objectInfoMap.get(teamObjKey).put('labelSingular', Label.Team);
                            objectInfoMap.get(teamObjKey).put('labelPlural', Label.Teams);
                            objectInfoMap.get(teamObjKey).put('fieldset', 'FieloPLT__TeamLanding');
                            objectInfoMap.get(teamObjKey).put('icon', 'standard:groups');
                            objectInfoMap.get(teamObjKey).put('filter', new Map<String, String>{'FieloPLT__Program__c' => programId});

                            filter = new Map<String, String>((Map<String, String>) objectInfoMap.get(teamObjKey).get('filter'));
                            filter.put('FieloPLT__Type__c', 'Team');
                            objectInfoMap.get(teamObjKey).put('filter', (Object) filter);

                            objectInfoMap.get(teamObjKey).put('quantity', Fielo_AuraService.countRecords(objectKey, JSON.serialize(objectInfoMap.get(teamObjKey).get('filter'))));
                        }
                    }
                    when 'FieloPLT__Budget__c' {
                        objectInfoMap.get(objectKey).put('fieldset', 'FieloPLT__BudgetingLanding');
                    }
                }
            }
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
		return objectInfoMap.values();
	}

    @AuraEnabled
	public static Map<String, Object> getRelatedObjectInfo(String objectName, String relatedList, Id recordId) {
        Boolean isRank = false;
        Map<String, Object> results = new Map<String, Object>();
        if( String.isEmpty(objectName) ){
            throw new AuraHandledException('ObjectName is required.');
        }
        if( String.isEmpty(relatedList) ){
            throw new AuraHandledException('RelatedList is required.');
        }

        if( objectName == 'FieloPLT__Member__c' && relatedList == 'FieloPLT__RankMembers__r' ){
            isRank = true;
            relatedList = 'FieloPLT__LevelsMembers__r';
        }

        //Get related object based on the related list api name
        Schema.DescribeSObjectResult describeResult = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe();
        String relatedObject = '';
        for(Schema.ChildRelationship thisChild : describeResult.getChildRelationships()){
            if(thisChild.getRelationshipName() != null && String.valueOf(thisChild.getRelationshipName()) == relatedList){
                relatedObject = String.valueOf(thisChild.getChildSObject());
                break;
            }
        }

        //For related object
        Set<String> objects = new Set<String>();
        Map<String, String> relNameByObject = new Map<String, String>();
        if( String.isNotEmpty(relatedObject) ){
            describeResult = ((sObject)Type.forName(relatedObject).newInstance()).getSObjectType().getDescribe();
            //If it is Rank then replace Level for Rank
            String label = describeResult.getLabel();
            String apiName = describeResult.getName();
            if( isRank ){
                label = label.replace('Level', 'Rank');
                apiName = apiName.replace('Level', 'Rank');
            }
            results.put('label', label);
            results.put('apiName', apiName);

            //Get fields (apiname - label) from related object
            for(String s : describeResult.fields.getMap().keySet()){
                String fieldlabel = describeResult.fields.getMap().get(s).getDescribe().getLabel();
                String fieldApiName = describeResult.fields.getMap().get(s).getDescribe().getName();
                if( isRank ){
                    fieldlabel = fieldlabel.replace('Level', 'Rank');
                    fieldApiName = fieldApiName.replace('Level', 'Rank');
                }

                results.put(fieldApiName, fieldlabel);

                //If has related objects get fields from it
                if( String.valueOf(describeResult.fields.getMap().get(s).getDescribe().getType()) == 'REFERENCE' ){
                    objects.add( describeResult.fields.getMap().get(s).getDescribe().getReferenceTo()[0].getDescribe().getName() );
                    relNameByObject.put(describeResult.fields.getMap().get(s).getDescribe().getReferenceTo()[0].getDescribe().getName(),
                    describeResult.fields.getMap().get(s).getDescribe().getRelationshipName());
                }
            }
        }
        //If has lookup fields, get fields from related objects
        if( !objects.isEmpty() ){
            for(DescribeSObjectResult d : Schema.describeSObjects(new List<String>(objects))){
                Map <String,Object> objectLookup = new Map <String,Object>();
                objectLookup.put('label', d.getLabel());
                //If it is Rank
                for(String s : d.fields.getMap().keySet()){
                    String fieldlabel = d.fields.getMap().get(s).getDescribe().getLabel();
                    String fieldApiName = d.fields.getMap().get(s).getDescribe().getName();
                    if( isRank && d.getName() == 'FieloPLT__Level__c' ){
                        fieldlabel = fieldlabel.replace('Level', 'Rank');
                        fieldApiName = fieldApiName.replace('Level', 'Rank');
                    }
                    objectLookup.put(fieldApiName, fieldlabel);
                }
                results.put(d.getName() ,objectLookup);
                if (relNameByObject.containsKey(d.getName())) {
                    results.put(relNameByObject.get(d.getName()) ,objectLookup);
                }
            }
        }

        if( recordId != null ){
            //Map<String, object> result = new Map<String, object>();
            Map<String, Set<Id>> objectIdMap = new Map<String, Set<Id>>();
            String recordApiName = recordId.getSObjectType().getDescribe().getName();
            String stringSQL = 'SELECT Id, Name, RelatedList__c, Segment__c, Mission__r.Action__r.RuleTrigger__r.Object__c, Rule__r.Action__r.RuleTrigger__r.Object__c, (SELECT Id, FieloPLT__Order__c, FieloPLT__BooleanValue__c, FieloPLT__DateValue__c, FieloPLT__IsField__c, FieloPLT__FieldName__c, FieloPLT__FieldType__c, FieloPLT__NumberValue__c, FieloPLT__Operator__c, FieloPLT__Values__c FROM FieloPLT__Criteria__r ORDER BY FieloPLT__Order__c) FROM CriterionGroup__c WHERE ' + recordApiName + ' = \'' + recordId + '\'';
            for(CriterionGroup__c cg : Database.query(stringSQL)) {
                if (cg.Segment__c != null) objectName = 'fieloplt__member__c';
                if (cg.Mission__r != null) objectName = cg.Mission__r.Action__r.RuleTrigger__r.Object__c;
                if (cg.Rule__r != null) objectName = cg.Rule__r.Action__r.RuleTrigger__r.Object__c;

                describeResult = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe();
                for(Schema.ChildRelationship thisChild : describeResult.getChildRelationships()){
                    if(thisChild.getRelationshipName() != null && thisChild.getRelationshipName().toLowerCase() == cg.RelatedList__c.toLowerCase()){
                        describeResult = thisChild.getChildSObject().getDescribe();
                        break;
                    }
                }

                for(Criterion__c c : cg.Criteria__r){
                    if( c.FieldType__c == 'Reference' ) {
                        String relObjName;
                        if (c.FieldName__c.split('\\.').size() == 1) {
                            relObjName = describeResult.fields.getMap().get(c.FieldName__c).getDescribe().getReferenceTo().get(0).getDescribe().getName();
                        } else {
                            for(Integer i=0; i < c.FieldName__c.split('\\.').size()-1; i++) {
                                String fieldPath = c.FieldName__c.split('\\.')[i];
                                fieldPath = fieldPath.endsWith('__r') ?
                                    fieldPath.replace('__r', '__c') :
                                    ( !fieldPath.endsWith('__c') && !fieldPath.endsWith('Id') ? fieldPath+'Id' : fieldPath);
                                describeResult = describeResult.fields.getMap().get(fieldPath).getDescribe().getReferenceTo().get(0).getDescribe();
                            }
                            String fieldName = c.FieldName__c.split('\\.').get(c.FieldName__c.split('\\.').size()-1);
                            relObjName = describeResult.fields.getMap().get(fieldName).getDescribe().getReferenceTo().get(0).getDescribe().getName();
                        }

                        results.put(c.FieldName__c + '-referenceTo', relObjName);

                        if( objectIdMap.containsKey(relObjName) ){
                            objectIdMap.get(relObjName).add(c.Values__c);
                        } else {
                            objectIdMap.put(relObjName, new Set<Id>{c.Values__c});
                        }
                    }
                }
            }

            for(String s : objectIdMap.keySet()){
                Set<Id> objectIds = new Set<Id>(objectIdMap.get(s));
                String query = 'SELECT Id, Name FROM ' + s + ' WHERE Id In: objectIds';
                for(SObject element : Database.query(query)){
                    results.put(element.Id, element.get('Name'));
                }
            }
        }

        return results;
    }

    @AuraEnabled
    public static Model__c createModel(String objectName, Id recordId) {
        Model__c recordObject;
        objectName = recordId.getSObjectType().getDescribe().getName();

        String exportType = 'model';
        map<String,Set<String>> mapExportRec = new map<String,Set<String>>();

        if(objectName == 'FieloPLT__Promotion__c'){
            recordObject = new Model__c(Type__c = 'Promotion');

            //JSON
            mapExportRec.put('fieloplt__promotion__c', new set<String>{recordId});
            recordObject.JSON__c = MigrationService.exportRecords(MigrationUtils.getExportJSONString('promotions'), mapExportRec, exportType);

        }else if(objectName == 'FieloPLT__Challenge__c'){
            recordObject = new Model__c(Type__c = 'Challenge');

            //JSON
            mapExportRec.put('fieloplt__challenge__c', new set<String>{recordId});
            recordObject.JSON__c = MigrationService.exportRecords(MigrationUtils.getExportJSONString('challenges'), mapExportRec, exportType);

        } else if(objectName == 'FieloPLT__Program__c'){
            recordObject = new Model__c(Type__c = 'Program');

            //JSON
            mapExportRec.put('fieloplt__program__c', new set<String>{recordId});
            recordObject.JSON__c = MigrationService.exportRecords(MigrationUtils.getExportJSONString('programs'), mapExportRec, exportType);

        }
        return recordObject;
    }

    public static boolean canAccess(Schema.DescribeSObjectResult objectDescribe, String fieldName) {
        Boolean hasAccess = true;
        List<String> fieldPath;
        String currentField;
        Schema.DescribeSObjectResult currentDescribe;

        if (fieldName.contains('.')) {
            hasAccess = true;
            fieldPath = fieldName.split('\\.');

            for(Integer index = 0; index < fieldPath.size(); index++) {
                currentDescribe = index == 0 ? objectDescribe : currentDescribe;
                currentField = fieldPath[index].endsWith('__r') ? fieldPath[index].replace('__r','__c') : fieldPath[index];

                if ( index == fieldPath.size()-1 ) {
                    if (!currentDescribe.fields.getMap().get(currentField).getDescribe().isAccessible()) {
                        hasAccess = false;
                        break;
                    }
                } else {
                    if (!currentDescribe.fields.getMap().get(currentField).getDescribe().getReferenceTo().get(0).getDescribe().isAccessible()) {
                        hasAccess = false;
                        break;
                    } else {
                        currentDescribe = SObjectDescribe.getDescribe(currentDescribe.fields.getMap().get(currentField).getDescribe().getReferenceTo().get(0)).getDescribe();
                    }
                }
            }
        } else if(objectDescribe.fields.getMap().containskey(fieldName) && objectDescribe.fields.getMap().get(fieldName).getDescribe().isAccessible()) {
            hasAccess = true;
        } else {
            hasAccess = false;
        }
        return hasAccess;
    }

	@AuraEnabled
	public static String saveFromModel(sObject objectRecord, String modelId, String modelType) {
		String result = '';
        if( objectRecord == null &&  modelId == null && modelType == null){
			throw new FieloException('Record: invalid parameter.');
		} else if ( modelType == 'FieloPLT__Promotion__c' ) {
            try {
                Map<String, Set<Id>> createdPromotionsMap = PromotionService.createFromModel((Promotion__c)objectRecord,modelId);
                if( createdPromotionsMap.containsKey('fieloplt__promotion__c') ){
                    for(Id recordId:  createdPromotionsMap.get('fieloplt__promotion__c')){
                        result = recordId;
                        break;
                    }
                }
            } catch (DmlException e) {
                throw new AuraHandledException(e.getDMLMessage(0));
            } catch(Exception e){
                throw new AuraHandledException(e.getMessage());
            }
        } else if ( modelType == 'FieloPLT__Challenge__c' ) {
            try {
                Map<String, Set<Id>> createdPromotionsMap = ChallengeService.createFromModel((Challenge__c)objectRecord, modelId);
                if( createdPromotionsMap.containsKey('fieloplt__challenge__c') ){
                    for(Id recordId:  createdPromotionsMap.get('fieloplt__challenge__c')){
                        result = recordId;
                        break;
                    }
                }
            } catch (DmlException e) {
                throw new AuraHandledException(e.getDMLMessage(0));
            } catch(Exception e){
                throw new AuraHandledException(e.getMessage());
            }
        } else if ( modelType == 'FieloPLT__Program__c' ) {
            try {
                Map<String, Set<Id>> createdPrgramsMap = ProgramService.createFromModel((Program__c)objectRecord, modelId);
                if( createdPrgramsMap.containsKey('fieloplt__program__c') ){
                    for(Id recordId:  createdPrgramsMap.get('fieloplt__program__c')){
                        result = recordId;
                        break;
                    }
                }
            } catch (DmlException e) {
                throw new AuraHandledException(e.getDMLMessage(0));
            } catch(Exception e){
                throw new AuraHandledException(e.getMessage());
            }
        }
        return result;
    }
    @AuraEnabled
	public static Object adjustTransaction(Transaction__c record) {
        String resultMessage = '';
        RemoteActionResult ram = FormAdjustTransactionController.save( record, null );

        Id transactionId = record.Id;

        List<Point__c> points = Database.query('SELECT Id, Payout__c FROM Point__c WHERE Transaction__c = :transactionId LIMIT 1');

        Id payoutId;
        if (!points.isEmpty()) {
            payoutId = points.get(0).Payout__c;
        }

        resultMessage = '';
        for(RemoteActionResult.RemoteActionMessage m : ram.getMessages()){
            if (m.severity == ApexPages.Severity.ERROR) {
                throw new FieloException(m.summary);
            } else {
                resultMessage += m.summary;
            }
        }
        return (Object) new Map<String, Object>{
            'message' => (Object) resultMessage,
            'record' => (Object) record,
            'payoutId' => payoutId
        };
    }

    @AuraEnabled
	public static Map<String, Object> saveRedemption(Redemption__c record, List<RedemptionItem__c> items){
        RemoteActionResult ram = RedemptionLandingController.save( record, items );
        Map<String, Object> result = new Map<String, Object>();
        if(!ram.recordsId.isEmpty()){
            result.put('message', ram.getMessages()[0].summary);
            result.put('recordId', ram.recordsId[0]);
        }else {
            throw new AuraHandledException(ram.getMessages()[0].summary);
        }

        return result;
    }


    @AuraEnabled
	public static String setManager(String recordId, boolean setUnset) {
		String result = '';
        try{
            if(recordId != null && setUnset != null){
                MemberService.toggleManagers(new List<Id>{recordId}, (setUnset) ? 'true' : 'false');
            }
        }catch(DMLException e){
            result = e.getDMLMessage(0);
        }catch(Exception e){
            result = e.getMessage();
        }
        return result;
    }

    // Code used by backend
    @AuraEnabled
    public static Object getDynamicSegmentsMembers(String fields, String objectName, String dataFilters, String orderBy, Integer recordsPerPage, Integer offset) {
        return SegmentService.getMembers(objectName, fields, offset, orderBy, dataFilters, recordsPerPage, null);
    }

    // Code used by backend
	@AuraEnabled
	public static List<Id> getSegmentsIdsByMember( String memberId ){
        List<Id> response = new List<Id>();
        try{
            Set<Id> segmentIds = SegmentService.calculateMemberSegments(memberId, null);
            if(!segmentIds.isEmpty()){
                for(Segment__c seg: [SELECT Id, Name FROM Segment__c WHERE Id IN: segmentIds AND RecordType.DeveloperName != 'Metasegment']){
                    response.add(seg.Id);
                }
            }
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return response;
    }

    @AuraEnabled
    public static List<Object> getConsents(Id recordId){
        List<Object> consents = new List<Object>();
        for(SObjectService.Consent consent: SObjectService.getConsents(recordId)){
            Map<String, Object> tempConsent = new Map<String, Object>();
            tempConsent.put('consent', (Object) consent.consent);
            if(consent.isActive){
                tempConsent.put('isActive', consent.isActive);
                tempConsent.put('isInactive', false);
            } else {
                tempConsent.put('isActive', consent.isActive);
                tempConsent.put('isInactive', true);
            }
            consents.add(tempConsent);
        }
        return consents;
    }

    @AuraEnabled
    public static List<Map<String,Object>> getLibraries(String fields, String objectName, String dataFilters, String orderBy, String recordsPerPage, String offset) {
            dataFilters = dataFilters.replace('{','');
            dataFilters = dataFilters.replace('}','');
            List<Map<String,Object>> libraries = new  List<Map<String,Object>>();
            map<String, FieloPLT__Library__c> librariesOnDBMap = new map<String, FieloPLT__Library__c>();
            map<String, Decimal> staticResourcesLibraryVersionMap = new map<String, Decimal>();
            for(FieloPLT__Library__c l: new LibrariesSelector().selectLibraries()){
                if(!librariesOnDBMap.containsKey(l.Name)){
                    librariesOnDBMap.put(l.Name, l);
                }
            }
            for(StaticResource sr: [SELECT Id, Name, NamespacePrefix, SystemModStamp, Body FROM StaticResource WHERE Description Like '%FieloPLT-Library%']){
                MigrationUtils.ImportJSON records;

                try{
                    records = MigrationService.importGetRecords(sr.Body.toString());
                }catch(DMLException e){
                    String errorMsge = '';
                    for(Integer i = 0; i < e.getNumDML(); i++){
                        errorMsge += e.getDMLMessage(i) + ' ';
                    }
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, String.format(label.AuditError, new List<String>{string.valueOf(errorMsge)})));
                }
                if(records != null && records.migrationRecords != null){
                    for(MigrationUtils.MigrationObject mobject: records.migrationRecords){
                        if(mobject.objectAPIName == 'fieloplt__library__c'){
                            for(MigrationUtils.MigrationRecord mrecord: mobject.records){
                                Decimal vers = 0;
                                try{
                                    vers = Decimal.ValueOf(mrecord.getField('fieloplt__version__c').value);
                                    } catch(Exception e){}
                                if(!staticResourcesLibraryVersionMap.containsKey(mrecord.getField('name').value)){
                                    staticResourcesLibraryVersionMap.put(mrecord.getField('name').value, vers);
                                }

                            }
                        }
                    }

                    for(MigrationUtils.MigrationObject mo: records.migrationRecords){
                        if(mo.objectAPIName == 'fieloplt__library__c'){
                            for(MigrationUtils.MigrationRecord mr: mo.records){
                                Boolean addLibraryToResponse = false;
                                Decimal vers = 0;
                                try{
                                    vers = Decimal.ValueOf(mr.getField('fieloplt__version__c').value);
                                    } catch(Exception e){}

                                Map<Object, Object> libraries_fields = new Map<Object, Object>();
                                for(String field: fields.deleteWhitespace().split(',')){
                                    switch on field {
                                        when 'Name' {
                                            libraries_fields.put(field,mr.getField('name').value);
                                        }
                                        when 'FieloPLT__Version__c' {
                                            if(librariesOnDBMap.containsKey(mr.getField('name').value)){
                                               libraries_fields.put(field,librariesOnDBMap.get(mr.getField('name').value).FieloPLT__Version__c);
                                            }else{
                                               libraries_fields.put(field,vers);
                                            }
                                        }
                                        when 'FieloPLT__Status__c' {
                                            //check for the active and inactive libraries
                                            if(librariesOnDBMap.containsKey(mr.getField('name').value)){
                                                addLibraryToResponse = dataFilters.contains('Active') ? true : false;
                                                //Active
                                                libraries_fields.put('FieloPLT__Status__c', label.Active);
                                                libraries_fields.put('Id', librariesOnDBMap.get(mr.getField('name').value).Id);
                                                libraries_fields.put('resourceIdLibraryName', sr.Id+'-'+mr.getField('name').value);
                                                //Inactivate button label
                                                libraries_fields.put('ButtonLabel', label.Inactivate);

                                                //check an upgrade version
                                                if(staticResourcesLibraryVersionMap.containsKey(mr.getField('name').value)){
                                                    if(staticResourcesLibraryVersionMap.get(mr.getField('name').value) > librariesOnDBMap.get(mr.getField('name').value).FieloPLT__Version__c){
                                                        libraries_fields.put('disableUpgrade', false);
                                                    } else {
                                                        libraries_fields.put('disableUpgrade', true);
                                                    }
                                                }else{
                                                    libraries_fields.put('disableUpgrade', true);
                                                }
                                            }else{
                                                addLibraryToResponse = dataFilters.contains('Inactive') ? true : false;
                                                //Inactive
                                                libraries_fields.put('FieloPLT__Status__c', label.Inactive);
                                                libraries_fields.put('resourceIdLibraryName', sr.Id+'-'+mr.getField('name').value);
                                                //Activate button label
                                                libraries_fields.put('ButtonLabel', label.Activate);
                                                libraries_fields.put('disableUpgrade', true);
                                            }
                                        }
                                    }
                                }
                                if(addLibraryToResponse){
                                   libraries.add( new Map<String,Object>{'libraries' => libraries_fields} );
                                   addLibraryToResponse = false;
                                } else if (String.isBlank(dataFilters)){
                                   libraries.add( new Map<String,Object>{'libraries' => libraries_fields} );
                                }
                            }
                        }
                    }
                }
            }
            return libraries;
    }

    @AuraEnabled
    public static List<String> changeLibraryStatus(String resourceIdLibraryName, String action ) {
        List<String> result = new List<String>();

            if(!String.isBlank(action) && !String.isBlank(resourceIdLibraryName) ){
                switch on action {
                    when 'Activate' {
                        RemoteActionResult ram = LibraryLandingController.activate(resourceIdLibraryName);
                        result.add(string.valueOf(ram.getMessages().get(0).summary));
                        result.add(string.valueOf(ram.getMessages().get(0).severity));
                    }
                    when 'Inactivate' {
                        RemoteActionResult ram = LibraryService.changeStatus(resourceIdLibraryName, null, null, 'inactivate');
                        result.add(string.valueOf(ram.getMessages().get(0).summary));
                        result.add(string.valueOf(ram.getMessages().get(0).severity));
                    }
                    when 'Upgrade' {
                        RemoteActionResult ram = LibraryService.changeStatus(null, resourceIdLibraryName.split('-')[0], resourceIdLibraryName.split('-')[1], 'upgrade');
                        result.add(string.valueOf(ram.getMessages().get(0).summary));
                        result.add(string.valueOf(ram.getMessages().get(0).severity));
                    }
                }
            }
        return result;
    }

    // Code used by backend to Fulfilled a redemption item
      @AuraEnabled
    public static boolean fulfilledAndRevertRedemptionItem(Id recordId, String action){
        boolean result;
        List<Id> idsRedemptionItems = new List<Id>();
        List<String> invalidStatusToRevert = new List<String>{'Reverted', 'Delivered'};
		try{
            if (recordId != null) {
                String sObjName = recordId.getSObjectType().getDescribe().getName();
                if (sObjName == 'FieloPLT__Redemption__c') {
                    List<Redemption__c> redemptionsList = new RedemptionsSelector(
                        new Set<String>{
                            'FieloPLT__Status__c'
                        }
                    ).selectById(new Set<Id>{recordId});
                    for(Redemption__c redemption : redemptionsList){
                        if(redemption.Status__c == 'Pending' && action == 'revert'){
                            throw new FieloException(Label.CannotRevertPendingRedemption);
                        }
                    }

                    List<FieloPLT__RedemptionItem__c> redemptionItems = Database.query('SELECT Id, FieloPLT__Status__c FROM FieloPLT__RedemptionItem__c WHERE FieloPLT__Redemption__c = :recordId');
                    for(FieloPLT__RedemptionItem__c r: redemptionItems){
                        if(!invalidStatusToRevert.contains(r.FieloPLT__Status__c)){
                            idsRedemptionItems.add(r.Id);
                        }
                    }
                } else if (sObjName == 'FieloPLT__RedemptionItem__c') {
                    idsRedemptionItems.add((Id)recordId);
                }

                result = idsRedemptionItems.size() > 0 ? true:false;
            }
            if(action == 'deliver'){
                RedemptionItemService.deliverRedemptionItems(idsRedemptionItems);
            }
            if(action == 'revert'){
            RedemptionItemService.revertRedemptionItems(idsRedemptionItems);
            }
		}catch(DmlException e){
            result = false;
			system.debug(e.getDMLMessage(0));
            throw new AuraHandledException(e.getDMLMessage(0));
        }catch(Exception e){
            result = false;
			system.debug(e.getMessage());
			throw new AuraHandledException(e.getMessage());
		}
		return result;
    }

    @AuraEnabled
    public static void implementBehavior(Id recordId){
        try{
            SObjectUnitOfWork uow = new SObjectUnitOfWork(new List<Schema.SObjectType>{RuleTrigger__c.SObjectType});
            FieloPLT__RuleTrigger__c behavior = Database.query('SELECT Id, FieloPLT__Status__c FROM FieloPLT__RuleTrigger__c WHERE Id = :recordId LIMIT 1');
            if(behavior != null){
                behavior.FieloPLT__Status__c = 'In Development';
                uow.registerDirty(behavior);
                uow.commitWork();
            }
            MetadataService.createFutureBehaviorFields(recordId);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<SObject> getPayoutRecords(String dataFilters, String orderBy, String recordsPerPage, String offset) {
        return new SObjectsSelector().queryPayoutRecords(dataFilters, orderBy, recordsPerPage, offset);
    }

    @AuraEnabled
    public static Integer countPayoutCurrencies(String objId) {
        if(String.isEmpty(objId)){
            Program__c program = getActiveProgram();
            if(program != null){
                return new SObjectsSelector().countPayoutCurrencies(program.Id, true);
            }else{
                return 0;
            }
        }else{
            String objName = getRecordObject(objId);
            if(objName == 'FieloPLT__Program__c'){
                return new SObjectsSelector().countPayoutCurrencies(objId, true);
            }if(objName == 'FieloPLT__Member__c'){
                return new SObjectsSelector().countPayoutCurrencies(objId, false);
            }else{
                return 0;
            }
        }
    }

    @AuraEnabled
    public static object changePayoutStatus(String payoutsByMember, String pointsByPayout, String status){
        Map<Id, Set<Id>> payoutsToUpdateMap = new Map<Id, Set<Id>>();
        List<Payout__c> payouts = new List<Payout__c>();

        FieloPLT.Payouts.validateAdminFields = false;
        if (String.isNotBlank(payoutsByMember)) {
            Map<String,Set<String>> payoutsByMemberMap = (Map<String,Set<String>>) JSON.deserialize(payoutsByMember, Map<String,Set<String>>.class);

            Set<Id> memberIdsToQueryAllPayouts = new Set<Id>();
            Set<Id> payoutsToExclude = new Set<Id>();

            for(String memberId : payoutsByMemberMap.keySet()) {
                if (payoutsByMemberMap.get(memberId).contains('all')) {
                    for(String payoutId : payoutsByMemberMap.get(memberId)) {
                        if (payoutId == 'all') {
                            memberIdsToQueryAllPayouts.add(Id.valueOf(memberId));
                        } else {
                            payoutsToExclude.add(Id.valueOf(payoutId));
                        }
                    }
                } else {
                    for(String payoutId : payoutsByMemberMap.get(memberId)) {
                        payoutsToUpdateMap.put(Id.valueOf(payoutId),new Set<Id>());
                    }
                }
            }

            if (!memberIdsToQueryAllPayouts.isEmpty()) {
                String oldStatus = status == 'Pending' ?
                    'Open' :
                        status == 'Paid' ?
                        'Approved' :
                        status == 'Open' ?
                            'Rejected' :
                            'None';
                for(Payout__c p : new PayoutsSelector(new Set<String>{'FieloPLT__Status__c'}).selectByMemberAndStatus(memberIdsToQueryAllPayouts, oldStatus, payoutsToExclude) ){
                    payoutsToUpdateMap.put(p.Id, new Set<Id>());
                }
            }

            payouts = PayoutService.changeStatusPayouts(payoutsToUpdateMap, status);
        } else if (String.isNotBlank(pointsByPayout)) {
            Map<String,Set<String>> pointsByPayoutMap = (Map<String,Set<String>>) JSON.deserialize(pointsByPayout, Map<String,Set<String>>.class);

            for(String payoutId: pointsByPayoutMap.keySet()) {
                payoutsToUpdateMap.put(Id.valueOf(payoutId), new Set<Id>());
                for (String pointId : pointsByPayoutMap.get(payoutId)) {
                    payoutsToUpdateMap.get(Id.valueOf(payoutId)).add(Id.valueOf(pointId));
                }
            }

            payouts = PayoutService.changeStatusPayouts(payoutsToUpdateMap, status);
        }

        FieloPLT.Payouts.validateAdminFields = true;

        return (Object) new Map<String, Object>{
            'result' => payouts.size() > 0 ? 'OK' : 'NOK',
            'payouts' => payouts
        };
    }

    @AuraEnabled
    public static void checkBehaviorStatus(Id recordId) {
        List<RuleTrigger__c> behavior = new RuleTriggersSelector(
            new Set<String>{
                'FieloPLT__GenerateTrigger__c',
                'FieloPLT__LookupFromTransaction__c',
                'FieloPLT__LookupFromTracker__c',
                'FieloPLT__LookupFromPoint__c',
                'FieloPLT__LookupFromEmailAlert__c',
                'FieloPLT__DeploymentStatus__c'
            }).selectById(new Set<Id>{recordId}
        );

        if (behavior.get(0).GenerateTrigger__c) {
            MetadataService.checkDeploymentStatus(recordId);
        } else {
            Boolean deployDone = true;
            if (String.isNotBlank(behavior.get(0).LookupFromTransaction__c)) {
                Map<String, Schema.SObjectField> transactionFields = ((sObject)Type.forName('FieloPLT__Transaction__c').newInstance()).getSObjectType().getDescribe().fields.getMap();
                if (!transactionFields.containsKey(behavior.get(0).LookupFromTransaction__c)) {
                    deployDone = false;
                }
                if (String.isNotBlank(behavior.get(0).LookupFrompoint__c)) {
                    Map<String, Schema.SObjectField> pointFields = ((sObject)Type.forName('FieloPLT__Point__c').newInstance()).getSObjectType().getDescribe().fields.getMap();
                    if (!pointFields.containsKey(behavior.get(0).LookupFrompoint__c)) {
                        deployDone = false;
                    }
                }
            }
            if (String.isNotBlank(behavior.get(0).LookupFromtracker__c)) {
                Map<String, Schema.SObjectField> trackerFields = ((sObject)Type.forName('FieloPLT__Tracker__c').newInstance()).getSObjectType().getDescribe().fields.getMap();
                if (!trackerFields.containsKey(behavior.get(0).LookupFromtracker__c)) {
                    deployDone = false;
                }
                if (String.isNotBlank(behavior.get(0).LookupFrompoint__c)) {
                    Map<String, Schema.SObjectField> pointFields = ((sObject)Type.forName('FieloPLT__Point__c').newInstance()).getSObjectType().getDescribe().fields.getMap();
                    if (!pointFields.containsKey(behavior.get(0).LookupFrompoint__c)) {
                        deployDone = false;
                    }
                }
            }
            if (String.isNotBlank(behavior.get(0).LookupFromemailalert__c)) {
                Map<String, Schema.SObjectField> emailalertFields = ((sObject)Type.forName('FieloPLT__EmailAlert__c').newInstance()).getSObjectType().getDescribe().fields.getMap();
                if (!emailalertFields.containsKey(behavior.get(0).LookupFromemailalert__c)) {
                    deployDone = false;
                }
            }

            String behaviorStatus = '';
            if (deployDone) {
                behaviorStatus = 'Active';
            } else {
                behaviorStatus = 'Inactive';
            }
            // Change Status to active
            RuleTrigger__c rt = new RuleTrigger__c(
                Id = behavior.get(0).Id,
                DeploymentStatus__c = behaviorStatus == 'Active' ? 'Success' : behavior.get(0).DeploymentStatus__c,
                Status__c = behaviorStatus
            );
            update rt;
        }
    }

    @AuraEnabled
    public static String getOrgCurrency() {
        ConnectApi.OrganizationSettings orgSettings = ConnectApi.Organization.getSettings();
        //Check if multi-currency is enabled
        if(orgSettings.features.multiCurrency){
            try{
                SObject corporateCurrency = Database.query('SELECT ISOCode FROM CurrencyType WHERE IsActive=TRUE and IsCorporate=TRUE LIMIT 1');
                return String.valueOf(corporateCurrency.get('ISOCode'));
            } catch(Exception e){

            }
        }
        return String.valueOf(orgSettings.features.defaultCurrencyIsoCode);
    }

    @AuraEnabled
    public static string getObjectNameByRecordId(Id recordId){
        return String.valueOf(recordID.getSObjectType().getDescribe().getName());
    }

    @AuraEnabled
	public static String saveEarmark(Earmark__c record, String incentives){
        Savepoint sp;
        Map<Id, String> recordChallenges = new Map<Id, String>();
        Map<Id, String> recordPromotions = new Map<Id, String>();

        if(!((List<Object>)JSON.deserializeUntyped(incentives)).isEmpty()){
            for(Object o : (List<Object>) JSON.deserializeUntyped(incentives)){
                Map<String, Object> incentive = (Map<String, Object>) o;

                String incentiveType = String.valueOf(incentive.get('type'));
                String rulesIds ='';
                List<Object> items = (List<Object>) incentive.get('items');
                if(items != null){
                    for (Object item : items){
                        Map<String, Object> itemMap = (Map<String, Object>) item;
                        if(itemMap != null){
                            rulesIds += String.valueOf(itemMap.get('value'))+';';
                        }
                    }
                }

                if (String.isEmpty(rulesIds)){
                    rulesIds = null;
                }
                if(incentiveType == 'Promotion'){
                    recordPromotions.put(Id.valueOf((String) incentive.get('id')), rulesIds);
                } else {
                    recordChallenges.put(Id.valueOf((String) incentive.get('id')), rulesIds);
                }
            }
        } else {
            throw new FieloException(Label.AllocateOneIncentive);
        }
        sp = Database.setSavepoint();
        String result = null;
        try{
            EarmarkService.createUpdateEarmarks(record, recordChallenges, recordPromotions);
            result = record.Id;
        }catch (DmlException e) {
            system.debug(e.getDMLMessage(0));
            Database.rollback(sp);
            if( Test.isRunningTest() ){
                throw new FieloException(e.getDMLMessage(0));
            }
            throw new AuraHandledException(e.getDMLMessage(0));
        } catch(Exception e){
            system.debug(e.getMessage());
            Database.rollback(sp);
            if( Test.isRunningTest() ){
                throw new FieloException(e.getMessage());
            }
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static Object getMissionSummary(String missionId) {
        if (missionId == null)
            throw new FieloException('Null mission id');
        if (missionId != null && Id.valueOf(missionId).getSobjectType().getDescribe().getName() != 'FieloPLT__Mission__c')
            throw new FieloException('The provided id is not from a mission');

        List<Mission__c> missions = new MissionsSelector(new Set<String>{
            'FieloPLT__Action__r.FieloPLT__RuleTrigger__r.FieloPLT__Object__c',
            'FieloPLT__ObjectiveType__c',
            'FieloPLT__ObjectiveValue__c',
            'FieloPLT__ObjectiveField__c',
            'FieloPLT__FieldToAggregate__c',
            'FieloPLT__ValueMode__c',
            'FieloPLT__Operator__c'
        }).selectById(new Set<Id>{Id.valueOf(missionId)});

        Map<String, Object> result = new Map<String, Object>();
        if (!missions.isEmpty()) {
            Mission__c m = missions.get(0);

            DescribeSObjectResult objectDescribe = ((sObject)Type.forName(m.Action__r.RuleTrigger__r.Object__c).newInstance()).getSObjectType().getDescribe();

            String fieldLabel;
            Boolean isCurrency = false;
            if (String.isNotBlank(m.FieldToAggregate__c)) {
                fieldLabel = objectDescribe.fields.getMap().get(m.FieldToAggregate__c).getDescribe().getLabel();
                isCurrency = objectDescribe.fields.getMap().get(m.FieldToAggregate__c).getDescribe().getType().name().toLowerCase() == 'currency';

                if (!fieldLabel.startsWith(objectDescribe.getLabel())) {
                    fieldLabel = objectDescribe.getLabel() + ' ' + fieldLabel;
                }
            }

            String aggregation = m.ObjectiveType__c == 'Counter' ?
                String.format('{0} {1}', new List<String>{Label.Count, objectDescribe.getLabelPlural()}) :
                String.format('{0} ({1})', new List<String>{Label.SumUp, fieldLabel});
            result.put('aggregationLabel', (Object) Label.Aggregation);
            result.put('aggregationValue', (Object) aggregation);

            if (String.isNotBlank(m.ValueMode__c) ) {
                result.put('objectiveLabel', (Object) Label.Objective);
                switch on m.ValueMode__c.toLowerCase() {
                    when 'fixed' {
                        result.put('objectiveValue', (Object) (m.Operator__c + ' ' + (isCurrency ? '$' : '') + m.ObjectiveValue__c));
                    }
                    when 'dynamic' {
                        result.put('objectiveValue', (Object) (m.Operator__c + ' ' + getPathLabel('FieloPLT__Member__c', m.ObjectiveField__c)));
                    }
                    when 'historicaldata' {
                        result.put('objectiveValue', (Object) (m.Operator__c + ' ' + m.ObjectiveValue__c + '%'));
                    }
                }
            }
        }

        return (Object) result;
    }

    @AuraEnabled
    public static Object saveChallengeRewardsWithParent(sObject record, String lookupField, List<sObject> relatedRecords, List<String> deletedRecords) {
        try{
            if( record == null ){
                throw new FieloException('Record: invalid parameter.');
            }
            sObjectUnitOfWork uow;
            sObjectField sField;
            if(lookupField == 'FieloPLT__Mission__c') {
                uow = new sObjectUnitOfWork(
                    new List<Schema.SObjectType>{
                        Mission__c.SObjectType,
                        ChallengeReward__c.SObjectType
                    }
                );
                sField = ChallengeReward__c.Mission__c;
            } else {
                uow = new sObjectUnitOfWork(
                    new List<Schema.SObjectType>{
                        Challenge__c.SObjectType,
                        ChallengeReward__c.SObjectType
                    }
                );
                sField = ChallengeReward__c.Challenge__c;
            }

            uow.registerDirty(record);

            for(sObject relatedRecord : relatedRecords) {
                if (relatedRecord.Id != null) {
                    uow.registerDirty(relatedRecord);
                } else {
                    uow.registerNew(relatedRecord, sField, record);
                }
            }

            if (deletedRecords != null && !deletedRecords.isEmpty()) {
                uow.registerDeleted([SELECT Id FROM ChallengeReward__c WHERE Id IN :deletedRecords]);
            }

            uow.commitWork();

            return record;
        } catch(DmlException e) {
            throw new AuraHandledException(e.getDmlMessage(0));
        }
    }

    @AuraEnabled(cacheable=true)
    public static Object getWiredObjectFields(String objectName, Boolean customOnly) {
        try{
            Schema.DescribeSObjectResult objDescribe = ((sObject)Type.forName(objectName).newInstance()).getSObjectType().getDescribe();
            Set<String> fields = new Set<String>();

            if (customOnly != null && customOnly == true) {
                fields.add('Id');
                for(String f : objDescribe.fields.getMap().keySet()) {
                    if (f.endsWith('__c')) {
                        fields.add(f);
                    }
                }
            } else {
                fields = objDescribe.fields.getMap().keySet();
            }

            return (Object) new List<String>(fields);
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    private static Map<String, String> getStatusLabelForTeam(){
        Map<String, String> mapStatus = new Map<String, String>();
        Schema.DescribeSObjectResult objectDescribe = ((sObject)Type.forName('FieloPLT__Member__c').newInstance()).getSObjectType().getDescribe();
        if( objectDescribe.fields.getMap().containskey('FieloPLT__Status__c')) {
            for( Schema.PicklistEntry entry : objectDescribe.fields.getMap().get('FieloPLT__Status__c').getDescribe().getPicklistValues() ){
                if( entry.isActive() && entry.getValue() == 'Active'){
                    mapStatus.put('Active', entry.getLabel());
                }else if(entry.isActive() && entry.getValue() == 'Inactive'){
                    mapStatus.put('Inactive', entry.getLabel());
                }else if(entry.isActive() && entry.getValue() == 'Draft'){
                    mapStatus.put('Draft', entry.getLabel());
                }
            }
        }
        return mapStatus;
    }

    @AuraEnabled
    public static void enableAuditPoints(Id behaviorId){
        try{
            SObjectUnitOfWork uow = new SObjectUnitOfWork(new List<Schema.SObjectType>{RuleTrigger__c.SObjectType});

            FieloPLT__RuleTrigger__c behavior = Database.query('SELECT Id, FieloPLT__Object__c, FieloPLT__LookupFromTransaction__c, FieloPLT__LookupFromTracker__c, FieloPLT__LookupFromPoint__c FROM FieloPLT__RuleTrigger__c WHERE Id = :behaviorId LIMIT 1');

            if(behavior != null){
                behavior.LookupFromPoint__c = String.isNotBlank(behavior.LookupFromTransaction__c) ?
                        behavior.LookupFromTransaction__c :
                        String.isNotBlank(behavior.LookupFromTracker__c) ?
                                behavior.LookupFromTracker__c :
                                null;
                if (String.isNotBlank(behavior.LookupFromPoint__c)) {
                    uow.registerDirty(behavior);
                    uow.commitWork();
                }

                MetadataService.createBehaviorField(behaviorId, 'FieloPLT__LookupFromPoint__c');
            }
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String activateFundRewarding(){
        String creationResult;
        try{
            creationResult = (MetadataService.createFundRewardingFields());
            if(creationResult == Label.FundsRewardingActive){
                MetadataService.createFutureFundRewardingFields();
            }
        }catch(Exception e){
            creationResult =  e.getMessage();
        }
        return creationResult;
    }

    @AuraEnabled
    public static Boolean isFundsActive(){
        try {
            return PublicSettings__c.getOrgDefaults().FieloPLT__ActiveFund__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }*/
}