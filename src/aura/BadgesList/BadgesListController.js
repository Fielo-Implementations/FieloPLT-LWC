({    
    doInit: function(component, event, helper){        
        var fields, fieldset;
        try {

            fieldset = [], fields = [];

            var fieldsConfig = component.get('v.fields').trim();
            if (fieldsConfig.length == 0) {
                fieldsConfig = 'Name,FieloPLT__ExternalURL__c/image'
            } 
            if (fieldsConfig.indexOf('[') == 0) {
                fieldset = JSON.parse(fieldsConfig);
            } else {
                var newField, nameAndType, apiName, type;
                var fieldsList = fieldsConfig.split(',');
                fieldsList.forEach(function (field) {
                    nameAndType = field.split('/');
                    apiName = nameAndType[0].trim();
                    if (apiName) {
                        type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
                        newField = {
                            'apiName': apiName,
                            'type': type,
                            'label': {
                                'type': 'default'
                            },
                            'showLabel': false
                        }
                        fieldset.push(newField);
                        if (fields.indexOf(apiName) == -1) {
                            fields.push(apiName);
                        }
                    }
                })
                fieldset.push({
                    'type': 'subcomponent',
                    'subcomponent': 'FieloPLT:BadgeDetail',
                    'label': {
                        'type': 'default'
                    },
                    'config': {
                        'status': component.get('v.status')
                    },
                    'showLabel': false
                });
            }
            component.set('v.fieldset', fieldset);
            component.set('v.fieldsBadges', fields);            
            helper.getBadgesList(component, 0);
        } catch (e) {
            component.set('v.error', e);
            component.set('v.showError', true);
        }       
    },
    updateMember: function(component, event, helper){
        helper.getBadgesList(component, 0);
    },
    paginator: function(component, event, helper){
        var offset = event.getParam("offset");        
        helper.getBadgesList(component, offset);
    },
    filter: function(component, event, helper) {
        component.set('v.dynamicFilter', event.getParam('condition'));
        component.set('v.orderBy', event.getParam('orderBy'));
        helper.getBadgesList(component, 0);
    }
})