({
	doInit : function(component, event, helper) {
		var action = component.get('c.getAccount');
        action.setCallback(this,function(res){
            component.set('v.lstAccount',res.getReturnValue());
        });
        $A.enqueueAction(action);
	}
})