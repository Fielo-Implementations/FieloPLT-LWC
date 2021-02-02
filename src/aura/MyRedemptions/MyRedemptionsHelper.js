({
    hasImageField: false,
    defaultImage: '',
    pointTypes: '',
    getRedemptions : function(component, offset) {
        var spinner = $A.get("e.c:ToggleSpinnerEvent");
        var memberId = component.get('v.member');
        var quantity = component.get('v.quantity');
        var orderBy = component.get('v.orderBy') || null;
        var paging = component.get('v.paging');
        if (paging) {
            quantity++;
        } else {
            quantity = null;
        }
        var dynamicFilter = component.get('v.dynamicFilter');
        var listviews = component.get('v.recordDetailListviews') || {};
        if(memberId){
            if(spinner){
                spinner.setParam('show', true);
                spinner.fire();
            }

            memberId = memberId.Id;
            var fieldsRedemption = component.get('v.fields').split(',');
            var action = component.get("c.getMemberRedemptions");
            action.setParams({
                "fieldsRedemption": fieldsRedemption,
                "fieldsRedemptionItem": Object.keys(listviews.FieloPLT__RedemptionItems__r || {}),
                'memberId': memberId,
                "quantity": quantity,
                "offset": offset,
                "orderBy": orderBy,
                "dynamicFilter": dynamicFilter
            });

            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var toastEvent = $A.get("e.force:showToast");
                var spinner = $A.get("e.c:ToggleSpinnerEvent");
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    //success
                    var redemptions = response.getReturnValue();
                    for(var i=0;i<redemptions.length;i++){
                        if (redemptions[i].CreatedDate){
                            redemptions[i].CreatedDate = redemptions[i].CreatedDate.slice(0,10);
                        }
                    }
                    var redemptionDetailConfig = component.get('v.recordDetailConfig');
                    var redemptionListviews = redemptionDetailConfig.relatedLists || [];
                    redemptions.forEach(function(redemption){
                        redemptionListviews.forEach(function(listview){
                            var newListView = {};
                            var listviewRecordsValue = null;
                            if(listview.objectRelation){
                                listviewRecordsValue = redemption[listview.objectRelation] || [];
                            }
                            if (!redemption.relatedLists) {
                                redemption.relatedLists = [];
                            }                                                        
                            if (this.hasImageField) {
                                listviewRecordsValue.forEach(function(redemptionItem){                                    
                                    if (redemptionItem.FieloPLT__Reward__r && !redemptionItem.FieloPLT__Reward__r.FieloPLT__ExternalURL__c) {
                                        redemptionItem.FieloPLT__Reward__r.FieloPLT__ExternalURL__c = this.defaultImage;
                                    }
                                }, this)            
                            }
                            newListView.layout = 'grid';
                            newListView.records = listviewRecordsValue;
                            newListView.titleValue = listview.titleValue;
                            newListView.objectAPIName = listview.objectAPIName;
                            newListView.fieldset = listview.fieldset;
                            redemption.relatedLists.push(newListView);
                        }, this)
                    }, this)
                    component.set('v.records', redemptions);
                    component.set('v.showRecords', true);
                } else {
                    var errorMsg = response.getError()[0].message;
                    toastEvent.setParams({
                        "title": errorMsg,
                        "message": " ",
                        "type": "error"
                    });
                    toastEvent.fire();
                }
                if(spinner){
                    spinner.setParam('show', false);
                    spinner.fire();
                }
            });
            // Send action off to be executed
            $A.enqueueAction(action);
        }

    },
    getRedemptionDetail : function(component, redemptionId) {
        var spinner = $A.get("e.c:ToggleSpinnerEvent");
        var memberId = component.get('v.member');
        var condition = component.get('v.condition');
        var fieldsRedemption = component.get('v.recordDetailFields');
        var dynamicFilter = component.get('v.dynamicFilter');
        var listviews = component.get('v.recordDetailListviews') || {};
        if(memberId){
            if(spinner){
                spinner.setParam('show', true);
                spinner.fire();
            }
            memberId = memberId.Id;
            var action = component.get("c.getMemberRedemptions");
            action.setParams({
                "fieldsRedemption": fieldsRedemption,
                "fieldsRedemptionItem": Object.keys(listviews.FieloPLT__RedemptionItems__r || {}),
                "redemptionIds": redemptionId,
                "memberId": memberId,
                "dynamicFilter": dynamicFilter

            });
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var toastEvent = $A.get("e.force:showToast");
                var spinner = $A.get("e.c:ToggleSpinnerEvent");
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    //success
                    var redemptionDetail = response.getReturnValue()[0];
                    var redemptionDetailConfig = component.get('v.recordDetailConfig');
                    var redemptionListviews = redemptionDetailConfig.relatedLists || [];
                    redemptionListviews.forEach(function(listview){
                        var listviewRecordsValue = null;
                        if(listview.objectRelation){
                            listviewRecordsValue = redemptionDetail[listview.objectRelation] || [];
                        }
                        if (listviewRecordsValue && this.hasImageField) {                            
                            listviewRecordsValue.forEach(function(redemptionItem){                                    
                                if (redemptionItem.FieloPLT__Reward__r && !redemptionItem.FieloPLT__Reward__r.FieloPLT__ExternalURL__c) {
                                    redemptionItem.FieloPLT__Reward__r.FieloPLT__ExternalURL__c = this.defaultImage;
                                }
                            }, this)
                        }
                        listview.records = listviewRecordsValue;
                    }, this)
                    component.set('v.recordDetail', redemptionDetail);
                } else {
                    var errorMsg = response.getError()[0].message;
                    toastEvent.setParams({
                        "title": errorMsg,
                        "message": " ",
                        "type": "error"
                    });
                    toastEvent.fire();
                }
                if(spinner){
                    spinner.setParam('show', false);
                    spinner.fire();
                }
            });
            // Send action off to be executed
            $A.enqueueAction(action);
        }
    },
    getPointTypes: function (component) {
    var member = component.get('v.member');

    var pointTypes = component.get("c.getPointTypes");
    pointTypes.setParams({'memberId': member.Id});

    // Add callback behavior for when response is received
    pointTypes.setCallback(this, function(response) {
      var spinner = $A.get("e.c:ToggleSpinnerEvent");
      if (
        component.isValid() &&
        response.getState() === "SUCCESS"
      ) {
        // success
        // Obtain actual points

        var fieldset = component.get('v.fieldset');
        var recordDetailFields = component.get('v.recordDetailFields');
        var redemptionDetailConfig = component.get('v.recordDetailConfig');

        this.pointTypes = JSON.stringify(response.getReturnValue());
        fieldset.forEach(this.addPointTypeClass.bind(this));
        recordDetailFields.forEach(this.addPointTypeClass.bind(this));

        if (redemptionDetailConfig.relatedLists) {
            redemptionDetailConfig.relatedLists.forEach(function(list) {
                list.fieldset.forEach(this.addPointTypeClass.bind(this));
            }, this);
        }

        component.set('v.fieldset', fieldset);
        component.set('v.recordDetailFields', recordDetailFields);
        component.set('v.recordDetailConfig', redemptionDetailConfig);

        this.getRedemptions(component, 0);
      }
      if(spinner){
        spinner.setParam('show', false);
        spinner.fire();
      }
    });

    // Send action off to be executed
    var spinner = $A.get("e.c:ToggleSpinnerEvent");
    if(spinner){
      spinner.setParam('show', true);
      spinner.fire();
    }
    $A.enqueueAction(pointTypes);
  },
  addPointTypeClass: function(item) {
    if(this.pointTypes.indexOf(item.apiName) > -1) {
        if (!item.cssClass) {
          item.cssClass = '';
        }
        item.cssClass += ' fielo-field--is-point-type';
      }
  }
})