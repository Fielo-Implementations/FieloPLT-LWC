({        
    originalLayout: "",
    getFieldset : function(fieldset) {  
        var fields = {fieldset: [], subcomponents: []};
        fieldset.forEach(function(field){
            if(field.type != 'subcomponent'){
                fields.fieldset.push(field.apiName);    
            } else {
                fields.subcomponents.push(field);    
            }           
        })      
        return fields;
    },
    setResponsiveLayout: function(component){
        var list = component.find('fielo-list-view');
        if (list) {
            list = list.getElement();
        }        
        var button = component.find('change-layout-button');
        if( 
            list && 
            component.get('v.showItems') && 
            component.get('v.layoutType').toLowerCase() == 'none' && 
            component.get('v.layout').toLowerCase() != 'accordiondetail' 
        ){
            if ( list.offsetWidth < 640 ){
                component.set('v.layout', 'grid');
                $A.util.addClass (button, "hide");
            }else{
                $A.util.removeClass (button, "hide");
                component.set('v.layout', this.originalLayout);
            }
        }
    },
    setRecords: function(component, event, helper){
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");        
        var records = component.get('v.records');        
        var quantity = component.get('v.quantity');  
        var paging = component.get('v.paging');
        if(paging){
            if(records.length > quantity){
                component.set('v.lastPage', false);
                records = records.slice(0, quantity);
            }else{
                component.set('v.lastPage', true);
            }            
        }        
        var title = component.get('v.title');        
        if(records.length == 0){
            component.set('v.noRecords', true);            
        }else{
            component.set('v.noRecords', false);
            component.set('v.renderRecords', records);
        }
        if(spinner){
            spinner.setParam('show', false);
            spinner.fire();    
        }    
    },
    getLabels: function(component, event, helper, fieldset){        
        var objectAPIName = component.get('v.objectAPIName');
        if(objectAPIName){
            var labelValues = component.get("c.getFieldData");                        
            labelValues.setParams({
                'objectAPIName': objectAPIName,
                'fieldNames': component.get('v.fieldset').filter(field => field.apiName).map(field=>{return field.apiName}).join(',')
            })
            // Add callback behavior for when response is received
            labelValues.setCallback(this, function(response) {
                var toastEvent = $A.get("e.force:showToast");
                var state = response.getState();                
                if (component.isValid() && state === "SUCCESS") {  
                    
                    var fieldLabels = JSON.parse(response.getReturnValue());
                    fieldLabels.fields.forEach(function(field){
                        fieldLabels[field.attributes.name] = field.attributes.label;
                    })

                    var fieldset = component.get('v.fieldset');
                    fieldset.forEach(function(field){
                        field.label = field.label || {};
                        var labelType = field.label.type ? field.label.type : 'default';
                        if(labelType == 'default' && field.apiName){
                            field.label.labelValue = fieldLabels[field.apiName];
                        } else if(labelType == 'label'){
                            var customLabel = '$Label.' + field.label.value;                                         
                            field.label.labelValue = $A.get(customLabel);
                        }else{
                            field.label.labelValue = field.label.value || '';
                        }    
                    })
                    if (component.get('v.layout').toLowerCase() == 'accordiondetail') {                        
                        var detail = component.get('v.recordDetailConfig');
                        detail.sections.forEach(function(s){
                            s.rows.forEach(function(r){
                                r.forEach(function(field){
                                    field.label = field.label || {};
                                    var labelType = field.label.type ? field.label.type : 'default';
                                    if(labelType == 'default' && field.apiName){
                                        var labelApiName = field.apiName.split('.');
                                        if(labelApiName.length > 1){
                                            labelApiName = labelApiName[0].replace('__r', '__c');
                                        }                            
                                        field.label.labelValue = fieldLabels[labelApiName];
                                    } else if(labelType == 'label'){
                                        var customLabel = '$Label.' + field.label.value;
                                        field.label.labelValue = $A.get(customLabel);
                                    }else{
                                        field.label.labelValue = field.label.value || '';
                                    }    
                                })
                            })
                        })
                    }
  
  
  
                    component.set('v.labelsMap', fieldLabels);
                    component.set('v.objectLabel', fieldLabels.labelplural);
                    component.set('v.renderFieldset', fieldset);
                    component.set('v.showItems', true);
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
        }
        
    },
    queryRecords: function(component, event, helper){
        var toastEvent = $A.get("e.force:showToast");
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");        
        var whereCondition = component.get('v.whereCondition');
        var object = component.get('v.objectAPIName');        
        var getRecords = component.get('c.getRecords');
        var fieldset = component.get('v.fieldset');
        var subcomponents = component.get('v.subcomponents');
        
        var getFields = helper.getFieldset(fieldset);
        
        fieldset = getFields.fieldset.join(',');
        component.set('v.subcomponents', getFields.subcomponents);        
        getRecords.setParams({
            'fieldset': fieldset,
            'objectType': object,
            'whereCondition': whereCondition
        })
        // Add callback behavior for when response is received
        getRecords.setCallback(this, function(response) {            
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();                
            if (component.isValid() && state === 'SUCCESS') {
                var records = response.getReturnValue();
                if(records.length > 0){
                    component.set('v.renderRecords', records);                        
                    component.set('v.showItems', true);
                    if(component.get('v.title').length > 0){
                        component.set('v.showTitle', true);
                    }                                           
                } else {
                    var errorMsg = 'No records to show';
                    toastEvent.setParams({
                        "title": errorMsg,
                        "message": " ",
                        "type": "error"
                    });
                    toastEvent.fire(); 
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
            if(spinner){
                spinner.setParam('show', false);
                spinner.fire();    
            }           
        });      
        
        $A.enqueueAction(getRecords);
    }
  })