({
	doInit: function(component, event, helper){        
		var recordId = component.get('v.recordId');
		if (recordId) {
			var mode = component.get('v.mode');
			var action;
			if (mode == 'registration') {
				action = component.get('c.getActiveConsents');
			}else {
				action = component.get('c.getConsents');
			}
			helper.getConsents(component, component.get('v.recordId'), action);
			
		}
	},
	updateMember: function (component, event, helper) {
		
		helper.getConsents(
			component, event.getParam('member').Id, 
			component.get('c.getConsents')
		);
	},
	dismiss : function(component, event, helper) {
		component.set('v.show', false);
	},
    submit: function(component, event, helper){        
        helper.submit(component, event, helper);
	},
	get: function(component, event, helper) {
		return helper.getValues(component, event, helper);
	}
})