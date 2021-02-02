({
    doInit : function(component, event, helper) {
        var fieldset, fields;        
        var config = component.get('v.configDefault');        
        try{
            config = JSON.parse(config);
            fieldset = config.fieldset;
        } catch(e) {
            component.set('v.error', e);
            component.set('v.showError', true);
        }
        var fields = component.get('v.fields').trim();
        if(fields.length > 0){
            if(fields.indexOf('[') == 0){
                fieldset = JSON.parse(fields);
            } else {
                var newField, nameAndType, apiName, type;
                fieldset = [];            
                fields = fields.split(',');
                fields.forEach(function(field){
                    nameAndType = field.split('/');
                    apiName = nameAndType[0].trim();
                    type = nameAndType[1] ? nameAndType[1].trim() : 'output';
                    newField = {
                        'apiName': apiName,
                        'type': type,
                        'label': {'type': 'default'},
                        'showLabel': true
                    }
                    fieldset.push(newField);
                });                
            }
        }                    
        component.set('v.fieldset', fieldset);
        var defaultFields = {
            "Name":true,
            "FieloPLT__Program__c":true,
            "FieloPLT__Program__r.Name":true,
            "FieloPLT__Agreement__c":true,
            "FieloPLT__Status__c": true,
            "FieloPLT__ExternalURL__c": true,
            "FieloPLT__CurrentLevelMember__r.FieloPLT__Level__r.Name": true
        }
        fields = [];
        fieldset.forEach(function(item){
            if(!defaultFields[item.apiName]){
                fields.push(item.apiName);    
            }
        });
        for(var key in defaultFields){
            fields.push(key);
        }
        var subfield = component.get('v.subfield');
        if (subfield && subfield.trim().length > 0 && fields.indexOf(subfield) == -1) {            
            fields.push(subfield.trim());
        }
        fields = fields.join(',');
        component.set('v.fields', fields);
        
        var labelValues = component.get("c.getFieldLabels");
        // Add callback behavior for when response is received
        labelValues.setCallback(this, function(response) {
            var state = response.getState();        
            if (component.isValid() && state === "SUCCESS") {
                //success                                                                            
                var fieldLabels = response.getReturnValue();                    
                fieldset.forEach(function(field){
                    if (field.showLabel) {
                        var labelType = field.label ? field.label.type : 'default';
                        if(labelType == 'default'){                        
                            field.label = fieldLabels[field.apiName];
                        } else if(labelType == 'label'){
                            var customLabel = '$Label.' + field.label.value;                                         
                            field.label = $A.get(customLabel);
                        }else{
                            field.label = field.label.value;
                        }
                    }
                })                
                component.set('v.programLabel', fieldLabels.FieloPLT__Program__c);
                component.set('v.memberLabel', fieldLabels.objectLabel);
                helper.members(component, event, true, helper);
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
        
        $A.enqueueAction(labelValues);
        
    },
    refreshMember : function(component, event, helper) {
        helper.members(component, event, false, helper);
    },
    selectMember : function(component, event, helper){
        var memberId = event.getSource().get("v.value");
        helper.setMember(component, memberId);
    },
    selectProgram: function(component, event, helper){
        var programId = event.getSource().get("v.value");
        component.set('v.members', helper.programs[programId]);
        helper.setMember(component, helper.programs[programId][0].Id);
    },
    handlePubsubReady: function (component, event, helper) {
        var pubsub = component.find('pubsub');
        pubsub.registerListener(
            'getMember',
            $A.getCallback(function (payload) {
                if (component.get('v.memberInfo')) {
                    var pubsub = component.find('pubsub');
                    if (pubsub)
                        pubsub.fireEvent('memberChange', {
                            member: component.get('v.memberInfo')
                        });

                } else {
                    helper.members(component, event, false, helper);
                }
        }));
    },
    handleDestroy: function (component) {
        var pubsub = component.find('pubsub');
        pubsub.unregisterAllListeners();
    }
})