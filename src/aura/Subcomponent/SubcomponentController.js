({
    doInit : function(component, event, helper) {
        var type = component.get('v.type');
        var record = component.get('v.record');
        var config = component.get('v.config');
        var name = component.get('v.name');            
        var fieldName = component.get('v.fieldName');
        $A.createComponent(
            type,
            {
                "record": record,
                "config": config,
                "name": name,
                "fieldName": fieldName                
            },
            function(newSubcomponent, status, errorMessage){
                //Add the new button to the body array
                if (status === "SUCCESS") {
                    var body = component.get("v.body");
                    body.push(newSubcomponent);
                    component.set("v.body", body);
                }
                else if (status === "INCOMPLETE") {
                    console.log("No response from server or client is offline.")
                    // Show offline error
                }
                    else if (status === "ERROR") {
                        console.log("Error: " + errorMessage);
                        // Show error message
                    }
            }
        );
        
    }
})