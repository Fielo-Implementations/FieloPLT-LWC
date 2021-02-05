({
    doInit: function (component, event, helper) {
        var title, fields, fieldset;
        var config = component.get('v.configDefault');
        try {
            config = JSON.parse(config);
            // CHECK IF BASIC CONFIG OVERRIDES ADVANCED CONFIG
            // TITLE
            var titleValue = component.get('v.titleValue').trim();
            if (titleValue.length > 0) {
                if (titleValue.indexOf('{') == 0) {
                    title = JSON.parse(titleValue);
                } else {
                    title = {
                        "value": component.get('v.titleValue'),
                        "type": "text"
                    }
                }
            }
            if (title) {
                titleValue = '';
                var type = title.type.toLowerCase();
                var value = title.value;
                if (type == 'label') {
                    var label = '$FieloPLT.Label.' + value;
                    titleValue = $A.get(label);
                    component.set('v.title', titleValue);
                } else {
                    titleValue = value;
                    component.set('v.title', titleValue);
                }
            }
            // TITLE

            if (!component.get('v.quantity')) {
                component.set('v.quantity', config.quantity);
            }

            fieldset = [], fields = [];

            var fieldsConfig = component.get('v.fields').trim();
            if (fieldsConfig.length == 0) {
                fieldset = config.fieldset;
            } else if (fieldsConfig.indexOf('[') == 0) {
                fieldset = JSON.parse(fieldsConfig);
            } else {
                var newField, nameAndType, apiName, type;
                var fieldsList = component.get('v.fields').split(',');
                fieldsList.forEach(function (field) {
                    nameAndType = field.split('/');
                    apiName = nameAndType[0].trim();
                    type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
                    newField = {
                        'apiName': apiName,
                        'type': apiName == 'Name' ? 'subcomponent' : type,
                        'label': {},
                        'showLabel': true
                    }
                    if (apiName == 'Name') {
                        newField.subcomponent = 'c:ShowRecord';
                        newField.showLabel = true;
                    }
                    fieldset.push(newField);
                })
            }
            fieldset.forEach(function (field) {
                if (fields.indexOf(field.apiName) == -1) {
                    fields.push(field.apiName);
                }
            })
            component.set('v.fieldset', fieldset);
            component.set('v.fields', fields.join(','));

            var listviews = [];
            var listviewsFields = {},
                newListViews = [],
                payoutItemRelatedActive = false;
            listviews.forEach(function (listview) {
                if (listview.title) {
                    var titleType = listview.title.type.toLowerCase();
                    var titleValue = listview.title.value;
                    if (titleType == 'label') {
                        var titleLabel = '$FieloPLT.Label.' + titleValue;
                        listview.titleValue = $A.get(titleLabel);
                    } else {
                        listview.titleValue = titleValue;
                    }
                }
                newListViews.push(listview);
            });

            component.set('v.recordDetailListviews', listviewsFields);
            /* FILTER */
            var sortByFields = component.get('v.sortByFields');
            var sortByFieldset = [];
            if (sortByFields && sortByFields.trim().length > 0) {
                sortByFields.split(',').forEach(function (field) {
                    var newField = {
                        'apiName': field,
                        'type': 'output'
                    }
                    sortByFieldset.push(newField);
                })
            }
            component.set('v.sortByFieldset', sortByFieldset);

            // var filterFields = component.get('v.filterFields').trim();
            // if (filterFields.length == 0) {
            //     filterFields = config.filterFields;
            // }
            // component.set('v.filterFieldset', filterFields);
            helper.getFilterFields(component);

            // sets overrides helptexts
            component.set(
                'v.overrideHelptext',
                {
                    'fieloplt__status__c': $A.get('$FieloPLT.Label.c.FilterPayoutStatusHelpText')
                }
            );


            var defaultPicklistOptions = {
                'FieloPLT__Status__c': {
                    'defaultPicklistValue': $A.get("$FieloPLT.Label.All")
                }
            };

            component.set('v.defaultPicklistOptions', defaultPicklistOptions);

            var spinner = $A.get("e.c:ToggleSpinnerEvent");
            if (spinner) {
                spinner.setParam('show', true);
                spinner.fire();
            }

            /* RECORD DETAIL */
            var member = component.get('v.member');
            if (member) {
                helper.getPayouts(component);
            } else {
                var memberEvent = $A.get("e.c:RefreshMemberEvent");
                if (memberEvent) {
                    memberEvent.fire();
                }
            }
        } catch (e) {
            component.set('v.error', e);
            component.set('v.showError', true);
        }
    },
    updateMember: function (component, event, helper) {
        component.set('v.member', event.getParam('member'));
        helper.getPayouts(component,0);
    },
    paginator: function (component, event, helper) {
        helper.getPayouts(component, event.getParam("offset"));
    },
    filter: function (component, event, helper) {
        component.set('v.dynamicFilter', event.getParam('condition'));
        component.set('v.orderBy', event.getParam('orderBy'));
        helper.getPayouts(component, 0);
    },
    handleBackClick: function (component, event, helper) {
        var backEvent = component.getEvent("backToCatalog");
        if (backEvent) {
            backEvent.fire();
        }
    },
    showRecord: function (component, event, helper) {
        try{
            component.set('v.record', event.getParam('record'));
            component.set('v.dataFilters', JSON.stringify({FieloPLT__Payout__c: component.get('v.record').Id}));
            component.set('v.showList', false);
            component.set('v.showDetail', true);
        } catch(e) {
            console.error(e);
        }
    },
    backToMyPayouts: function (component, event, helper) {
        try {
            component.set('v.dataFilters', '{}');
            component.set('v.record', null);
            component.set('v.showDetail', false);
            component.set('v.showList', true);
        } catch (e) {
            console.error(e);
        }
    }
})