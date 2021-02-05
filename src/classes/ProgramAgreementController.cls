public with sharing class ProgramAgreementController {
    @auraEnabled
    public static FieloPLT__Agreement__c getProgramAgreement(FieloPLT__Member__c member, Id programId){
        try{                                    
            FieloPLT__Agreement__c programAgreement = FieloPLT.AgreementService.getCurrentAgreement(programId,null);
            return programAgreement;   
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }    
    @auraEnabled
    public static FieloPLT__Member__c submitNewAgreement(FieloPLT__Member__c member, Id agreementId){
        try{                                    
            member.FieloPLT__Agreement__c = agreementId;            
            FieloPLT.SObjectService.enableAdminPermission(true);
            update member;
            FieloPLT.SObjectService.enableAdminPermission(false);
            return member;     
        } catch(DMLException e) {
            throw new AuraHandledException(e.getDMLMessage(0));
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }    
}