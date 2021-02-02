public with sharing class RegistrationController {
    String labelValidEmail = Label.ValidEmail;
    
    @auraEnabled    
    public static List<FieloPLT__Program__c> getProgramsList(List<String> fields, List<Id> programIds, Integer quantity, Integer offset, String orderBy, String dynamicFilter){
        try{
            Set<String> fieldsSet = new Set<String>(fields);
            Set<Id> programIdsSet = new Set<Id>(programIds);
            List<FieloPLT__Program__c> result = FieloPLT.ProgramService.getPrograms(
                  fieldsSet,
                  programIdsSet.size() == 0 ? null : programIdsSet,
                  orderBy,
                  quantity,
                  offset,
                  dynamicFilter);
            return result;            
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    @auraEnabled
    public static FieloPLT__Member__c registerMember(Id programId, Id agreementId){
        try{             
            String userId = UserInfo.getUserId();
            String userName = UserInfo.getName();
            String userEmail = UserInfo.getUserEmail();
            Member__c member = new Member__c(Name = userName, Email__c = userEmail, Program__c = programId, User__c = userId, Type__c = 'Individual Account', Agreement__c = agreementId);
            Members.communityRegistration = false;
            insert member;
            Members.communityRegistration = true;
            return member;
        } catch(DMLException e) {
            throw new AuraHandledException(e.getDMLMessage(0));
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    @auraEnabled
    public static Program__c getProgramInfo(String fields, Id programId){
        try{
            Program__c programInfo = Database.query('SELECT ' + fields + ' FROM Program__c WHERE Id = \'' + programId + '\'');
            return programInfo;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @auraEnabled
    public static String getObjectData(){                
        try{                                                        
            return AuraService.getObjectData('FieloPLT__Program__c');            
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }                
        
    }
}