({
  doInit: function (component, event, helper) {
    var recordDetailConfig = component.get('v.config');
    var recordId = component.get('v.record').Id;
    if (recordDetailConfig) {
      if (!recordDetailConfig.view) {
        recordDetailConfig.view = 'custom';
      }
      var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
      var fieldLabels = component.get('v.labels');
      var sections = recordDetailConfig.sections;

      if (recordDetailConfig.subcomponents) {
        component.set('v.subcomponents', recordDetailConfig.subcomponents);
      }
      if (recordDetailConfig.relatedLists) {
        recordDetailConfig.relatedLists.forEach(function (related) {
          var whereCondition = '';

          if (!related.standard) {
            whereCondition = related.relationField + "='" + recordId + "'";
          }
          related.whereCondition = whereCondition;
        })
        component.set('v.listviews', recordDetailConfig.relatedLists);
      }
      sections.forEach(function (section) {
        var title = section.title;
        if (title) {
          var type = title.type.toLowerCase();
          var value = title.value;
          if (type == 'label') {
            var label = '$Label.' + value;
            section.titleValue = $A.get(label);
          } else {
            section.titleValue = value;
          }
        }
        section.rows.forEach(function (row) {
          row.forEach(function (field) {
            var labelType = field.label.type || 'default';
            if (labelType == 'default') {
              var labelApiName = field.apiName.split('.');
              if (labelApiName.length > 1) {
                labelApiName = labelApiName[0].replace('__r', '__c');
              }
              field.label.labelValue = fieldLabels[labelApiName];
            } else if (labelType == 'label') {
              var customLabel = '$Label.' + field.label.value;
              field.label.labelValue = $A.get(customLabel);
            } else {
              field.label.labelValue = field.label.value;
            }
          })
        })

      });

      if (recordDetailConfig.view == 'default') {
        var images = [];
        var fieldset = component.get('v.fieldset');
        fieldset.forEach(function (field) {
          if (field.type && field.type.toLowerCase() == 'image') {
            images.push(field);
          }
        });
        component.set('v.imageFields', images);
        component.set('v.showImages', images.length > 0);
      }

      component.set('v.sections', sections);
      component.set('v.showRecordDetail', true);
      if (spinner) {
        spinner.setParam('show', false);
        spinner.fire();
      }
    }
  },
  dismiss: function (component, event, helper) {
    var dismissEvent = component.getEvent("recordDetailDismiss");
    if (dismissEvent) {
      dismissEvent.fire();
    }
  }
})