({
    doInit : function(component, event, helper) {
        var title, fields, fieldset;
        var config = component.get('v.configDefault');
        try{
            config = JSON.parse(config);
            
            var titleValue = component.get('v.memberBadgesTitle').trim();
            if(titleValue.length > 0){
                if (titleValue.indexOf('{') == 0) {
                    title = JSON.parse(titleValue);
                } else {
                    title = {
                        "value": titleValue,
                        "type": "text"
                    };                    
                }
            }
            if (title) {
                titleValue = '';
                var type = title.type.toLowerCase();
                var value = title.value;
                if(type == 'label'){
                    var label = '$Label.' + value;
                    titleValue = $A.get(label);
                    component.set('v.title', titleValue);                
                }else{
                    titleValue = value;
                    component.set('v.title', titleValue);
                }                
            }
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
            
        } catch(e) {
            component.set('v.error', e);
            component.set('v.showError', true);
        }
    },
    updateMember: function(component, event, helper){
        var member = event.getParam('member');
        component.set('v.member', member);
    }
})