({
    programs: {
        
    },
    members: function (component, event, refresh, helper) {
        
        var fields = component.get('v.fields');
        var action = component.get("c.getMembers");
        var memberId = window.localStorage.getItem('member');
        var joinedMember = window.localStorage.getItem('joinedMember');
        var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        action.setParams({
            'fieldset': fields
        })
        // Add callback behavior for when response is received
        action.setCallback(this, function (response) {
            var memberEvent = $A.get("e.FieloPLT:UpdateMemberEvent");
            var toastEvent = $A.get("e.force:showToast");
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var response = response.getReturnValue();
                if (response.length > 0) {
                    var membersPending = true;
                    var newMember = response[0];
                    var programs = [];
                    helper.programs = {};
                    response.forEach(function (member) { 
                        var newProgram = {};
                        newProgram.Id = member.FieloPLT__Program__r.Id;
                        newProgram.Name = member.FieloPLT__Program__r.Name;
                        if (helper.programs[newProgram.Id]) {
                            helper.programs[newProgram.Id].push(member);
                        } else {
                            programs.push(newProgram);
                            helper.programs[newProgram.Id] = [member];                            
                        }
                    })                    
                    if (joinedMember) {
                        joinedMember = JSON.parse(joinedMember);
                        
                        response.forEach(function (member) {
                            if (joinedMember.Id == member.Id && member.FieloPLT__Status__c == 'Active') {
                                newMember = member;
                            }
                            if (member.FieloPLT__Status__c == 'Active' || member.FieloPLT__Status__c == 'Opt-out') {
                                membersPending = false;
                            }
                        })
                        window.localStorage.clear('joinedMember');
                    }else if (memberId) {
                        memberId = JSON.parse(memberId);
                        response.forEach(function (member) {
                            if (memberId.Id == member.Id) {
                                newMember = member;
                            }
                            if (member.FieloPLT__Status__c == 'Active' || member.FieloPLT__Status__c == 'Opt-out') {
                                membersPending = false;
                            }
                        })
                    } else {
                        window.localStorage.setItem('member', JSON.stringify(newMember));
                        newMember ? membersPending = false : membersPending = true;
                    }
                    component.set("v.memberInfo", newMember);
                    var newPrograms = [];
                    programs.forEach(function(program) {                        
                        var allDisabled = true;
                        if (helper.programs[program.Id]) {
                            helper.programs[program.Id].forEach(function(member){
                                if (member.FieloPLT__Status__c == 'Active' || member.FieloPLT__Status__c == 'Opt-out') {
                                    allDisabled = false;
                                }
                            })                        
                            newPrograms.push({
                                'program': program,
                                'disabled': allDisabled
                            });    
                        }
                        
                    })
                    component.set("v.programs", newPrograms);
                    component.set("v.members", helper.programs[newMember.FieloPLT__Program__r.Id]);
                    component.set("v.programInfo", { 'Name': newMember.FieloPLT__Program__r.Name, 'Id': newMember.FieloPLT__Program__r.Id });
                    component.set("v.showMemberFields", false);
                    component.set("v.showMemberFields", true);
                    if (!membersPending) {
                        if (memberEvent) {
                            memberEvent.setParam('member', component.get('v.memberInfo'));
                            memberEvent.fire();
                        }
                        var pubsub = component.find('pubsub');
                        if (pubsub)
                            pubsub.fireEvent('memberChange', {member: component.get('v.memberInfo')});
                    }
                } else {
                    component.set('v.showProfile', false);
                }
                if (refresh) {
                    var registrationEvent = $A.get("e.FieloPLT:ToggleRegistrationEvent");
                    if (registrationEvent) {
                        registrationEvent.setParams({
                            "userMembers": response
                        })
                        registrationEvent.fire();
                    }
                }
                if (spinner) {
                    spinner.setParam('show', false);
                    spinner.fire();
                }
                
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
    setMember: function (component, memberId) {
        //var spinner = $A.get("e.FieloPLT:ToggleSpinnerEvent");
        var memberEvent = $A.get("e.FieloPLT:UpdateMemberEvent");
        var members = component.get('v.members');
        members.forEach(function (member) {
            if (member.Id == memberId) {
                component.set('v.memberInfo', member);
                component.set('v.showMemberFields', false);
                component.set('v.showMemberFields', true);
                window.localStorage.setItem('member', JSON.stringify(member));
                if (memberEvent) {
                    memberEvent.setParam('member', member);
                    memberEvent.fire();
                }
                var pubsub = component.find('pubsub');
                if(pubsub)
                    pubsub.fireEvent('memberChange', {member: member});

            }
        })
    }
})