({
    doInit: function(component, event, helper){
        var title;
        var programs = [];
        var config = component.get('v.configDefault');        
        try{
            config = JSON.parse(config);
        } catch(e) {
            component.set('v.error', e);
            component.set('v.showError', true);
        }
                
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
        if(title){
            titleValue = '';
            var type = title.type.toLowerCase();
            var value = title.value;
            if(type == 'label'){
                var label = '$Label.' + value;
                titleValue = $A.get(label);                
            }else{
                titleValue = value;                
            }
            // TITLE            
            component.set('v.title', titleValue);                
            component.set('v.showTitle', true);    
        }
        
        
        var programsList = config.programs || [];
        var programListConfig = component.get('v.programList').trim();
        if(programListConfig.length > 0){
            programsList = programListConfig.split(',');
        }
        var id, banner, programAndBanner;
        programsList.forEach(function(program){
            if(program.id){
                id = program.id.trim();
                banner = program.banner;
            }else{                
                id = program.trim();                
            }                
            helper.programsContent[id] = banner || '';
            programs.push(id);
        })
        var layoutType = component.get('v.layoutType');
        var showLabel = layoutType == 'None';
        var fieldset = [], fields = [];
        var newField, nameAndType, apiName, type;
        var fieldsList = component.get('v.fields').trim();        
        if(fieldsList.length == 0){
            fieldset = config.fieldset || [];
        } else if (fieldsList.indexOf('[') == 0) {
            fieldset = JSON.parse(fieldsList);                  
        }else{
            fieldsList = fieldsList.split(',');
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
                    'showLabel': showLabel
                }
                fieldset.push(newField);                
            })
        }
        fieldset.forEach(function(field){
            if(field.apiName){
                fields.push(field.apiName);                
            }
        })
        if (fields.indexOf('Name') == -1) {
            fields.push('Name');
        }
        component.set('v.fieldset', fieldset);
        component.set('v.programFields', fields.join(','));
        
        if (fields.indexOf('FieloPLT__ExternalURL__c') != -1) {
            helper.hasImageField = true;        
            helper.defaultImage = $A.get('$Resource.FieloPlt_Salesforce') + '/images/program.png';
        }
        
        component.set('v.registrationPrograms', programs);


        /* RECORD DETAIL */
        var recordDetailConfig = config.recordDetail;
        
        var recordDetailFieldsetConfig = component.get('v.recordDetailFieldset').trim();
        if(recordDetailFieldsetConfig.length > 0 && recordDetailFieldsetConfig.indexOf('[') == 0){
            recordDetailConfig.sections = JSON.parse(recordDetailFieldsetConfig);                
        } else if(recordDetailFieldsetConfig.length > 0){            
            var row = [];
            fieldsList = recordDetailFieldsetConfig.split(',');                
            fieldsList.forEach(function(field){
                nameAndType = field.split('/');
                apiName = nameAndType[0].trim();
                type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
                newField = {
                    'apiName': apiName,
                    'type': type,
                    'label': {},
                    'showLabel': true
                }
                row.push(newField);
            })
            recordDetailConfig.sections = [recordDetailConfig.sections[0]];                
            recordDetailConfig.sections[0].rows = [row];            
        }
        
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
        component.set('v.recordDetailConfig', recordDetailConfig);
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

        var filterFields = component.get('v.filterFields').trim();
        if (filterFields.length == 0) {
            filterFields = config.filterFields;
        }
        component.set('v.filterFieldset', filterFields);

        helper.getProgramLabel(component, event, helper);                
        var programs = component.get('v.programList');
        if (programs && programs.trim().length > 0) {
            programs = programs.split(',');
            programs.forEach(function(prog) {
                helper.availablePrograms[prog] = true;
            })
        }
    },
    register: function(component, event, helper){
        var checked = event.getParam('checked');
        component.set('v.agreementChecked', checked);
        var toastEvent = $A.get("e.force:showToast");
        if(checked){
            helper.registration(component, event, helper);
        }else{
            var errorMsg = $A.get("$Label.c.AgreementAccept");
            toastEvent.setParams({
                "title": errorMsg,
                "message": " ",
                "type": "error"
            });
            toastEvent.fire();
        }
    },
    toggleRegistration: function(component, event, helper){
        var userMembers = event.getParam('userMembers');
        helper.memberPrograms = {};        
        userMembers.forEach(function(member){
            helper.memberPrograms[member.FieloPLT__Program__c] = true;
        });
        helper.getPrograms(component, 0);
    },
    toggleAgreement: function(component, event, helper){   
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        var agreement = event.getParam('agreement');
        component.set('v.agreement', agreement);
        var hasAgreement = agreement ? true : false;
        component.set('v.hasAgreement', hasAgreement);
        if(!hasAgreement){
            helper.registration(component, event, helper); 
        }else{
            if(spinner){                
                spinner.setParam('show', false);
                spinner.fire();    
            }
            component.set('v.showAgreement', true);            
        }
    },
    updateProgramInfo: function(component, event, helper){
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        if(spinner){
            spinner.setParam('show', true);
            spinner.fire();    
        }
        var program = event.getParam('program');        
        component.set('v.program', program.Id);
        var agreementCmp = component.find("programAgreement");
        agreementCmp.updateProgram(program.Id);
    },
    showProgram: function(component, event, helper){
        var record = event.getParam('record');
        record = record.Id;
        helper.getProgramDetail(component, record);
    },
    paginator: function(component, event, helper) {
        var offset = event.getParam("offset");        
        helper.getPrograms(component, offset);
    },
    filter: function(component, event, helper) {
        component.set('v.dynamicFilter', event.getParam('condition'));
        component.set('v.orderBy', event.getParam('orderBy'));
        helper.getPrograms(component, 0, true);
    }
})