({	
	doInit: function (component, event, helper) {
		if (component.get('v.type') === 'picklist') {
			if ( 
				!( (component.get('v.required')=='true') && (component.get('v.defaultValue') != '') ) && 
				!component.get('v.disableSelectAnOption') &&
				!component.get('v.picklistEntries').some(element=> element.value == '')
			){
				component.get('v.picklistEntries').unshift(
					{
						label: $A.get("$Label.c.SelectAnOption"),
						value: ""
					})
			}
			component.set('v.renderPicklistEntries', component.get('v.picklistEntries'));
		}
		if (
			component.get('v.type') === 'picklist' &&
			component.get('v.metadata') &&
			component.get('v.metadata').controllerField
		) {
				if (component.get('v.value')) {
					var compEvent = $A.get("e.c:GetInputValue");

					compEvent.setParams({
						payload: {
							apiName: component.get('v.metadata').controllerField
						}
					});
					compEvent.fire();
				} else {
					component.find('picklist').set('v.disabled', true);
				}
		}

		if (
			component.get('v.type') === 'picklist' &&
			(component.get('v.value') === undefined ||
			component.get('v.value') === '')
			) {
			if (component.get('v.defaultValue')) {
				component.set('v.value', component.get('v.defaultValue'));
			} else {
				component.set('v.value', '');
			}
		}

	},
	handleGetInputValue: function (component, event, helper) {
		if (
			component.get('v.type') === 'picklist' &&
			component.get('v.fieldName') ===  event.getParam("payload").apiName
		) {
			helper.fireChangeEvent(component);
		}
	},
	handleChangeValue: function (component, event, helper) {
		helper.fireChangeEvent(component);
	},
	handleChangeEvent: function (component, event, helper) {
		if (
			component.get('v.type') === 'picklist' &&
			component.get('v.metadata') &&
			component.get('v.metadata').controllerField &&
			component.get('v.metadata').controllerField === event.getParam("payload").apiName
			) {
				if (component.get('v.metadata').validPicklistOptions[event.getParam("payload").value]) {
					component.set(
						'v.renderPicklistEntries',
						component.get('v.picklistEntries').filter((item) => {
							return component.get('v.metadata').validPicklistOptions[event.getParam("payload").value].includes(item.value)
						})
					);
				} else {
						component.set(
							'v.renderPicklistEntries',
							[]
						);
						component.set('v.value', '');
				}
				component.find('picklist').set('v.disabled', false);
		}
	},
	get: function(component, event, helper) {		
		var type = component.get('v.type');
		var value = component.get('v.value');
		if (type == 'reference') {			
			value = component.find('lookupField').getValue();
			value = value ? value.Id : '';
			component.set('v.value', value);
		} else if (type == 'checkbox') {
			value = component.get('v.checked');
		}
		var res = {
			"fieldName": component.get('v.fieldName'),
			"value": value,
			"type": type
		}        
		return res;
	}
})