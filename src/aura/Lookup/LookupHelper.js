({
    getOptions: function(component, searchValue, cache) {
        var lookupObjectName = component.get('v.field').attributes.referenceTo;         
        var getRecords = component.get('c.getRecords');
        getRecords.setParams({
            'objectName': lookupObjectName,
            'whereClause': searchValue
        });
        getRecords.setCallback(this, function(response) {            
            var state = response.getState();
            if (component.isValid() && state === 'SUCCESS') {                    
                var records = response.getReturnValue();
                var newSearchValue = component.get('v.searchValue') || '';
                if ((newSearchValue.trim() != '' && !cache) || cache) {
                    component.set('v.options', records);
                }
                if (cache) {
                    component.set('v.optionsCache', records);
                }                
            }else {
                var errorMsg = response.getError()[0].message;
                var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": errorMsg,
                    "message": " ",
                    "type": "error"
                });
                toastEvent.fire(); 
                if(spinner){
                    spinner.setParam('show', false);
                    spinner.fire();    
                } 
            }            
        });
        $A.enqueueAction(getRecords);
    },
    show: function(component) {        
        var combobox = component.find('fielo-lookup-combobox');        
        $A.util.addClass(combobox, 'slds-is-open');        
    },
    hide: function(component) {        
        var combobox = component.find('fielo-lookup-combobox');
        $A.util.removeClass(combobox, 'slds-is-open');        
    },    
    selectOption: function(component, record) {                
        component.set('v.selectedRecord', record);
        this.hide(component);
    },
    filterOptions: function(component) {
        var searchValue = component.get('v.searchValue');        
        this.getOptions(component, searchValue, false);        
    }    
})