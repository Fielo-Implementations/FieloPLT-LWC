({
    doInit: function(component, event, helper) {
        try{            
            helper.getOptions(component, '', true);                        
        } catch(e) {
            console.log(e);
        }
    },
    showOptions: function(component, event, helper) {
        helper.show(component);
    },
    hideOptions: function(component, event, helper) {
        helper.hide(component);
    },
    optionSelected: function(component, event, helper) {                
        var option = event.getParam('option');
        helper.selectOption(component, option);        
    },
    removeRecord: function(component, event, helper) {                
        var options = component.get('v.optionsCache');
        component.set('v.selectedRecord', null);
        component.set('v.searchValue', '');
        component.set('v.options', options);        
    },    
    filterRecords: function(component, event, helper) {        
        var searchValue = event.target.value;
        component.set('v.searchValue', searchValue);
        console.log(searchValue);        
        if (searchValue.trim() == '') {
            var records = component.get('v.optionsCache');
            component.set('v.options', records);
        } else {            
        	helper.filterOptions(component);    
        }        
    },
    getValue: function(component, event, helper) {
        return component.get('v.selectedRecord');
    }    
})