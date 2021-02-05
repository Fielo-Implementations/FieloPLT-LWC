global class CommunityRegistrationController {
    
    public CommunityRegistrationController() {
        
    }
    
    @TestVisible 
    private static boolean isValidPassword(String password, String confirmPassword) {
        return password == confirmPassword;
    }
    
    
    @TestVisible 
    private static void validatePassword(User u, String password, String confirmPassword) {
        if(!Test.isRunningTest()) {
            Site.validatePassword(u, password, confirmPassword);
        }
        return;
    }
    
    @AuraEnabled
    public static string selfRegister(String fields, Boolean includePassword, String password, String confirmPassword, String regConfirmUrl, String startUrl, Map<Id, Boolean> consents) {
        Savepoint sp = null;
        try {
            sp = Database.setSavepoint();            
            Map<String,Object> fieldset = (Map<String, Object>) JSON.deserializeUntyped(fields);            
            String firstname = (String) fieldset.get('Name');            
            String lastname = (String) fieldset.get('LastName');
            String email = (String) fieldset.get('FieloPLT__Email__c'); 
            String accountId = (String) fieldset.get('FieloPLT__Account__c');  

            fieldset.remove('LastName');
            
            User u = new User();
            u.Username = email;
            u.put('Email',email);
            
            u.FirstName = firstname;
            u.LastName = lastname;
            
            String networkId = Network.getNetworkId();
            
            // If using site to host the community the user should not hit s1 after logging in from mobile.
            if(networkId != null ) {
                u.put('UserPreferencesHideS1BrowserUI',true);
            }
            
            String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0,1) : '' ) + lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            u.put('CommunityNickname', nickname);                                               
            
            if (includePassword) {
                if (!isValidPassword(password, confirmPassword)) {
                    throw new FieloPLT.FieloException(Label.site.passwords_dont_match);
                }
                validatePassword(u, password, confirmPassword);
            }
            else {
                password = null;
            }
            if(userExists(email)){
                throw new FieloPLT.FieloException('There is already an user with this username. Please, use another e-mail');
            }
            // lastName is a required field on user, but if it isn't specified, we'll default it to the username
            
            FieloPLT__Member__c member = createMemberPortal(u, accountId, password, fieldset);
            /*
            if (!consents.isEmpty()) {
                sObjectService.setConsents(member.Id, consents);
            }*/       
            
            //Commented to allow success message delay
            if (password != null && password.length() > 1) {
                ApexPages.PageReference lgn = Site.login(email, password, startUrl);
                //if(!System.Test.isRunningTest())
                    //aura.redirect(lgn);
            }
            
            return 'Registration Successful';
        }catch (DmlException ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getDmlMessage(0));           
        }catch(Exception e){
            Database.rollback(sp);
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    public static FieloPLT__Member__c createMemberPortal(User u, String accountId, String password, Map<String,Object> fieldset){
        String userId = Site.createPortalUser(u, accountId, password);    
        FieloPLT__Member__c member = new FieloPLT__Member__c();                
        fieldset.put('Name', u.FirstName + ' ' + u.LastName);
        fieldset.put('FieloPLT__User__c', userId);
        for(String field : fieldset.keySet()){                    
            member.put(field, fieldset.get(field));
        }            
        member.FieloPLT__Type__c = 'Individual Account';            
        
        insert member;
        return member;
    }

    public static List<SObject> queryCommunitySuffix(Id networkId){
        return Database.query('SELECT Id, urlPathPrefix FROM Network WHERE Id=: networkId LIMIT 1');
    }

    public static Boolean userExists(string userName){
        List<User> existingUser = [Select Id FROM User WHERE Username =: userName];
        return existingUser.size() > 0 ? true : false;
    }
    
    @auraEnabled
    public static String communityLogin(String email, String password){
        try {
            ApexPages.PageReference lgn = Site.login(email, password, '');
            aura.redirect(lgn);
            return null;
        } catch (Exception ex) {            
            return ex.getMessage();
        }
    }
    
    @auraEnabled
    public static FieloPLT__Agreement__c getProgramAgreement(Id programId){
        Set<String> fieldset = new Set<String>{'FieloPLT__Agreement__c', 'FieloPLT__Status__c', 'Name'};
        try{
            FieloPLT__Agreement__c programAgreement = FieloPLT.AgreementService.getCurrentAgreement(programId, fieldset);
            return programAgreement;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }    
    
    @auraEnabled
    public static map<String, String> getFieldLabels(){
        map<String, String> mapFieldLabels = new map<String, String>();
        
        for(Schema.SObjectField sfield: FieloPLT__Member__c.sObjectType.getDescribe().fields.getMap().Values()){
            Schema.Describefieldresult dfield = sfield.getDescribe();
            mapFieldLabels.put(dfield.getName(), dfield.getLabel());
        }
        
        return mapFieldLabels;
    }
    
    @auraEnabled
    public static String getFields(String objectName, String fieldNames){
        try{        
            String fields = Fielo_AuraService.getFieldData(objectName, fieldNames, true);			
            return  fields;
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }        
    }
        // Code used by communities
    @AuraEnabled
    public static String getCommunitySuffix(){
        return getSuffix();
    }

    public static String getSuffix(){
        String pref = '';
        if(Network.getNetworkId() != null){
            Id networkId = Id.valueOf(Network.getNetworkId());
            try{
                List<Sobject> lst = queryCommunitySuffix(networkId);
                if(!lst.isEmpty()){
                    pref = (String) (lst.get(0)).get('urlPathPrefix');
                }
            }catch(QueryException e){
                throw new FieloPLT.FieloException('Unable To Perfom Query' + ' ' + e.getMessage());
            }
        }
        return pref;
    }
}