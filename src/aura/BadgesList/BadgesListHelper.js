({
    getBadgesList: function (component, offset) {
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        var member = component.get('v.member');        
        var status = component.get('v.status');
        var fields = component.get('v.fieldsBadges');
        var orderBy = component.get('v.orderBy') || null;
        var dynamicFilter = component.get('v.dynamicFilter');
        var paging = component.get('v.paging');
        var quantity = component.get('v.quantity');        
        if (paging) {
            quantity++;
        } else {
            quantity = null;
        }        
        if (member) {
            if (spinner) {
                spinner.setParam('show', true);
                spinner.fire();
            }

            var action = component.get("c.getMemberBadges");
            action.setParams({
                "fieldsBadge": fields,
                "fieldsBadgeMember": ['Name','CreatedDate','FieloPLT__Rule__r.Name','FieloPLT__ChallengeReward__r.Name', 'FieloPLT__ChallengeReward__r.FieloPLT__Challenge__r.Name', 'FieloPLT__ChallengeReward__r.FieloPLT__Mission__r.Name'],
                "fieldsChallengeReward": ['Name','FieloPLT__Challenge__r.Name', 'FieloPLT__Mission__r.Name'],
                "status": status,
                'memberId': member.Id,
                "quantity": quantity,
                "dynamicFilter": dynamicFilter,
                "orderBy": orderBy,
                "offset": offset
            });

            // Add callback behavior for when response is received
            action.setCallback(this, function (response) {

                var toastEvent = $A.get("e.force:showToast");
                var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
                var state = response.getState();
                if (component.isValid() && state === "SUCCESS") {
                    //success                       
                    var badges = JSON.parse(response.getReturnValue());
                    var newBadges = [];
                    badges.forEach(function (badge) {
                        badge.badge.achievable = status.toLowerCase() == 'achievable';
                        badge.badge.badgeMembersActive = badge.badgeMembersActive;
                        badge.badge.badgeMembersExpired = badge.badgeMembersExpired;
                        newBadges.push(badge.badge);
                    })
                    component.set('v.records', newBadges);                    
                } else {
                    var errorMsg = response.getError()[0].message;
                    toastEvent.setParams({
                        "title": errorMsg,
                        "message": " ",
                        "type": "error"
                    });
                    toastEvent.fire();
                }
                if (spinner) {
                    spinner.setParam('show', false);
                    spinner.fire();
                }
            });
            // Send action off to be executed
            $A.enqueueAction(action);
        }
    }
})