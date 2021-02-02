({
	doInit : function(component, event, helper) {
        var record = component.get('v.record');
        if(record.disabled){
            component.set('v.disabled', true);
        }
        if(record.active){
            component.set('v.active', true);
        }
	}
})