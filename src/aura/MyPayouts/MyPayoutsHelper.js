({
    hasImageField: false,
    defaultImage: '',
    pointTypes: '',
    getPayouts: function (component, offset) {
        var spinner = $A.get("e.c:ToggleSpinnerEvent");
        var memberId = component.get('v.member');
        var quantity = component.get('v.quantity');
        var orderBy = component.get('v.orderBy') || null;
        var paging = component.get('v.paging');
        if (paging) {
            quantity++;
        } else {
            quantity = null;
        }
        var dynamicFilter = component.get('v.dynamicFilter');
        var listviews = component.get('v.recordDetailListviews') || {};
        if (memberId) {
            if (spinner) {
                spinner.setParam('show', true);
                spinner.fire();
            }

            memberId = memberId.Id;
            var fieldsPayout = component.get('v.fields').split(',');
            var action = component.get("c.getMemberPayouts");
            action.setParams({
                "fieldsPayout": fieldsPayout,
                "fieldsPayoutItem": Object.keys(listviews.FieloPLT__Points__r || {}),
                'memberId': memberId,
                "quantity": quantity,
                "offset": offset,
                "orderBy": orderBy,
                "dynamicFilter": dynamicFilter
            });

            // Add callback behavior for when response is received
            action.setCallback(this, function (response) {
                var toastEvent = $A.get("e.force:showToast");
                var spinner = $A.get("e.c:ToggleSpinnerEvent");
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    //success
                    var payouts = response.getReturnValue();
                    for (var i = 0; i < payouts.length; i++) {
                        if (payouts[i].CreatedDate) {
                            payouts[i].CreatedDate = payouts[i].CreatedDate.slice(0, 10);
                        }
                    }
                    var payoutListviews = [];
                    payouts.forEach(function (payout) {
                        payoutListviews.forEach(function (listview) {
                            var newListView = {};
                            var listviewRecordsValue = null;
                            if (listview.objectRelation) {
                                listviewRecordsValue = payout[listview.objectRelation] || [];
                            }
                            if (!payout.relatedLists) {
                                payout.relatedLists = [];
                            }
                            newListView.layout = 'grid';
                            newListView.records = listviewRecordsValue;
                            newListView.titleValue = listview.titleValue;
                            newListView.objectAPIName = listview.objectAPIName;
                            newListView.fieldset = listview.fieldset;
                            payout.relatedLists.push(newListView);
                        }, this)
                    }, this)
                    component.set('v.records', payouts);
                    component.set('v.showRecords', true);
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
        } else {
            var memberEvent = $A.get("e.c:RefreshMemberEvent");
            if (memberEvent) {
                memberEvent.fire();
            }
        }
    },
    getFilterFields: function (component) {
        try{
            var fields = component.get('v.filterFields').trim();
            var filterFieldsAction = component.get('c.getFilterFields');
            var fieldNames = '';
            var newFields = new Set();
            var fieldTypes = {};

            fields.split(',').forEach(function (field) {
                field = field.trim();
                var fieldSplit = field.split('/');
                newFields.add(fieldSplit[0]);
                if (fieldSplit.length > 1) {
                    fieldTypes[fieldSplit[0]] = fieldSplit[1];
                }
            });
            
            var sortByFieldset = component.get('v.sortByFieldset');
            // Adds items to field name that only has apiName
            sortByFieldset.forEach(function (item) {
                if (item.apiName && !newFields.has(item.apiName)) {
                    newFields.add(item.apiName);
                }
            });
            sortByFieldset = component.get('v.sortByFieldset')
                .reduce(
                    function (map, obj) {
                        if (obj.apiName) {
                            map[obj.apiName.toLowerCase()] = obj;
                        }
                        return map;
                    },
                    {}
                );

            fieldNames = Array.from(newFields).join(',');

            filterFieldsAction.setParams({
                'objectName': 'FieloPLT__Payout__c',
                'fieldNames': fieldNames
            });

            var defaultOptions = component.get('v.defaultPicklistOptions');
            
            // Add callback behavior for when response is received
            filterFieldsAction.setCallback(this, function (response) {
                try {
                    var toastEvent = $A.get("e.force:showToast");
                    var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
                    var state = response.getState();
                    if (component.isValid() && state === "SUCCESS") {
                        //success
                        var newFilterFields = [];
                        var sortByEntries = [];
                        var fieldsMeta = response.getReturnValue();
                        fieldsMeta = JSON.parse(fieldsMeta).fields;
                        fieldsMeta.forEach(function (field) {
                            if (
                                sortByFieldset[field.attributes.name.toLowerCase()] &&
                                sortByFieldset[field.attributes.name.toLowerCase()].type != 'image'
                            ) {
                                sortByEntries.push({
                                    label: field.attributes.label + ' ↑',
                                    value: field.attributes.name + ' ASC'
                                });
                                sortByEntries.push({
                                    label: field.attributes.label + ' ↓',
                                    value: field.attributes.name + ' DESC'
                                });
                            }
                            // removes if it isn't a filter element
                            if (fields.toLowerCase().indexOf(field.attributes.name.toLowerCase()) != -1 ) {

                                if (field.attributes.name.toLowerCase() == 'fieloplt__status__c') {
                                    let options = [
                                        {label:$A.get("$Label.c.All"), value:''}
                                    ];
                                    options.push(...field.picklistentries);
                                    field.picklistentries = options;
                                    field.disableSelectAnOption = true;
                                }
                                if (defaultOptions && defaultOptions[field.attributes.name] && field.attributes.inputType == 'picklist') {
                                    var defaultFieldOptions = defaultOptions[field.attributes.name].options;
                                    var defaultPicklistValue = defaultOptions[field.attributes.name].defaultPicklistValue;
                                    if (defaultFieldOptions) {
                                        var newPicklistEntries = [];
                                        field.picklistentries.forEach(function (entry) {
                                            if (defaultFieldOptions[entry.value]) {
                                                newPicklistEntries.push(entry);
                                            }
                                        });
                                        field.picklistentries = newPicklistEntries;
                                    }
                                    if (defaultPicklistValue) {
                                        field.defaultPicklistValue = defaultPicklistValue;
                                    }
                                }
                                if (fieldTypes[field.attributes.name]) {
                                    field.type = fieldTypes[field.attributes.name];
                                }
                                newFilterFields.push(field);
                            }
                        });
                        
                        component.set('v.sortByEntries', sortByEntries);
                        component.set('v.filterFieldset', newFilterFields);
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
                } catch(e) {
                    console.error(e);
                }
            });

            $A.enqueueAction(filterFieldsAction);
        } catch(e) {
            console.error(e);
        }
    }
})