({
    hasImageField: false,
    defaultImage: '',
    programsContent: {

    },
    memberPrograms: {

    },
    availablePrograms: {

    },
    getPrograms: function(component, offset, isFilter) {
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        if (spinner) {
            spinner.setParam('show', true);
            spinner.fire();
        }        
        var memberPrograms = this.memberPrograms;
        var conditions = [];
        Object.keys(memberPrograms).forEach(function(programId){
            var newCondition = {
                "field": "Id",
                "value": programId,
                "operator": "not eq",
                "andOrOperator": "" 
            }
            conditions.push(newCondition);
        });
        var dynamicFilter = component.get('v.dynamicFilter');
        if (dynamicFilter && dynamicFilter.length > 0) {
            dynamicFilter = JSON.parse(dynamicFilter);
            dynamicFilter.forEach(function(item){
                conditions.push(item);
            })
        }
        
        var orderBy = component.get('v.orderBy') || null;
        var paging = component.get('v.paging');
        var quantity = component.get('v.quantity');
        if (paging) {
            quantity++;
        } else {
            quantity = null;
        }
        
        var fields = component.get('v.programFields');
        
        var action = component.get('c.getProgramsList');        
        action.setParams({
            'fields': fields.split(','),
            'programIds': Object.keys(this.availablePrograms),
            'quantity': quantity,
            'offset': offset,
            'orderBy': orderBy,
            'dynamicFilter': conditions.length > 0 ? JSON.stringify(conditions) : ''
        })
        
        action.setCallback(this, function(response) { 
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();            
            if (component.isValid() && state === "SUCCESS") {
                var programs = response.getReturnValue();                
                if(programs.length > 0 || isFilter){
                    if (this.hasImageField) {
                        programs.forEach(function(program){                            
                            if (!program.FieloPLT__ExternalURL__c) {
                                program.FieloPLT__ExternalURL__c = this.defaultImage;
                            }
                        }, this)            
                    }
                    component.set('v.programs', programs);
                    component.set('v.showRegistration', true);
                }else{
                    component.set('v.showRegistration', false);   
                }
            }else {
                var errorMsg = response.getError()[0].message;
                toastEvent.setParams({
                    "title": errorMsg,
                    "message": " ",
                    "type": "error"
                });
                toastEvent.fire();                     
            }
            var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
            if (spinner) {
                spinner.setParam('show', false);
                spinner.fire();
            }
        });
        
        // Send action off to be executed
        $A.enqueueAction(action);
    },
    registration: function (component, event, helper) {
        var programId = component.get('v.program');
        var agreement = component.get('v.agreement');
        if (agreement) {
            agreement = agreement.Id;
        }
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        if (spinner) {
            spinner.setParam('show', true);
            spinner.fire();
        }
        var registerMember = component.get("c.registerMember");
        registerMember.setParams({
            "programId": programId,
            "agreementId": agreement
        })

        // Add callback behavior for when response is received
        registerMember.setCallback(this, function (response) {
            var state = response.getState();
            var toastEvent = $A.get("e.force:showToast");
            if (component.isValid() && state === "SUCCESS") {
                var response = response.getReturnValue();                
                toastEvent.setParams({
                    "title": $A.get("$FieloPLT.Label.RegistrationSuccessful"),
                    "message": " ",
                    "type": "success"
                });
                window.localStorage.setItem('joinedMember', JSON.stringify(response));
                toastEvent.fire();
                var refreshEvent = $A.get('e.force:refreshView');
                if (refreshEvent) {
                    refreshEvent.fire();
                }
                component.set('v.showRegistration', false);
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

        $A.enqueueAction(registerMember);
    },
    getProgramDetail: function (component, programId) {
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        var fieldsProgram = component.get('v.recordDetailFields');
        var fieldset = component.get('v.fieldset');
        fieldset.forEach(function (field) {
            if (field.apiName && fieldsProgram.indexOf(field.apiName) == -1) {
                fieldsProgram.push(field.apiName);
            }
        })
        if (programId) {
            if (spinner) {
                spinner.setParam('show', true);
                spinner.fire();
            }
            var action = component.get("c.getProgramInfo");
            action.setParams({
                "fields": fieldsProgram.join(','),
                "programId": programId

            });
            // Add callback behavior for when response is received
            action.setCallback(this, function (response) {
                var toastEvent = $A.get("e.force:showToast");
                var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    //success                    
                    var programDetail = response.getReturnValue();
                    if (this.hasImageField && !programDetail.FieloPLT__ExternalURL__c) {                        
                        programDetail.FieloPLT__ExternalURL__c = this.defaultImage;
                    }
                    component.set('v.recordDetail', programDetail);
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
    getProgramLabel: function(component, event, helper){       
        var action = component.get("c.getObjectData");            
        // Add callback behavior for when response is received
        action.setCallback(this, function (response) {
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();                
            if (component.isValid() && state === "SUCCESS") {
                //success
                var programData = JSON.parse(response.getReturnValue());
                var label = $A.get('$FieloPLT.Label.View');
                label += ' ' + programData.label;
                var btn = {
                    "type": "subcomponent",
                    "subcomponent": "FieloPLT:ShowRecord",
                    "apiName": "Name",
                    "showLabel": true,
                    "config": {
                        "type": "btn",
                        "variant": "neutral",
                        "label": {
                            "value": label
                        }
                    }
                };
                var buttons = component.get('v.buttons');
                buttons.unshift(btn);
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
        $A.enqueueAction(action);
    }
})