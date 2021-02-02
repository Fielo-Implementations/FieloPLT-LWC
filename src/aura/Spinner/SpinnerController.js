({
	toggleSpinner : function(component, event, helper) {
		var show = event.getParam('show');
        var spinner = component.find('fieloSpinner');        
        if(show){
        	$A.util.removeClass(spinner, 'slds-hide');    
        } else {
        	$A.util.addClass(spinner, 'slds-hide');    
        }                
	}
})