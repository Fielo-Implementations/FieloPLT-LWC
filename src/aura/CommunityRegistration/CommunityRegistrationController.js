({
    doInit: function(component, event, helper) {        
        var title;
        var getSuffix = component.get("c.getCommunitySuffix");
        // Add callback behavior for when response is received
        getSuffix.setCallback(this, function (response) {
            helper.communityUrl = location.protocol + '//' + location.hostname + '/';
            if (component.isValid() && response.getState() === "SUCCESS") {
                //success
                if (response.getReturnValue()) {
                    helper.communityUrl += response.getReturnValue() + '/s/'
                } else {
                    helper.communityUrl += 's/'
                }
            } else {
                helper.communityUrl += 's/'
            }
        });
        // Send action off to be executed
        $A.enqueueAction(getSuffix);
        try{
            helper.labels.FirstName = $A.get('$FieloPLT.Label.FirstName');
            helper.labels.LastName = $A.get('$FieloPLT.Label.LastName');
            // TITLE REGISTRATION
            var titleValue = component.get('v.titleValueRegistration').trim();
            if(titleValue.length > 0){                    
                if (titleValue.indexOf('{') == 0) {
                    title = JSON.parse(titleValue);
                } else {
                    title = {
                        "value": titleValue,
                        "type": "text"
                    };
                }
            }
            if(title){
                titleValue = '';
                var type = title.type.toLowerCase();
                var value = title.value;
                if(type == 'label'){
                    var label = '$FieloPLT.Label.' + value;
                    titleValue = $A.get(label);                
                }else{
                    titleValue = value;                
                }                              
                component.set('v.titleRegistration', titleValue);                    
            }
            
            // TITLE LOGIN
            var titleValue = component.get('v.titleValueLogin').trim();
            if(titleValue.length > 0){                    
                if (titleValue.indexOf('{') == 0) {
                    title = JSON.parse(titleValue);
                } else {
                    title = {
                        "value": titleValue,
                        "type": "text"
                    };
                }
            }
            if(title){
                titleValue = '';
                var type = title.type.toLowerCase();
                var value = title.value;
                if(type == 'label'){
                    var label = '$FieloPLT.Label.' + value;
                    titleValue = $A.get(label);                
                }else{
                    titleValue = value;                
                }                    
                component.set('v.titleLogin', titleValue);                    
            }
            
            
            
            var programId = component.get('v.program');
            var agreementCmp = component.find("programAgreement");
            agreementCmp.updateProgram(programId);
            component.set('v.programId', programId);
            component.set('v.showConsents', true);
            helper.getExtraFields(component, event, helper);
        } catch(e) {
            component.set('v.error', e);
            component.set('v.showError', true);
        }        
    },    
    handleSelfRegister: function (component, event, helper) {        
        var hasAgreement = component.get('v.hasAgreement');
        var agreementChecked = component.get('v.agreementChecked');
        
        var includePassword = component.get("v.includePasswordField");
        var password = component.get("v.password");
        var confirmPassword = component.get("v.confirmPassword");

        var extraFields = component.find('extraField');
        var extraFieldValues = {};
        extraFields.forEach(function(field){
            var value = field.getValue();            
            extraFieldValues[value.fieldName] = value.value;
        })        
        component.set('v.extraFieldsValues', extraFieldValues);
        if(helper.checkRequired(component) && ((includePassword && password && confirmPassword) || !includePassword)){
            if ((hasAgreement && agreementChecked) || !hasAgreement) {
                helper.handleSelfRegister(component, event, helper);
            } else {
                var errorMsg = $A.get("$FieloPLT.Label.AgreementAccept");
                var inlineToast = component.find('inlineToast');
                if (inlineToast) {
                    inlineToast.showToast({                        
                        "title": errorMsg,
                        "variant": "error",
                        "mode": "pester"
                    })
                }
            }
        }else{
            var errorMsg = $A.get("$FieloPLT.CompleteRequiredFields");
            var inlineToast = component.find('inlineToast');
            if (inlineToast) {
                inlineToast.showToast({                    
                    "title": errorMsg,
                    "variant": "error",
                    "mode": "pester"                    
                })
            }
        }
        
    },
    showAgreement: function(component, event, helper){
        component.set('v.showAgreement', true);
    },
    submitAgreement: function(component, event, helper){
        var checked = event.getParam('checked');        
        component.set('v.agreementChecked', checked);            
        
    },
    toggleAgreement: function(component, event, helper){
        var agreement = event.getParam('agreement');
        component.set('v.agreement', agreement);
        var hasAgreement = agreement ? true : false;
        component.set('v.hasAgreement', hasAgreement);        
    },
    dismiss: function(component, event, helper){
        component.set('v.agreementChecked', false);
        component.set('v.showAgreement', false);
    },    
    handleLogin: function(component, event, helper){
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        if(spinner){
            spinner.setParam('show', true);
            spinner.fire();    
        }        
        var user = component.get('v.loginUser');
        var password = component.get('v.loginPassword');
        var action = component.get("c.communityLogin");        
        action.setParams({
            email: user,
            password: password            
        });
        action.setCallback(this, function(a){
            var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");            
            var rtnValue = a.getReturnValue();
            if(spinner){
                spinner.setParam('show', false);
                spinner.fire();    
            }
            if (rtnValue !== null) {                                
                var errorMsg = rtnValue;                
                var inlineToast = component.find('inlineToast');
                if (inlineToast) {
                    inlineToast.showToast({                        
                        "title": errorMsg,
                        "variant": "error",
                        "mode": "pester"
                    })
                }
            }
        });
        $A.enqueueAction(action);
    }

})