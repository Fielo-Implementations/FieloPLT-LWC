({    
    doInit: function(component, event, helper){        
        var title = component.get('v.title');
        var titleValue = '';
        var titleTranslatedValue = [];
        if(title){
            var type = title.type.toLowerCase();
            var value = title.value;
            if(type == 'label'){
                var label = '$Label.' + value;
                titleValue = $A.get(label);
                component.set('v.title', titleValue);                
            }else if(type == 'picklist'){
                value = title.value.split('.');                
                titleTranslatedValue.push(value[0]);
                var titleField = value[1];
            }else{
                titleValue = value;
                component.set('v.titleValue', titleValue);
            }
        }
        
        var fieldset = component.get('v.fieldset');
        var fields = [];        
        fieldset.forEach(function(field){
            if (field.apiName) {
                fields.push(field.apiName);
            }
        })
        component.set('v.fields', fields);                 
        
        /* RECORD DETAIL */
        var recordDetailConfig = component.get('v.recordDetailConfig');
        if(recordDetailConfig){            
            var recordDetailFields = {
                'Name' : true
            };
            recordDetailConfig.sections.forEach(function(section){
                section.rows.forEach(function(row){                
                    row.forEach(function(f){
                        recordDetailFields[f.apiName] = true;                    
                    })                
                })
            })
            
            component.set('v.recordDetailFields', Object.keys(recordDetailFields));    
            var listviews = recordDetailConfig.relatedLists || [];
            var listviewsFields = {};            
            listviews.forEach(function(listview){
                if(listview.objectRelation){
                    listview.standard = true;
                    listviewsFields[listview.objectRelation] = {};
                    listview.fieldset.forEach(function(field){
                        listviewsFields[listview.objectRelation][field.apiName] = true;
                    })
                }
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
            
            component.set('v.recordDetailListviews', listviewsFields);
        }
        
        /* RECORD DETAIL */
        
        var multilanguageValues = component.get("c.getPicklistsValues");
        multilanguageValues.setParams({            
            "listPicklistsToTranslate": titleTranslatedValue
        })
        
        // Add callback behavior for when response is received
        multilanguageValues.setCallback(this, function(response) {
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();        
            if (component.isValid() && state === "SUCCESS") {
                //success                                                                            
                var picklistValues = response.getReturnValue();                
                titleTranslatedValue.forEach(function(title){
                    component.set('v.titleValue', picklistValues[title][titleField]);
                })                
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
        $A.enqueueAction(multilanguageValues);
        if (component.get('v.member')) {
            helper.getTransactionList(component, 0);
        }
    },
    updateMember: function(component, event, helper){
        var member = event.getParam('member');
        component.set('v.member', member);        
        helper.getTransactionList(component, 0);
    },
    filter: function(component, event, helper){                        
        helper.getTransactionList(component, 0);
    },
    paginator: function(component, event, helper){
        var offset = event.getParam("offset");        
        helper.getTransactionList(component, offset);
    },
    toggle: function(component, event, helper){
        var accordionBody = component.find('body');
        var accordionHeader = component.find('header');
        $A.util.toggleClass(accordionBody, 'closed');
        $A.util.toggleClass(accordionHeader, 'closed');
    },
    showTransaction: function(component, event, helper){
        var record = event.getParam('record');
        record = record.Id;
        helper.getTransactionDetail(component, record);        
    }
})