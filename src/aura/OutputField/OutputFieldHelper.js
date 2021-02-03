({
	getSuffix : function(component) {        
		var action = component.get("c.getCommunitySuffix");
		// Add callback behavior for when response is received
		action.setCallback(this, function(response) {            
			var toastEvent = $A.get("e.force:showToast");			
			var state = response.getState();
			if (component.isValid() && state === "SUCCESS") {
				//success
				var suffix = response.getReturnValue();
				var content = component.get('v.content');
				if (suffix != '' && content && content.indexOf(suffix) != 1) {
					component.set('v.suffix', suffix);
				} 
				component.set('v.showImage', true);
			} else {
				var errorMsg = response.getError()[0].message;
				toastEvent.setParams({
					"title": errorMsg,
					"message": " ",
					"type": "error"
				});
				toastEvent.fire();                     
			}			     
		});            
		// Send action off to be executed
		$A.enqueueAction(action);
	},
	unescapeJsInHtml: function(string) {
        string && string.replace && (string = string.replace(/\\\\/g, '\\'), // eslint-disable-line no-unused-expressions
        string = string.replace(/\\'/g, '\''),
        string = string.replace(/\\n/g, '\n'),
        string = string.replace(/\\&#39;/g, '\''),
        string = string.replace(/&#39;/g, '\''),
        string = string.replace(/&quot;/g, '"'),
        string = string.replace(/&amp;/g, '&'));
        return string;
	  },

	getUserTimeZone : function(component) {
		var action = component.get("c.getUserTimeZone");
		action.setCallback(this, function(response) {
			var state = response.getState();
			if (component.isValid() &&  state === "SUCCESS") {
				var timeZoneResponse = response.getReturnValue();
				component.set("v.timeZone", timeZoneResponse);
			}
		});
		$A.enqueueAction(action);
	}
})