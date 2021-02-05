({
    agreement: function(component, event, helper){
        var params = event.getParam('arguments');
        if (params) {
            var program = params.program;
            component.set('v.program', program);
            helper.getAgreement(component, event, helper);
        }        
    },
    showAgreement : function(component, event, helper) {
        var showAgreement = component.get('v.showAgreement');
        component.set('v.showAgreementModal', false);
        component.set('v.agreementChecked', false);
        if(showAgreement){
            component.set('v.showAgreementModal', true);    
        }        
    },
    submit: function(component, event, helper){
        var toastEvent = $A.get("e.force:showToast");
        var checked = component.get('v.agreementChecked');
        var isRegistration = component.get('v.registration');
        if(checked){
            if(isRegistration){
                var checkEvent = component.getEvent("checkAgreement");
                checkEvent.setParams({"checked" : checked });
                checkEvent.fire();
                component.set('v.showAgreement', false);
            }else{
                helper.submitAgreement(component, event, helper);
            }
        }else{
            var errorMsg = $A.get("$FieloPLT.Label.c.AgreementAccept");
            toastEvent.setParams({
                "title": errorMsg,
                "message": " ",
                "type": "error"
            });
            toastEvent.fire();
        }
    },
    dismiss: function(component, event, helper){
        component.set('v.showAgreement', false);
    },
    updateMember: function(component, event, helper){
        var registration = component.get('v.registration');
        if(!registration){            
            var member = event.getParam('member');        
            component.set('v.member', member);
            component.set('v.program', member.FieloPLT__Program__c);
            helper.getAgreement(component, event, helper);
        }                   
    }
})