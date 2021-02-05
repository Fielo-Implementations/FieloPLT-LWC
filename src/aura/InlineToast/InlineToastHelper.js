({
	show : function(component) {
		component.set('v.visible', true);
	},
	hide : function(component) {
		component.set('v.visible', false);
	},
	config: function(component, config) {
		// merges default config with new one
		config = Object.assign({}, {
			title: '',
			message: '',
			messageData: [],
			variant: 'info',
			// mode: 'dismissable'
		}, config);

		config.icon = 'utility:' + config.variant.toLowerCase();
		config.iconClass = 'slds-icon_container slds-icon-utility-' + config.variant.toLowerCase() +
			' slds-m-right_small slds-no-flex slds-align-top';
		config.themeClass = 'slds-notify slds-notify_toast slds-theme_' + config.variant.toLowerCase();

		component.set('v.config', config);
	}
})