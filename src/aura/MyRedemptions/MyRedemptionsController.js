({
  doInit: function (component, event, helper) {
    var title, fields, fieldset;
    var config = component.get('v.configDefault');
    try {
      config = JSON.parse(config);
      // CHECK IF BASIC CONFIG OVERRIDES ADVANCED CONFIG
      // TITLE
      var titleValue = component.get('v.titleValue').trim();
      if (titleValue.length > 0) {
        if (titleValue.indexOf('{') == 0) {
          title = JSON.parse(titleValue);
        } else {
          title = {
            "value": component.get('v.titleValue'),
            "type": "text"
          }
        }
      }
      if (title) {
        titleValue = '';
        var type = title.type.toLowerCase();
        var value = title.value;
        if (type == 'label') {
          var label = '$Label.' + value;
          titleValue = $A.get(label);
          component.set('v.title', titleValue);
        } else {
          titleValue = value;
          component.set('v.title', titleValue);
        }
      }
      // TITLE

      if (!component.get('v.quantity')) {
        component.set('v.quantity', config.quantity);
      }

      fieldset = [], fields = [];

      var fieldsConfig = component.get('v.fields').trim();
      if (fieldsConfig.length == 0) {
        fieldset = config.fieldset;
      } else if (fieldsConfig.indexOf('[') == 0) {
        fieldset = JSON.parse(fieldsConfig);
      } else {
        var newField, nameAndType, apiName, type;
        var fieldsList = component.get('v.fields').split(',');
        fieldsList.forEach(function (field) {
          nameAndType = field.split('/');
          apiName = nameAndType[0].trim();
          type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
          newField = {
            'apiName': apiName,
            'type': type,
            'label': {},
            'showLabel': true
          }
          fieldset.push(newField);
        })
      }
      fieldset.forEach(function (field) {
        if (fields.indexOf(field.apiName) == -1) {
          fields.push(field.apiName);
        }
      })
      component.set('v.fieldset', fieldset);
      component.set('v.fields', fields.join(','));

      /* RECORD DETAIL */
      var recordDetailConfig = config.recordDetail;
      var recordDetailFieldsetConfig = component.get('v.recordDetailFieldset').trim();
      if (recordDetailFieldsetConfig.length > 0 && recordDetailFieldsetConfig.indexOf('[') == 0) {
        recordDetailConfig.sections = JSON.parse(recordDetailFieldsetConfig);
      } else if (recordDetailFieldsetConfig.length > 0) {
        var row = [];
        fieldsList = recordDetailFieldsetConfig.split(',');
        fieldsList.forEach(function (field) {
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
        if (!recordDetailConfig.sections[0]) {
          recordDetailConfig.sections[0] = {};
        }
        recordDetailConfig.sections[0].rows = [row];
      }

      var recordDetailFields = {
        'Name': true
      };
      recordDetailConfig.sections.forEach(function (section) {
        section.rows.forEach(function (row) {
          row.forEach(function (f) {
            recordDetailFields[f.apiName] = true;
          })
        })
      })

      component.set('v.recordDetailFields', Object.keys(recordDetailFields));
      var listviews = recordDetailConfig.relatedLists || [];
      var listviewsFields = {},
        newListViews = [],
        redemptionItemRelatedActive = false;
      var showRedemptionItemRelated = component.get('v.showRedemptionItemRelated');
      var redemptionItemRelatedFields = component.get('v.redemptionItemRelatedFields').trim();
      if (redemptionItemRelatedFields.length > 0) {
        if (showRedemptionItemRelated) {
          var newRelated = {};
          newRelated.fieldset = [];
          newRelated.objectRelation = 'FieloPLT__RedemptionItems__r';
          newRelated.objectAPIName = 'FieloPLT__RedemptionItem__c';
          listviewsFields[newRelated.objectRelation] = {};
          if (redemptionItemRelatedFields.indexOf('[') == 0) {
            newRelated.fieldset = JSON.parse(redemptionItemRelatedFields);
          } else {
            redemptionItemRelatedFields = redemptionItemRelatedFields.split(',');
            redemptionItemRelatedFields.forEach(function (ruleField) {
              nameAndType = ruleField.split('/');
              apiName = nameAndType[0].trim();
              type = nameAndType[1] ? nameAndType[1].trim().toLowerCase() : 'output';
              var showLabel = type == 'image' ? false : true;
              newField = {
                'apiName': apiName,
                'type': type,
                'label': {},
                'showLabel': showLabel
              }
              newRelated.fieldset.push(newField);
            })

          }
          newRelated.fieldset.forEach(function (field) {
            listviewsFields[newRelated.objectRelation][field.apiName] = true;
            if (field.apiName == 'FieloPLT__Reward__r.FieloPLT__ExternalURL__c') {
              helper.hasImageField = true;
              helper.defaultImage = $A.get('$Resource.FieloPlt_Salesforce') + '/images/reward.png';
            }
          })
          newRelated.standard = true;
          newListViews.push(newRelated);
          redemptionItemRelatedActive = true;
        }
      }
      listviews.forEach(function (listview) {
        if (listview.title) {
          var titleType = listview.title.type.toLowerCase();
          var titleValue = listview.title.value;
          if (titleType == 'label') {
            var titleLabel = '$Label.' + titleValue;
            listview.titleValue = $A.get(titleLabel);
          } else {
            listview.titleValue = titleValue;
          }
        }
        if (listview.objectRelation && showRedemptionItemRelated && !redemptionItemRelatedActive) {
          listview.standard = true;
          listviewsFields[listview.objectRelation] = {};
          listview.fieldset.forEach(function (field) {
            listviewsFields[listview.objectRelation][field.apiName] = true;
          })
          newListViews.push(listview);
        } else if (!listview.objectRelation) {
          newListViews.push(listview);
        }
      });

      component.set('v.recordDetailListviews', listviewsFields);
      recordDetailConfig.relatedLists = newListViews;
      component.set('v.recordDetailConfig', recordDetailConfig);
      /* FILTER */
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
      /* RECORD DETAIL */
      var member = component.get('v.member');
      if (member) {
        helper.getPointTypes(component);
      }
      
      // sets overrides helptexts
      component.set(
        'v.overrideHelptext',
        {
          'fieloplt__status__c': $A.get('$Label.c.FilterRedemptionStatusHelpText')
        }
      );


      var defaultPicklistOptions = {
        'FieloPLT__Status__c': {
          'defaultPicklistValue': $A.get("$Label.c.All")
        }
      };

      component.set('v.defaultPicklistOptions', defaultPicklistOptions);

    } catch (e) {
      component.set('v.error', e);
      component.set('v.showError', true);
    }
  },
  updateMember: function (component, event, helper) {
    component.set('v.member', event.getParam('member'));
    helper.getPointTypes(component);
  },
  paginator: function (component, event, helper) {
    helper.getRedemptions(component, event.getParam("offset"));
  },
  showRedemption: function (component, event, helper) {
    helper.getRedemptionDetail(component, event.getParam('record').Id);
  },
  filter: function (component, event, helper) {
    var orderBy = event.getParam('orderBy');
    if (orderBy === '') {
        orderBy = 'CreatedDate DESC';
    }
    component.set('v.dynamicFilter', event.getParam('condition'));
    component.set('v.orderBy', orderBy);
    helper.getRedemptions(component, 0);
  },
  handleBackClick: function (component, event, helper) {
    var backEvent = component.getEvent("backToCatalog");
    if (backEvent) {
        backEvent.fire();
    }
  }
})