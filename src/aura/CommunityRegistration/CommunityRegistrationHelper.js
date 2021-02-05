({
    fields: {
        
    },
    labels: {
        
    },
    communityUrl:'',
    getExtraFields: function(component, event, helper) {        
        var defaultFieldset = JSON.parse(component.get('v.defaultFieldset'));
        var fieldset = [];
        var fields = JSON.parse(component.get('v.defaultFields'));
        var fieldsConfig = component.get('v.fields').trim();        
        
        fieldsConfig = fieldsConfig.length > 0 ? fieldsConfig.split(',') : [];
        fieldsConfig.forEach(function(field){
            var nameAndRequired = field.split('/');
            nameAndRequired[0] = nameAndRequired[0].trim(); 
            fields[nameAndRequired[0]] = true;            
            var newField = {
                'apiName': nameAndRequired[0],
                'required': nameAndRequired[1] ? true : false
            }            
            fieldset.push(newField);
        });                
        fieldset = defaultFieldset.concat(fieldset);
        
        var requiredFields = [];
        fieldset.forEach(function(field){
            if(field.required){
                requiredFields.push(field.apiName);
            }
        })            
        component.set('v.requiredFields', requiredFields);
        //component.set('v.fieldset', fieldset);
        var objectName = 'Member__c';
        var fieldsAction = component.get('c.getFields');
        fieldsAction.setParams({
            'objectName': objectName,
            'fieldNames': Object.keys(fields).join(',')
        });        
        // Add callback behavior for when response is received
        fieldsAction.setCallback(this, function(response) {
            var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
            var state = response.getState();                          
            if (component.isValid() && state === "SUCCESS") {
                //success
                var extraFields = response.getReturnValue();
                var fields = JSON.parse(extraFields).fields;
                var newFieldset = [];                
                fields.forEach(function(field){
                    if (field.attributes.name == 'Name') {
                        field.attributes.label = helper.labels.FirstName;
                        field.attributes.required = true;
                    } else if (field.attributes.name == 'FieloPLT__Email__c') {
                        field.attributes.required = true;                        
                        component.set('v.emailLabel', field.attributes.label);
                    }
                    helper.fields[field.attributes.name] = field;
                });                
                fieldset.forEach(function(field){
                    var fieldValue;                    
                    if (field.apiName == 'LastName') {
                        fieldValue = {
                            "attributes": {
                                "inputType": "text",
                                "name": "LastName",
                                "label": helper.labels.LastName,
                                "required": true
                            }                            
                        }
                    } else {
                        fieldValue = helper.fields[field.apiName];
                        if(fieldValue){
                            fieldValue.attributes.required = field.required;    
                        }                                    
                    }
                    field = fieldValue;                                                                
                    newFieldset.push(field);
                });
                
                newFieldset.forEach(function(field){
                    if (field){
                        if ( field.attributes.isNillable=='true'){
                            field.attributes.required = false
                        }else{
                            field.attributes.required = true
                        }
                    }
                })

                component.set('v.extraFields', newFieldset);
            } else {
                var errorMsg = response.getError()[0].message;                
                var inlineToast = component.find('inlineToast');
                if (inlineToast) {
                    inlineToast.showToast({                        
                        "title": errorMsg,
                        "variant": "error",
                        "mode": "pester"
                    })
                }
            }
            if(spinner){
                spinner.setParam('show', false);
                spinner.fire();
            }
        });
        // Send action off to be executed
        $A.enqueueAction(fieldsAction);
    },    
    handleSelfRegister: function (component, event, helper) {        
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        if(spinner){
            spinner.setParam('show', true);
            spinner.fire();    
        }        
        var regConfirmUrl = component.get("v.regConfirmUrl");
        if (regConfirmUrl.startsWith('./')) {
            regConfirmUrl = regConfirmUrl.substr(2);
        }

        var startUrl = component.get('v.startUrl');
        
        var includePassword = component.get("v.includePasswordField");
        var password = component.get("v.password");
        var confirmPassword = component.get("v.confirmPassword");
        
        var action = component.get("c.selfRegister");
        
        var programId = component.get('v.program');        
        var extraFields = component.get('v.extraFieldsValues');        
        extraFields.FieloPLT__Program__c = programId;
        
        var agreement = component.get('v.agreement');        
        if(agreement){
            extraFields.FieloPLT__Agreement__c = agreement.Id;
        }
        var consentComponent = component.find('consents');
        var consents = {};
        if (consentComponent) {
            var consents = consentComponent.getConsentsValues();
        }

        action.setParams({
            fields: JSON.stringify(extraFields),
            includePassword:includePassword,
            password:password,
            confirmPassword:confirmPassword,
            regConfirmUrl:regConfirmUrl,
            startUrl: startUrl,
            consents: consents
        });          
        action.setCallback(this, function(response){
            var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");            
            if(spinner){
                spinner.setParam('show', false);
                spinner.fire();    
            }
            let variant, mode, title; 
            if( response.getState() == "SUCCESS" ) { 
                variant = "success";
                mode = "paster"; 
                title = response.getReturnValue(); 
                //To delay success message
                if(password){
                    window.setTimeout(
                        $A.getCallback(function(){
                            var login = component.get("c.communityLogin");
                            login.setParams({
                                email:extraFields['FieloPLT__Email__c'],
                                password:password
                            });
                            $A.enqueueAction(login);
                        }.bind(this)), 1500
                    );
                }else if(regConfirmUrl) {
                    window.setTimeout(
                        $A.getCallback(function() {
                            var urlEvent = $A.get("e.force:navigateToURL");
                            urlEvent.setParams({
                                "url": this.communityUrl + regConfirmUrl
                            });
                            urlEvent.fire();
                        }.bind(this)), 1500
                    );
                }            
            }else{
                variant = "error";   
                mode = "paster";           
                title = response.getError()[0].message;                
                component.set('v.agreementCheked', false);
                component.set('v.showAgreement', false);
            }

            var inlineToast = component.find('inlineToast');
            if(inlineToast) {
                inlineToast.showToast({title, variant, mode});
            }
        });
        $A.enqueueAction(action);
    },
    checkRequired: function(component, event, helper){
        var requiredFields = component.get('v.requiredFields');        
        var extraFields = component.get('v.extraFieldsValues');
        var res = true;
        requiredFields.forEach(function(field){
            if(!extraFields[field] || extraFields[field] == ''){
                res = false;
            }
        })
        return res;
    }
})