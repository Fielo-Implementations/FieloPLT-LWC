({
    selectOption: function(component, event, helper) {        
        var selectOptionEvent = component.getEvent("selectOption");
        if (selectOptionEvent) {
            var option = component.get('v.option');            
            selectOptionEvent.setParams({
                'option': option
            });
            selectOptionEvent.fire();
        }
    }
})