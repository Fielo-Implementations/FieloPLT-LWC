({
    doInit : function(component, event, helper) {
        var title, fields, fieldset;        
        var config = component.get('v.config');
        var useAdvancedOnly = component.get('v.useAdvancedOnly');
        if(!useAdvancedOnly){
            config = component.get('v.configDefault');
        }        
        try{
            config = JSON.parse(config);
            if(useAdvancedOnly){
                title = config.title;
                if (title) {
                    titleValue = '';
                    var type = title.type.toLowerCase();
                    var value = title.value;
                    if(type == 'label'){
                        var label = '$Label.' + value;
                        titleValue = $A.get(label);                
                    }else{
                        titleValue = value;
                    }                
                    component.set('v.title', titleValue);
                }
                

                // VER PARTE DE SI ES STANDARD O NO EN LAS LISTVIEWS
                if(config.listviews){
                    config.listviews.forEach(function(listview){
                        if(listview.title){
                            var titleType = listview.title.type.toLowerCase();
                            var titleValue = listview.title.value;
                            if(titleType == 'label'){
                                var titleLabel = '$Label.' + titleValue;
                                listview.titleValue = $A.get(titleLabel);
                            }else{
                                listview.titleValue = titleValue;
                            }
                        }
                                            
                        if(listview.recordDetail && listview.recordDetail.relatedLists){                        
                            listview.recordDetail.relatedLists.forEach(function(related){
                                if(related.objectRelation){
                                    related.standard = true;
                                }
                            });    
                        }
                        
                    });                    
                }

            }else{
                /* FILTER */
                var filterFields = component.get('v.filterFields').trim();
                if (filterFields.length == 0){                
                    filterFields = config.filterFields;                
                }
                component.set('v.filterFieldset', filterFields);            

                var firstListView = config.listviews[0] || {};
                // CHECK IF BASIC CONFIG OVERRIDES ADVANCED CONFIG
                
                // TITLE                
                var titleValue = component.get('v.titleValue').trim();
                if(titleValue.length > 0){
                    if (titleValue.indexOf('{') == 0) {
                        title = JSON.parse(titleValue);
                    } else {
                        title = {
                            "value": component.get('v.titleValue'),
                            "type": "text"
                        };                    
                    }
                }
                if (title) {
                    titleValue = '';
                    var type = title.type.toLowerCase();
                    var value = title.value;
                    if(type == 'label'){
                        var label = '$Label.' + value;
                        titleValue = $A.get(label);                
                    }else{
                        titleValue = value;
                    }                
                    component.set('v.title', titleValue);
                }
                // TITLE
                
                firstListView.layout = component.get('v.layout').toLowerCase();
                
                firstListView.paging = component.get('v.paging');            
                if(component.get('v.quantity')){                
                    firstListView.quantity = component.get('v.quantity');
                }
                
                // var type = component.get('v.type');            
                // if (type && type != 'All'){
                //     firstListView.condition = "[{\"field\":\"FieloPLT__Type__c\",\"value\":\"" + type + "\",\"operator\": \"equals\"}]";
                // } else {
                // }
                
                firstListView.condition = '';
                firstListView.title = {                    
                    "type": "text",
                    "value": type
                }

                // component.set('v.showFilter', component.get('v.showDateFilter'));
                // component.set('v.dateFilter', config.dateFilter || 'CreatedDate');
                
                
                fieldset = [], fields = [];
                var configFields = component.get('v.fields');
                if (configFields && configFields.trim().length == 0) {
                    fieldset = firstListView.fieldset || [];
                } else if(configFields && configFields.indexOf('[') == 0) {
                    fieldset = JSON.parse(configFields);
                } else {
                    fieldset.push({
                        'type': 'subcomponent',
                        'subcomponent': 'c:TransactionTypeIcon',
                        'apiName': 'FieloPLT__Type__c'
                    });
                    // fieldset.push({
                    //     'type': 'subcomponent',
                    //     'subcomponent': 'c:ShowRecord',
                    //     'apiName': 'Name',
                    //     'label': {
                    //         'type': 'default'
                    //     },
                    //     'showLabel': true  
                    // });
                    var newField, nameAndType, apiName, type;
                    var fieldsList = component.get('v.fields').split(',');
                    fieldsList.forEach(function(field){
                        nameAndType = field.split('/');
                        apiName = nameAndType[0].trim();
                        if(apiName){
                            type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
                            newField = {
                                'apiName': apiName,
                                'type': type,
                                'label': {},
                                'showLabel': true
                            }
                            fieldset.push(newField);
                        }
                    })
                }
                firstListView.fieldset = fieldset;
                
                /* RECORD DETAIL */            
                var recordDetailConfig = firstListView.recordDetail || {
                    'sections' : [],
                    'relatedLists': [],
                    'subcomponents': []
                };
                
                if(component.get('v.recordDetailFieldset').trim().length > 0){
                    var row = [];
                    fieldsList = component.get('v.recordDetailFieldset').split(',');                
                    fieldsList.forEach(function(field){
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
                        row.push(newField);
                    })                
                    recordDetailConfig.sections = [];
                    var newSection = {};
                    newSection.rows = [row];
                    newSection.title = {
                        'type': 'text',
                        'value': 'Detail'
                    }
                    recordDetailConfig.sections.push(newSection);
                }
                
                var listviews = recordDetailConfig.relatedLists || [];
                var listviewsDefaultConfig = {};
                listviews.forEach(function(listview){
                    if(listview.objectRelation){
                        listviewsDefaultConfig[listview.objectRelation] = listview.fieldset;
                    }
                })
                var newListViews = [];
                // RULE RELATED
                var showPointRelated = component.get('v.showPointRelated');
                
                if(showPointRelated){
                    var newRelated = {};
                    newRelated.fieldset = [];
                    newRelated.objectRelation = 'FieloPLT__Points__r';
                    newRelated.objectAPIName = 'FieloPLT__Point__c';
                    newRelated.title = {
                        'type': 'text',
                        'value': 'Points'
                    }
                    newRelated.titleValue = 'Points';  
                    var pointRelatedFieldset = component.get('v.pointRelatedFields').trim();
                    if(pointRelatedFieldset.length == 0){
                        newRelated.fieldset = listviewsDefaultConfig[newRelated.objectRelation];
                        pointRelatedFieldset = [];
                    } else {
                        pointRelatedFieldset = pointRelatedFieldset.split(',')
                    }
                    pointRelatedFieldset.forEach(function(pointField){
                        nameAndType = pointField.split('/');
                        apiName = nameAndType[0].trim();
                        type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
                        newField = {
                            'apiName': apiName,
                            'type': type,
                            'label': {},
                            'showLabel': true
                        }
                        newRelated.fieldset.push(newField);                                                    
                    })
                    newRelated.standard = true;
                    newListViews.push(newRelated);
                }
                
                
                // BADGE MEMBER RELATED
                var showBadgeMemberRelated = component.get('v.showBadgeMemberRelated');
                
                if(showBadgeMemberRelated){
                    var newRelated = {};
                    newRelated.fieldset = [];
                    newRelated.objectRelation = 'FieloPLT__BadgesMembers__r';
                    newRelated.objectAPIName = 'FieloPLT__BadgeMember__c';
                    newRelated.title = {
                        'type': 'text',
                        'value': 'Badge Members'
                    }
                    newRelated.titleValue = 'Badge Members';                                            
                    var badgeMemberRelatedFieldset = component.get('v.badgeMemberRelatedFields').trim();
                    if(badgeMemberRelatedFieldset.length == 0){
                        newRelated.fieldset = listviewsDefaultConfig[newRelated.objectRelation];
                        badgeMemberRelatedFieldset = [];
                    } else {
                        badgeMemberRelatedFieldset = badgeMemberRelatedFieldset.split(',');
                    }
                    badgeMemberRelatedFieldset.forEach(function(badgeMemberField){
                        nameAndType = badgeMemberField.split('/');
                        apiName = nameAndType[0].trim();
                        type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
                        newField = {
                            'apiName': apiName,
                            'type': type,
                            'label': {},
                            'showLabel': true
                        }
                        newRelated.fieldset.push(newField);                                                    
                    })
                    newRelated.standard = true;
                    newListViews.push(newRelated);
                }
                
                // REDEMPTION RELATED
                var showRedemptionRelated = component.get('v.showRedemptionRelated');
                
                if(showRedemptionRelated){
                    var newRelated = {};
                    newRelated.fieldset = [];
                    newRelated.objectRelation = 'FieloPLT__Redemptions__r';
                    newRelated.objectAPIName = 'FieloPLT__Redemption__c';
                    newRelated.title = {
                        'type': 'text',
                        'value': 'Redemptions'
                    }
                    newRelated.titleValue = 'Redemptions';                    
                    var redemptionRelatedFieldset = component.get('v.redemptionRelatedFields').trim();
                    if(redemptionRelatedFieldset.length == 0){
                        newRelated.fieldset = listviewsDefaultConfig[newRelated.objectRelation];
                        redemptionRelatedFieldset = [];
                    } else {
                        redemptionRelatedFieldset = redemptionRelatedFieldset.split(',');
                    }
                    redemptionRelatedFieldset.forEach(function(redemptionField){
                        nameAndType = redemptionField.split('/');
                        apiName = nameAndType[0].trim();
                        type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
                        newField = {
                            'apiName': apiName,
                            'type': type,
                            'label': {},
                            'showLabel': true
                        }
                        newRelated.fieldset.push(newField);                                                    
                    })
                    newRelated.standard = true;
                    newListViews.push(newRelated);
                }
                
                
                listviews.forEach(function(listview){
                    if(listview.title){
                        var titleType = listview.title.type.toLowerCase();
                        var titleValue = listview.title.value;
                        if(titleType == 'label'){
                            var titleLabel = '$Label.' + titleValue;
                            listview.titleValue = $A.get(titleLabel);
                        }else{
                            listview.titleValue = titleValue;
                        }
                    }            
                });
                
                recordDetailConfig.relatedLists = newListViews;            
                /* RECORD DETAIL */  
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
            }
            component.set('v.listviews', config.listviews);
            component.set('v.showTransactions', true);
            if (component.get('v.member')) {
                component.set('v.showHeader', true);
            }
        } catch(e) {
            if(useAdvancedOnly && component.get('v.config').trim().length == 0){
                e = 'Please input a JSON for advanced configuration '    
            }
            component.set('v.error', e);
            component.set('v.showError', true);
        }
        
        if (component.find('fielo-transaction__filter')){
            var orderBy = component.find('fielo-transaction__filter').find('fielo-filter__sort-by');
        }
    },
    filter: function(component, event, helper){     
        var orderBy = event.getParam('orderBy');
        if (orderBy === '') {
            orderBy = 'CreatedDate DESC';
        }
        component.set('v.orderBy', orderBy);
        component.set('v.dynamicFilter', event.getParam('condition'));        
        var transactionList = component.find('transactionList');
        if (transactionList) {
            transactionList.filterElements();
        }
    }, 
    updateMember: function(component, event, helper){
        var member = event.getParam('member');
        component.set('v.member', member);
        component.set('v.showHeader', true);
    }
})
