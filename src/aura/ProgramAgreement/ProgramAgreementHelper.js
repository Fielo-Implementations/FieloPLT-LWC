({
    getAgreement: function(component, event, helper){    		
        var isRegistration = component.get('v.registration');
        var member = component.get('v.member');
        var programId = component.get('v.program');        
        if(programId){
            var programAgreement = component.get("c.getProgramAgreement");
            programAgreement.setParams({
                "member": member,
                "programId": programId
            })            
            // Add callback behavior for when response is received
            programAgreement.setCallback(this, function(response) {
                var state = response.getState();        
                var toastEvent = $A.get("e.force:showToast");
                if (component.isValid() && state === "SUCCESS") {                    
                    var agreement = response.getReturnValue();
                    var hasAgreementEvent = component.getEvent("hasAgreement");                    
                    if(agreement){
                        component.set('v.agreement', agreement);                        
                        if(isRegistration){
                            if(hasAgreementEvent){
                                hasAgreementEvent.setParams({"agreement" : agreement });    
                            }
                        }else{                            
                            component.set('v.showAgreement', true);                            
                        }
                    }
                    if(hasAgreementEvent && isRegistration){                        
                        hasAgreementEvent.fire();
                    }
                    
                } else {
                    var errorMsg = response.getError()[0].message;
                    toastEvent.setParams({
                        "title": errorMsg,
                        "message": " ",
                        "type": "error"
                    });
                    toastEvent.fire();                     
                }         
            });            
            // Send action off to be executed
            
            $A.enqueueAction(programAgreement);
        }        
    },
    submitAgreement : function(component, event, helper) {
        var member = component.get('v.member');
        var agreement = component.get('v.agreement');
        if(member && agreement){
            var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
            if(spinner){
                spinner.setParam('show', true);
                spinner.fire();    
            }                
            var submitAgreement = component.get("c.submitNewAgreement");
            submitAgreement.setParams({
                "member": member,
                "agreementId": agreement.Id
            })
            
            // Add callback behavior for when response is received
            submitAgreement.setCallback(this, function(response) {
                var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
                var state = response.getState();        
                var toastEvent = $A.get("e.force:showToast");                
                if (component.isValid() && state === "SUCCESS") {                    
                    component.set('v.showAgreement', false);                      
                } else {
                    var errorMsg = response.getError()[0].message;
                    toastEvent.setParams({
                        "title": errorMsg,
                        "message": " ",
                        "type": "error"
                    });
                    toastEvent.fire();                     
                }         
                if(spinner){
                    spinner.setParam('show', false);
                    spinner.fire();    
                }                                 
            });            
            // Send action off to be executed
            
            $A.enqueueAction(submitAgreement);         
        }
    }
})