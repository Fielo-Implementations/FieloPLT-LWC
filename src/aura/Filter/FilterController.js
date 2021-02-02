({
  doInit: function (component, event, helper) {
    var fields = component.get('v.fields');
    var fieldset = component.get('v.fieldset') || [];

    var newFields = [];
    var fieldNames = '';

    var sortByFieldset = component.get('v.sortByFieldset');
    // Adds items to field name that only has apiName
    sortByFieldset.forEach(function (item) {
      if (item.apiName && fieldNames.indexOf(item.apiName) == -1) {
        if (fieldNames !== '') {
          fieldNames += ',';
        }
        fieldNames += item.apiName;
      }
    });

    if ((!fieldset || !fieldset.length) && fields != '' && !$A.util.isUndefinedOrNull(fields)) {

      fields.split(',').forEach(function (field) {
        field = field.trim();
        var fieldSplit = field.split('/');
        if (fieldSplit.length > 1) {
          helper.rangeFields[fieldSplit[0].toLowerCase()] = true;
        }
        newFields.push(fieldSplit[0]);
      })
      if (fieldNames !== '') {
        fieldNames += ',';
      }
      fieldNames += newFields.join(',');

      var objectName = component.get('v.objectAPIName');
      var fieldsAction = component.get('c.getFilterFields');
      fieldsAction.setParams({
        'objectName': objectName,
        'fieldNames': fieldNames
      });
      // Add callback behavior for when response is received
      fieldsAction.setCallback(this, function (response) {
        var toastEvent = $A.get("e.force:showToast");
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        var state = response.getState();
        var fields = component.get('v.fields');
        var overrideHelptext = component.get('v.overrideHelptext') || {};
        var sortByFieldset = component.get('v.sortByFieldset')
          .reduce(
            function(map, obj) {
              if (obj.apiName) {
                map[obj.apiName.toLowerCase()] = obj;
              }
              return map;
            },
            {}
          );

        var sortByEntries = [];

        if (component.isValid() && state === "SUCCESS") {
          //success
          var defaultOptions = component.get('v.defaultOptions');
          var newFilterFields = [];
          var filterFields = response.getReturnValue();
          filterFields = JSON.parse(filterFields).fields;
          filterFields.forEach(function (field) {
            if (
              sortByFieldset[field.attributes.name.toLowerCase()] &&
              sortByFieldset[field.attributes.name.toLowerCase()].type != 'image'
            ) {
                sortByEntries.push({
                  label: field.attributes.label + ' ↑',
                  value: field.attributes.name + ' ASC'
                });
                sortByEntries.push({
                  label: field.attributes.label  + ' ↓',
                  value: field.attributes.name  + ' DESC'
                });
            }

            // sets range
            if (helper.rangeFields[field.attributes.name.toLowerCase()]) {
              field.type = "range";
            }
            // removes if it isn't a filter element
            if (fields.toLowerCase().indexOf(field.attributes.name.toLowerCase()) != -1) {
              if (defaultOptions && defaultOptions[field.attributes.name] && field.attributes.inputType == 'picklist') {
                var defaultFieldOptions = defaultOptions[field.attributes.name].options;
                var defaultPicklistValue = defaultOptions[field.attributes.name].defaultPicklistValue;              
                var defaultValue = defaultOptions[field.attributes.name].defaultValue;
                if (defaultFieldOptions) {
                  var newPicklistEntries = [];
                  field.picklistentries.forEach(function(entry){
                    if (defaultFieldOptions[entry.value]) {
                      newPicklistEntries.push(entry);
                    }
                  });
                  field.picklistentries = newPicklistEntries;
                }
                if (defaultPicklistValue) {
                  field.defaultPicklistValue = defaultPicklistValue;
                }
                if (defaultValue) {
                  field.defaultValue = defaultValue;
                }
              }
              newFilterFields.push(field);
            }

            // Overrides help texts
            
            if (overrideHelptext[field.attributes.name.toLowerCase()]) {
              field.attributes.helpText =
                overrideHelptext[field.attributes.name.toLowerCase()];
            }
          });

          component.set('v.sortByEntries', sortByEntries);
          component.set('v.fieldset', newFilterFields);
          component.set('v.showFilter', true);
        } else {
          var errorMsg = response.getError()[0].message;
          toastEvent.setParams({
            "title": errorMsg,
            "message": " ",
            "type": "error"
          });
          toastEvent.fire();
        }
        if (spinner) {
          spinner.setParam('show', false);
          spinner.fire();
        }
      });
      
      // Send action off to be executed
      $A.enqueueAction(fieldsAction);
    } else if(fieldset && fieldset.length) {
      component.set('v.showFilter', true);
    }
  },
  toggle: function(component, event, helper){
      var close = component.get('v.filterClosed');
      if (close)
          component.set('v.filterClosed',false);
      else
          component.set('v.filterClosed',true);
    },
  filter: function (component, event, helper) {
    var condition, newCondition, fieldValue,  filterValues,  filterEvent, rangeInputsFrom, rangeInputsTo;
    var filterConditions = [];
    rangeInputsFrom = component.find('rangeInputFrom');
    if (rangeInputsFrom) {
      if (!rangeInputsFrom.length) {
        rangeInputsFrom = [rangeInputsFrom];
      }
      rangeInputsFrom.forEach(function (rangeF) {
        fieldValue = rangeF.getValue();
        var value = fieldValue.value;
        if (value) {
          if (fieldValue.type == 'datetime') {
            value += 'T00:00:00Z';
          }
          newCondition = {
            'field': fieldValue.fieldName,
            'operator': '>=',
            'value': value
          }
          filterConditions.push(newCondition);
        }
      })
    }
    rangeInputsTo = component.find('rangeInputTo');
    if (rangeInputsTo) {
      if (!rangeInputsTo.length) {
        rangeInputsTo = [rangeInputsTo];
      }
      rangeInputsTo.forEach(function (rangeT) {
        fieldValue = rangeT.getValue();
        var value = fieldValue.value;
        if (value) {
          if (fieldValue.type == 'datetime') {
            value += 'T23:59:59Z';
          }
          newCondition = {
            'field': fieldValue.fieldName,
            'operator': '<=',
            'value': value
          }
          filterConditions.push(newCondition);
        }
      })
    }
    filterValues = component.find('filterInput');
    if (filterValues) {
      if (!filterValues.length) {
        filterValues = [filterValues];
      }
      filterValues.forEach(function (field) {
        fieldValue = field.getValue();
        if (fieldValue.value) {
          newCondition = {
            'field': fieldValue.fieldName,
            'operator':(field.get('v.type')=='text')?'like':'equals',
            'value': fieldValue.value
          }
          filterConditions.push(newCondition);
        }
      })
    }
    condition = JSON.stringify(filterConditions);
    condition = condition == '[]' ? '' : condition;
    component.set('v.condition', condition);
    filterEvent = component.getEvent("filterRecords");
    if (filterEvent) {
      var orderBy = component.find('fielo-filter__sort-by');
            var orderByValue = '';
            if (orderBy) {
                orderByValue = orderBy.getValue().value; 
            }
            filterEvent.setParams({
                'condition': condition,
                'orderBy' : orderByValue
            });      
      filterEvent.fire();
    }
  }
})
