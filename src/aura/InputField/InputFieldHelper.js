({
	isQuoted: {
		'address': true,
		'anytype': true,
		'base64': true,
		'boolean': false,
		'combobox': false,
		'currency': false,
		'datacategorygroupreference': false,
		'date': false,
		'datetime': false,
		'double': false,
		'email': true,
		'encryptedstring': true,
		'id': true,
		'integer': false,
		'multipicklist': true,
		'percent': false,
		'phone': true,
		'picklist': true,
		'reference': false,
		'string': true,
		'textarea': true,
		'time': false,
		'url': true
	},
	fieldMap: {
		'text': 'stringValue',
		'reference': 'reference',
		'checkbox': 'booleanValue',
		'number': 'decimalValue',
		'date': 'stringValue',
		'datetime': 'stringValue',
		'email': 'stringValue',
		'picklist': 'stringValue',
		'time': 'decimalValue',
		'url': 'stringValue'
	},
	setFieldValueByType: function (component, fieldValue) {
		var fieldMeta = component.get("v.fieldMeta");
		var fieldType = component.get('v.fieldMeta').attributes.inputType;

		if (this.fieldMap[fieldType] == 'stringValue') {
			component.set('v.stringValue', String(fieldValue));
		}
		if (this.fieldMap[fieldType] == 'reference') {
			var lookupComponent = component.get('v.lookupComponent');
			if (lookupComponent) {
				lookupComponent.pickRecord(String(fieldValue));
			}
		}
		if (this.fieldMap[fieldType] == 'booleanValue') {
			component.set('v.booleanValue', Boolean(fieldValue));
		}
		if (this.fieldMap[fieldType] == 'decimalValue') {
			component.set('v.decimalValue', Number(fieldValue).toFixed((component.get('v.fieldMeta').attributes.step.split('.')[1] || []).length));
		}
	},
	getFieldValueByType: function (component, fieldValue) {
		var fieldType = component.get('v.fieldMeta').attributes.inputType;
		var typedFieldValue;
		if (this.fieldMap[fieldType] == 'stringValue') {
			typedFieldValue = String(fieldValue);
		}
		if (this.fieldMap[fieldType] == 'reference') {
			var lookupComponent = component.get('v.lookupComponent');
			if (lookupComponent) {
				lookupComponent.pickRecord(String(fieldValue));
			}
		}
		if (this.fieldMap[fieldType] == 'booleanValue') {
			typedFieldValue = Boolean(fieldValue);
		}
		if (this.fieldMap[fieldType] == 'decimalValue') {
			typedFieldValue = Number(fieldValue);
		}
		return typedFieldValue;
	},
	fireFieldUpdate: function (component, fieldName, fieldValue) {
		try {
			var fieldMeta = component.get("v.fieldMeta");
			var compEvent = component.getEvent("fieldUpdate");
			var params = {};
			params.fieldName = fieldMeta.attributes.name;
			params.fieldValue = fieldValue;
			params.isQuoted = this.isQuoted[fieldMeta.attributes.inputType];
			params.jsType = fieldMeta.attributes.jsType;

			if (fieldValue === null || fieldValue === undefined || fieldValue == '') {
				params.isNull == true;
			}
			if (this.fieldMap[fieldMeta.attributes.inputType]) {
				params[this.fieldMap[fieldMeta.attributes.inputType]] = this.getFieldValueByType(component, fieldValue);
			}
			compEvent.setParams(params);
			component.set('v.fieldValue', fieldValue);
			compEvent.fire();
		} catch (e) {
			console.log(e);
		}
	},
	fireChangeEvent: function (component) {
		if (component.get('v.type') === 'picklist') {
			var compEvent = $A.get("e.c:ChangeEvent");

			compEvent.setParams({
				payload: {
					apiName: component.get('v.fieldName'),
					value: component.get('v.value')
				}
			});
			compEvent.fire();
		}
	}
})