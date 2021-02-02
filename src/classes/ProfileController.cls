public class ProfileController {
    @auraEnabled
    public static List<FieloPLT__Member__c> getMember(String fieldset, String memberId){
        try{
        	String userId = UserInfo.getUserId();
        	return database.query('SELECT ' + fieldset + ' FROM FieloPLT__Member__c WHERE Id =: memberId');
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @auraEnabled
    public static map<String, String> getFieldLabels(){
        map<String, String> mapFieldLabels = new map<String, String>();

        for(Schema.SObjectField sfield: Member__c.sObjectType.getDescribe().fields.getMap().Values()){
            Schema.Describefieldresult dfield = sfield.getDescribe();
            mapFieldLabels.put(dfield.getName(), dfield.getLabel());
        }

        return mapFieldLabels;
    }

    @auraEnabled
    public static String saveMemberInfo(FieloPLT__Member__c member, String folderId, String fileName, String photoBase64){
        Savepoint sp;
        try{
            // HAY QUE HACER EL INSERT DEL DOCUMENT Y USAR ESE ID PARA CONSTRUIR LA URL PARA EL CAMPO EXTERNALURL               
            sp = Database.setSavepoint();

            if (String.isNotBlank(fileName) && String.isNotBlank(photoBase64)) {                
                Document currentDocument = new Document();
                if(!String.isBlank(photoBase64)) {
                    Integer firstComma = photoBase64.indexOf(',');
                    photoBase64 = photoBase64.substring(firstComma + 1, photoBase64.length() - 1);
                    currentDocument.put('Body', EncodingUtil.Base64Decode(photoBase64));
                }

                currentDocument.put('Name', fileName);            
                currentDocument.put('FolderId', folderId);
                currentDocument.put('IsPublic', true);

                insert currentDocument;

                member.put('FieloPLT__Image__c', currentDocument.Id);
                member.put('FieloPLT__ExternalURL__c', createURL(currentDocument));
            }
        	upsert member;
            return 'Success';
        } catch(DMLException e) {
            Database.rollback(sp);
            throw new AuraHandledException(e.getDMLMessage(0));
        } catch(Exception e){
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage());
        }
    }

    @auraEnabled
    public static String getFields(String objectName, String fieldNames){
        try{
            DescribeSObjectResult redemptionsDescribe = ((sObject)Type.forName('FieloPLT__Redemption__c').newInstance()).getSObjectType().getDescribe();
            DescribeSObjectResult transactionsDescribe = ((sObject)Type.forName('FieloPLT__Transaction__c').newInstance()).getSObjectType().getDescribe();
            DescribeSObjectResult badgesDescribe = ((sObject)Type.forName('FieloPLT__Badge__c').newInstance()).getSObjectType().getDescribe();
            DescribeSObjectResult payoutsDescribe = ((sObject)Type.forName('FieloPLT__Payout__c').newInstance()).getSObjectType().getDescribe();

            String fields = AuraService.getFieldData(objectName, fieldNames, true);                        
            Map<String, String> objectInfo = new Map<String, String>();            
            objectInfo.put('redemptionsLabel', redemptionsDescribe.getLabelPlural());
            objectInfo.put('transactionsLabel', transactionsDescribe.getLabelPlural());
            objectInfo.put('badgesLabel', badgesDescribe.getLabelPlural());
            objectInfo.put('payoutsLabel', payoutsDescribe.getLabelPlural());
            objectInfo.put('fields', fields);
            return JSON.serialize(objectInfo);            
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
    }    

    public static String createURL(Document imageRecord){
        String url;        
        url = '/servlet/servlet.ImageServer?id=' + (String)imageRecord.Id + '&oid=' + UserInfo.getOrganizationId();
        if(imageRecord.get('LastModifiedDate') != null) {
            url += '&LastModifiedDate=' + String.valueOf(imageRecord.get('LastModifiedDate')).deleteWhitespace();
        }
        return url;
    }
    
}