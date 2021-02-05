({
    fieldsetEdit: {},
    fields: {},
    getMemberInfo: function (component, memberId) {
        var fields = component.get('v.fields');
        var action = component.get('c.getMember');
        action.setParams({
            'fieldset': fields,
            'memberId': memberId
        });

        action.setCallback(this, function (response) {
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var response = response.getReturnValue()[0];
                this.fieldsetEdit.forEach(function (field) {
                    field.value = response[field.apiName];
                });
                component.set('v.member', response);
                component.set('v.showMember', false);
                component.set('v.showMember', true);
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
    },
    getMemberLabels: function (component, event, helper) {
        var fields = component.get('v.fieldsEdit');
        var fieldsAction = component.get('c.getFields');        
        fieldsAction.setParams({
            'objectName': 'FieloPLT__Member__c',
            'fieldNames': fields
        });        
        // Add callback behavior for when response is received
        fieldsAction.setCallback(this, function(response) {
            var toastEvent = $A.get("e.force:showToast");
            var spinner = $A.get("e.c:ToggleSpinnerEvent");
            var state = response.getState();                          
            if (component.isValid() && state === "SUCCESS") {
                //success
                var fieldsInfo = response.getReturnValue();
                fieldsInfo = JSON.parse(fieldsInfo);
                var fields = JSON.parse(fieldsInfo.fields).fields;
                fields.forEach(function(field){                    
                    helper.fields[field.attributes.name] = field;
                });                
                this.fieldsetEdit.forEach(function(field){                    
                    field.attributes = helper.fields[field.apiName].attributes;
                    field.picklistentries = helper.fields[field.apiName].picklistentries;                    
                });
                component.set('v.transactionsLabel', fieldsInfo.transactionsLabel);
                component.set('v.badgesLabel', fieldsInfo.badgesLabel);
                component.set('v.redemptionsLabel', fieldsInfo.redemptionsLabel);
                component.set('v.payoutsLabel', fieldsInfo.payoutsLabel);
                component.set('v.fieldsetEdit', this.fieldsetEdit);
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
        $A.enqueueAction(fieldsAction);        
    },
    save: function (component, event, helper) {
        var spinner = $A.get("e.c:ToggleSpinnerEvent");
        if (spinner) {
            spinner.setParam('show', true);
            spinner.fire();
        }
        var member = component.get('v.member');
        this.fieldsetEdit.forEach(function (field) {
            member[field.apiName] = field.value;
        });
        var folderId = component.get('v.documentFolder');
        var fileName = component.get('v.fileName');
        var dataURL = component.get('v.imgSrc') || '';
        if (dataURL.length > 0) {
            dataURL = dataURL.match(/,(.*)$/)[1];
        }        

        var action = component.get('c.saveMemberInfo');
        action.setParams({
            'member': member,
            'folderId': folderId,
            'fileName': fileName,
            'photoBase64': dataURL
        });
        action.setCallback(this, function (response) {
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();
            var spinner = $A.get("e.c:ToggleSpinnerEvent");
            if (spinner) {
                spinner.setParam('show', false);
                spinner.fire();
            }
            if (component.isValid() && state === "SUCCESS") {
                // GUARDO                
                toastEvent.setParams({
                    "title": $A.get("$FieloPLT.Label.c.DataSavedSuccessfully"),
                    "message": " ",
                    "type": "success"
                });                
                toastEvent.fire();
                var refreshEvent = $A.get('e.force:refreshView');
                refreshEvent.fire();
                component.set('v.viewMode', true);	
                this.getMemberInfo(component, member.Id);
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