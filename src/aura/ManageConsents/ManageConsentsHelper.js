({
	getValues: function(component, event, helper){
        var data = {};
		var inputs = component.find('consentInput');
        if (inputs) {
            if (inputs.length) {
                inputs.forEach(function(field){
                    var value = field.getValue();				
                    data[value.fieldName] = value.value;
                });            
            } else {            
                var value = inputs.getValue();                
                data[value.fieldName] = value.value;
            }
        }
		return data;
	},
    submit : function(component, event, helper) {
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");		
        var recordId = component.get('v.recordId');        
        if (recordId) {
            if (spinner) {
                spinner.setParam('show', true);
                spinner.fire();
            }
            var data = this.getValues(component, event, helper);            
            var action = component.get('c.saveConsents');            
            action.setParams({				
                'recordId': recordId,
                'consents': data
            });
            action.setCallback(this, function (response) {
                var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");		
                var toastEvent = $A.get("e.force:showToast");
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {					
                    var response = response.getReturnValue();
                    if (response == 'success') {
                        component.set('v.show', false);   
                    }                    
                    toastEvent.setParams({
                        "title": "Data succesfully saved",
                        "message": " ",
                        "type": "success"
                    });
                    toastEvent.fire();
                } else {
                    var errorMsg = response.getError()[0].message;
                    toastEvent.setParams({
                        "title": errorMsg,
                        "message": " ",
                        "type": "error"
                    });
                    toastEvent.fire();
                }
                if (spinner) {
                    spinner.setParam('show', false);
                    spinner.fire();
                }
            });
            // Send action off to be executed
            $A.enqueueAction(action);
        }
    },
    getConsents : function(component, memberId, action) {
        component.set('v.recordId', memberId);
        
        if (memberId) {
            action.setParams({
                'recordId': memberId
            });
            action.setCallback(this, function (response) {
                if (component.isValid() && response.getState() === "SUCCESS") {					
                    var consents = JSON.parse(response.getReturnValue());
				
                    component.set('v.consents', consents);					
                    var consentsEvent = component.getEvent("manageConsentsEvent");
    
                    if (consentsEvent) {
                        consentsEvent.setParams({"hasConsents": consents.length > 0});
                        consentsEvent.fire();
                    }
                } else {
                    var toastEvent = $A.get("e.force:showToast");
                    var errorMsg = response.getError()[0].message;
                    toastEvent.setParams({
                        "title": errorMsg,
                        "message": " ",
                        "type": "error"
                    });
                    toastEvent.fire();
                }
            });
            $A.enqueueAction(action);
        }
    }
})