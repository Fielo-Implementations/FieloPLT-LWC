({
    doInit: function (component, event, helper) {        
        var fields, fieldset;
        var config = component.get('v.configDefault');
        try {
            config = JSON.parse(config);
            fieldset = [], fields = [], helper.fieldsetEdit = [];
            var fieldsConfig = component.get('v.fields').replace(/ /g, "");
            var defaultFields = [];
            if (fieldsConfig.length == 0) {
                fieldset = config.fieldset;                
            } else if (fieldsConfig.indexOf('[') == 0) {
                fieldset = JSON.parse(fieldsConfig);                
            } else {
                var newField, nameAndType, apiName, type;
                var fieldsList = fieldsConfig.split(',');
                fieldsList.forEach(function (field) {
                    nameAndType = field.split('/');
                    apiName = nameAndType[0].trim();
                    type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
                    newField = {
                        'apiName': apiName,
                        'type': type,
                        'label': {
                            'type': 'default'
                        },
                        'showLabel': true
                    }
                    fieldset.push(newField);                    
                })                
            }
            fieldset.forEach(function(field){
                if (field.apiName && defaultFields.indexOf(field.apiName) == -1) {
                    defaultFields.push(field.apiName);
                }
            })
            var defaultFieldsEdit = [];
            // var fieldsConfigEdit = component.get('v.fieldsEdit').trim();
            var fieldsConfigEdit = component.get('v.fieldsEdit').replace(/ /g, "");
            if (fieldsConfigEdit.length == 0) {
                helper.fieldsetEdit = config.fieldsetEdit;
            } else if (fieldsConfigEdit.indexOf('[') == 0) {                
                helper.fieldsetEdit = JSON.parse(fieldsConfigEdit);
            } else {
                var newField, nameAndType, apiName, type;
                var fieldsListEdit = fieldsConfigEdit.split(',');
                fieldsListEdit.forEach(function (field) {
                    nameAndType = field.split('/');
                    apiName = nameAndType[0].trim();
                    type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
                    newField = {
                        'apiName': apiName,
                        'type': type,
                        'label': {
                            'type': 'default'
                        },
                        'showLabel': true
                    }
                    helper.fieldsetEdit.push(newField);                    
                })
                if (fieldsListEdit.indexOf('Name') == -1) {
                    helper.fieldsetEdit.push({
                        'apiName': 'Name',
                        'type': 'output',
                        'label': {
                            'type': 'default'
                        },
                        'showLabel': true
                    })                    
                }
            }
            helper.fieldsetEdit.forEach(function(field){
                if (field.apiName && defaultFields.indexOf(field.apiName) == -1) {
                    defaultFields.push(field.apiName);
                }
                if (field.apiName && defaultFieldsEdit.indexOf(field.apiName) == -1) {
                    defaultFieldsEdit.push(field.apiName);
                }
            })
            component.set('v.fieldset', fieldset);
            component.set('v.fields', defaultFields.join(','));            
            component.set('v.fieldsEdit', defaultFieldsEdit.join(','));            

            helper.getMemberLabels(component, event, helper);
        } catch (e) {
            component.set('v.error', e.stack);
            component.set('v.showError', true);
        }
    },
    updateMember: function (component, event, helper) {
        var member = event.getParam('member');
        helper.getMemberInfo(component, member.Id);
    },
    editMember: function (component, event, helper) {
        component.set('v.viewMode', false);
    },
    cancelEdit: function (component, event, helper) {
        var fieldsetEdit = component.get('v.fieldsetEdit');
        var member = component.get('v.member');
        fieldsetEdit.forEach(function (field) {
            field.value = member[field.apiName];
        })
        component.set('v.imgSrc', '');
        component.set('v.fileName', '');
        component.set('v.files', []);
        component.set('v.viewMode', true);
    },
    saveMember: function (component, event, helper) {
        helper.save(component, event, helper);        
    },
    readFile: function (component, event, helper) {
        var toastEvent = $A.get("e.force:showToast");
        var files = component.get("v.files");
        if (files && files.length > 0) {
            var file = files[0][0];
            if (file.size > 2000000) {
                var uploadError = "File is too big";
                toastEvent.setParams({
                    "title": uploadError,
                    "message": " ",
                    "type": "error"
                });
                toastEvent.fire();
            } else {
                var reader = new FileReader();
                reader.onloadend = function () {
                    var dataURL = reader.result;
                    component.set("v.imgSrc", dataURL);
                    component.set("v.fileName", file.name);
                };
                reader.readAsDataURL(file);
            }
        }
    },
    manageConsents: function(component, event, helper) {
        component.set('v.showConsents', true);
    },
    hasConsents: function(component, event, helper) {
        component.set('v.hasConsents', event.getParam('hasConsents'));
    }
})