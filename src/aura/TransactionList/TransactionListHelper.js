({
    getTransactionList : function(component, offset) {        
        var spinner = $A.get("e.c:ToggleSpinnerEvent");        
        var memberId = component.get('v.member');    
        var condition = component.get('v.condition') || "[]";        
        var fields = component.get('v.fields');        
        var dynamicFilter = component.get('v.dynamicFilter');
        var quantity = component.get('v.quantity');        
        var orderBy = component.get('v.orderBy') || null;
        var paging = component.get('v.paging');
        if (paging) {
            quantity++;
        } else {
            quantity = null;
        }
        if(memberId){
            if(spinner){
                spinner.setParam('show', true);
                spinner.fire();    
            }   
            condition = JSON.parse(condition);
            if(dynamicFilter){                                
                dynamicFilter = JSON.parse(dynamicFilter);
                dynamicFilter.forEach(function(filter){
                    condition.push(filter);    
                })                                
            }                            
            condition = condition.length > 0 ? JSON.stringify(condition) : undefined;            
            memberId = memberId.Id;            
            var action = component.get("c.getTransactions");
            action.setParams({                
                "fieldsTransactions": fields,                
                'memberId': memberId,                
                "quantity": quantity,
                "offset": offset,
                "orderBy": orderBy,
                "dynamicFilter": condition
            });
            
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var toastEvent = $A.get("e.force:showToast");
                var spinner = $A.get("e.c:ToggleSpinnerEvent");
                var state = response.getState();                
                if (component.isValid() && state === "SUCCESS") {
                    //success                                  
                    var transactions = response.getReturnValue();                     
                    component.set('v.records', transactions);                                        
                    component.set("v.showRecords", true);                                        
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
    getTransactionDetail : function(component, transactionId) {
        var spinner = $A.get("e.c:ToggleSpinnerEvent");        
        var memberId = component.get('v.member');    
        var condition = component.get('v.condition') || "[]";        
        var fields = component.get('v.recordDetailFields');        
        var dynamicFilter = component.get('v.dynamicFilter');
        var listviews = component.get('v.recordDetailListviews') || {};             
        if(memberId){
            if(spinner){
                spinner.setParam('show', true);
                spinner.fire();
            }   
            condition = JSON.parse(condition);
            if(dynamicFilter){                                
                dynamicFilter.forEach(function(filter){
                    condition.push(filter);    
                })
            }
            condition = condition.length > 0 ? JSON.stringify(condition) : undefined;            
            memberId = memberId.Id;            
            var action = component.get("c.getTransactions");
            action.setParams({                
                "fieldsTransactions": fields,
                "fieldsPoint": Object.keys(listviews.FieloPLT__Points__r || {}),
                "fieldsRedemption": Object.keys(listviews.FieloPLT__Redemptions__r || {}),
                "fieldsBadgeMember": Object.keys(listviews.FieloPLT__BadgesMembers__r || {}),
                "fieldsRevertedTransaction": Object.keys(listviews.FieloPLT__Transactions__r || {}),
                "transactionIds": transactionId,
                'memberId': memberId,                
                "dynamicFilter": condition
            });
            
            // Add callback behavior for when response is received
            action.setCallback(this, function(response) {
                var toastEvent = $A.get("e.force:showToast");
                var spinner = $A.get("e.c:ToggleSpinnerEvent");
                var state = response.getState();                
                if (component.isValid() && state === "SUCCESS") {
                    //success                    
                    var transactionDetail = response.getReturnValue()[0];
                    var transactionDetailConfig = component.get('v.recordDetailConfig');
                    var transactionListviews = transactionDetailConfig.relatedLists || [];
                    transactionListviews.forEach(function(listview){
                        var listviewRecordsValue = null;
                        if(listview.objectRelation){
                            listviewRecordsValue = transactionDetail[listview.objectRelation] || [];
                        }                        
                        listview.records = listviewRecordsValue;                        
                    })
                    component.set('v.recordDetail', transactionDetail);
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
    }
})