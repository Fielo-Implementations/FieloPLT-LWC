({
    doInit : function(component, event, helper) {
        var type = component.get('v.type');
        var record = component.get('v.record');
        var fieldName = component.get('v.fieldName');
        var blankValue = component.get('v.blankValue');
        var content = '';
        if(fieldName){
            fieldName = fieldName.split('.');
            content = record[fieldName[0]];
            if(content){
                for(var i = 1; i < fieldName.length; i++){
                    if (content[fieldName[i]]) {
                        content = content[fieldName[i]] ;   
                    } else {
                        // Se vuelve a setear '', por si se esta buscando una relacion
                        // por ejemplo, campo__r.campo1__r.Name
                        // esta definido campo__r (porque dentro de esa relacion esta el campo ID, pero el campo Name no)
                        // como el campo no existe, va a quedar con el valor anterior, que es el de la relacion
                        // content = campo__r que es un objeto, cuando quiera asignarlo al v.content que es string, se rompe
                        content = '';
                    }
                }
            }
            if ( (!content || content === '') && blankValue !== '' ) {
                content = blankValue;
            }
            if (type === 'output') {
                content = helper.unescapeJsInHtml(content);
            }
            component.set('v.content', content);
        }         
        if(!type || type === '') {
            component.set('v.type', 'output')
        } else if (type.toLowerCase() == 'image' && content && content.indexOf('/') == 0) {
            helper.getSuffix(component);
        } else if (type.toLowerCase() == 'image') {
            component.set('v.showImage', true);
        }
        
        if(type == 'subcomponent'){
            component.set('v.showSubcomponent', true);
        } else if (type === 'datetime') {
            helper.getUserTimeZone(component);
        } else if (type === 'date') {
            component.set('v.dateFormat', $A.get("$Locale.shortDateFormat"));
        }
        
    }
})