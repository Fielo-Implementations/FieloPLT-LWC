({    
	previous: function(component, event, helper){        
		var page = component.get('v.page');
        var quantity = component.get('v.quantity');
        page --;
        component.set('v.page', page);
        var offset = page * quantity;
        var paging = component.getEvent("paging");
        paging.setParams({"offset": offset, "quantity": quantity});
        paging.fire();
    },
    next: function(component, event, helper){        
        var page = component.get('v.page');
        var quantity = component.get('v.quantity');
        page ++;
        component.set('v.page', page);
        var offset = page * quantity;                    
        var paging = component.getEvent("paging");
        paging.setParams({"offset": offset, "quantity": quantity});
        paging.fire();
    }
})