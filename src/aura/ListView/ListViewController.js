({    
    doInit : function(component, event, helper) {        
        var paging = component.get('v.paging');
        if(typeof paging == 'undefined'){
            paging = true;
        }
        component.set('v.paging', paging);
        var quantity = component.get('v.quantity') || 5;
        component.set('v.quantity', quantity);        
        helper.getLabels(component, event, helper);        
        var records = component.get('v.records');        
        if(records){
            helper.setRecords(component, event);                
        } else {
            helper.queryRecords(component, event, helper);
        }
        
        helper.originalLayout = component.get('v.layout');
        var resizeEnd;
        window.addEventListener('resize',function(){
            clearTimeout(resizeEnd);
            resizeEnd = setTimeout(
                $A.getCallback(function() {
                    helper.setResponsiveLayout(component);
                }), 50
            );
        });
    },
    showItemsChangeHandler: function(component, event, helper){
        helper.setResponsiveLayout(component);
    },
    toggleLayout: function(component, event, helper){
        var layout = component.get('v.layout');
        if (layout.toLowerCase() == 'table'){
            layout = 'grid';
        } else {
            layout = 'table';
        }
        helper.originalLayout = layout;
        component.set('v.layout', layout);
    },
    updateRecords: function(component, event, helper){
        helper.setRecords(component, event);
    },
    dismissDetail: function(component, event, helper){
        component.set('v.recordDetail', null);
        component.set('v.showRecord', false);       
    },
    showRecordDetail: function(component, event, helper){        
        component.set('v.showRecord', true);
    },
    backToList: function(component, event, helper){
        component.set('v.showRecord', false);
        component.set('v.displaySubcomponent', false);
        var backEvent = component.getEvent('backEvent');
        if (backEvent) {
            backEvent.fire();
        }
    },
    backToDetail: function(component, event, helper) {
        component.set('v.displaySubcomponent', false);
    },
    showSubdetail: function(component, event, helper) {
        var subcomponent = event.getParam('subcomponent');
        component.set('v.subdetail', subcomponent);
        component.set('v.displaySubcomponent', true);
    },
    toggle: function(component, event, helper){        
        var id = event.currentTarget.id;
        var accordionBody = component.find('accordionBody');
        $A.util.toggleClass(event.currentTarget, 'closed');
        if (accordionBody.length) {
            accordionBody.forEach(function(body){
                var element = body.getElement();
                if (element.dataset.recordId == id) {
                    $A.util.toggleClass(element, 'closed');
                }            
            })
        } else {
            $A.util.toggleClass(accordionBody.getElement(), 'closed');
        }        
    },
    collapseAll: function(component, event, helper) {
        var accordionBody = component.find('accordionBody');
        var accordionHeader = component.find('accordionHeader');
        var collapsed = component.get('v.collapsed');
        if (accordionBody.length) {
            accordionBody.forEach(function(body){
                if (collapsed) {
                    $A.util.removeClass(body.getElement(), 'closed');
                } else {                
                    $A.util.addClass(body.getElement(), 'closed');
                }
            })
        } else {
            if (collapsed) {
                $A.util.removeClass(accordionBody.getElement(), 'closed');
            } else {                
                $A.util.addClass(accordionBody.getElement(), 'closed');
            }
        }
        if (accordionHeader.length) {
            accordionHeader.forEach(function(header){
                $A.util.addClass(header.getElement(), 'closed');
                if (collapsed) {
                    $A.util.removeClass(header.getElement(), 'closed');
                } else {                
                    $A.util.addClass(header.getElement(), 'closed');
                }
            })
        } else {
            if (collapsed) {
                $A.util.removeClass(accordionHeader.getElement(), 'closed');
            } else {                
                $A.util.addClass(accordionHeader.getElement(), 'closed');
            }            
        }
        component.set('v.collapsed', !collapsed);
    }
})