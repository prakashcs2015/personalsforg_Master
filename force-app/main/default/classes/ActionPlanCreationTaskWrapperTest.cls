/*
Action Plans v4
David Schach 2022
https://appexchange.salesforce.com/appxListingDetail?listingId=a0N4V00000Gg6NVUAZ

Action Plans v3
Force.com Labs 2011
http://appexchange.salesforce.com/listingDetail?listingId=a0N30000003HcINEA0

Copyright (c) 2022, salesforce.com, inc.
All rights reserved.
SPDX-License-Identifier: BSD-3-Clause
For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/BSD-3-Clause
*/
/**
 * Tests for `ActionPlanCreationController.ApTaskWrapper` Create/Edit wrapper class
 * @author {@link [David Schach](https://github.com/dschach)}
 * @group Tests
 * @since 2022
 * @see ActionPlanCreationController.ApTaskWrapper
 * @see ActionPlanCreationController
 */
@IsTest
private class ActionPlanCreationTaskWrapperTest {
	/**
	 * For most tests, assign blank tasks to parent owner. We can override in specific tests.
	 */
	@TestSetup
	private static void makeData() {
		Action_Plans_Settings__c aps = ActionPlansUtilities.getCustomSetting();
		aps.Chatter_Object_Brag__c = false;
		aps.Unassigned_Task_Assigned_to_Owner__c = true;
		try {
			upsert aps;
		} catch (Exception e) {
			update aps;
		}
	}

	@IsTest
	private static void checkActionPlanTaskList() {
		System.runAs(new ActionPlansTestUtilities().createAdminUser()) {
			Test.startTest();

			Test.setCurrentPage(Page.ActionPlanCreation);

			ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
			ActionPlan__c actionPlan = testUtil.createNewActionPlan('account', 2);

			ApexPages.currentPage().getParameters().put('id', actionPlan.Id);
			ActionPlanCreationController apCreateController = new ActionPlanCreationController(new Apexpages.StandardController(actionPlan));

			List<ActionPlanCreationController.ApTaskWrapper> apTaskList = apCreateController.getTasks();
			for (ActionPlanCreationController.ApTaskWrapper wrap : apTaskList) {
				System.assertEquals(false, wrap.userRequired);
			}
			Test.stopTest();
			System.assert(!apTaskList.isEmpty(), 'Action plan task list is empty');
		}
	}

	private static ActionPlanCreationController doTemplateCreateEdit() {
		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		Account a = testUtil.createNewAccount();
		ActionPlanTemplate__c apTemplate = testUtil.createNewActionPlanTemplate(4);
		APTemplateTask__c aptt = [SELECT Id, User__c, Reminder__c FROM APTemplateTask__c LIMIT 1];
		aptt.User__c = UserInfo.getUserId();
		aptt.Reminder__c = true;
		update aptt;

		Test.setCurrentPage(Page.ActionPlanCreation);
		ApexPages.currentPage().getParameters().put('templateid', apTemplate.Id);
		ActionPlanCreationController apCreateController = new ActionPlanCreationController(new Apexpages.StandardController(new ActionPlan__c()));
		apCreateController.inVisualforceContext = true;
		apCreateController.actionPlan.Account__c = a.Id;

		List<ActionPlanCreationController.ApTaskWrapper> apTaskList = apCreateController.getTasks();
		System.assert(!apTaskList.isEmpty());
		for (ActionPlanCreationController.ApTaskWrapper wrap : apTaskList) {
			wrap.getUserRender();
		}

		Test.startTest();
		apCreateController.save();
		Test.stopTest();

		System.assertEquals(1, [SELECT COUNT() FROM ActionPlan__c], 'Action Plan should have been inserted');

		ActionPlan__c ap = [SELECT Id, Name, TaskRecordTypeId__c FROM ActionPlan__c LIMIT 1];

		Test.setCurrentPage(Page.ActionPlanCreation);
		ApexPages.currentPage().getParameters().clear();
		apCreateController = new ActionPlanCreationController(new Apexpages.StandardController(ap));
		apCreateController.onLoad();
		apCreateController.inVisualforceContext = true;
		List<ActionPlanCreationController.ApTaskWrapper> apTaskList2 = apCreateController.getTasks();
		System.assert(!apTaskList2.isEmpty());
		for (ActionPlanCreationController.ApTaskWrapper wrap : apTaskList2) {
			System.assertNotEquals(null, wrap.apt.User__c);
			wrap.getUserRender();
		}

		return apCreateController;
	}

	@IsTest
	private static void makeFromTemplateAssignByDefault() {
		User u;
		System.runAs(new User(Id = UserInfo.getUserId())) {
			u = new ActionPlansTestUtilities().createAdminUser();
		}
		System.runAs(u) {
			ActionPlanCreationController apCreateController = doTemplateCreateEdit();
			System.assertEquals(4, apCreateController.getTasks().size());
		}
	}

	@IsTest
	private static void makeFromTemplateNOTAssignByDefault() {
		User u;
		Action_Plans_Settings__c aps = ActionPlansUtilities.getCustomSetting();
		aps.Unassigned_Task_Assigned_to_Owner__c = false;
		try {
			upsert aps;
		} catch (Exception e) {
			update aps;
		}
		System.runAs(new User(Id = UserInfo.getUserId())) {
			u = new ActionPlansTestUtilities().createAdminUser();
		}
		System.runAs(u) {
			ActionPlanCreationController apCreateController = doTemplateCreateEdit();
			System.assertEquals(4, apCreateController.getTasks().size());
		}
	}

	private static ActionPlanCreationController doEditActionPlan() {
		Test.startTest();
		Test.setCurrentPage(Page.ActionPlanCreation);

		ActionPlansTestUtilities testUtil = new ActionPlansTestUtilities();
		ActionPlan__c actionPlan = testUtil.createNewActionPlan('contact', 2);

		ActionPlanCreationController apCreateController = new ActionPlanCreationController(new Apexpages.StandardController(actionPlan));
		//apCreateController.onLoad();
		List<ActionPlanCreationController.ApTaskWrapper> apTaskList = apCreateController.getTasks();
		System.assert(!apTaskList.isEmpty());
		for (ActionPlanCreationController.ApTaskWrapper wrap : apTaskList) {
			System.assertNotEquals(null, wrap.apt.Id);
			wrap.getUserRender();
		}
		Test.stopTest();
		return apCreateController;
	}

	@IsTest
	private static void editActionPlanAssignByDefault() {
		User u;
		System.runAs(new User(Id = UserInfo.getUserId())) {
			u = new ActionPlansTestUtilities().createAdminUser();
		}
		System.runAs(u) {
			System.assert(Schema.sObjectType.APTask__c.fields.User__c.isUpdateable());
			ActionPlanCreationController apCreateController = doEditActionPlan();
			System.assertEquals(0, ActionPlansTestUtilities.getCompleted(apCreateController.actionPlan.Id), 'New AP should have no completed tasks');
			System.assertNotEquals(null, apCreateController.relatedFieldName, 'should have lazy loaded relatedFieldName');
		}
	}

	@IsTest
	private static void editActionPlanNOTAssignByDefault() {
		User u;
		Action_Plans_Settings__c aps = ActionPlansUtilities.getCustomSetting();
		aps.Unassigned_Task_Assigned_to_Owner__c = false;
		try {
			upsert aps;
		} catch (Exception e) {
			update aps;
		}
		System.runAs(new User(Id = UserInfo.getUserId())) {
			u = new ActionPlansTestUtilities().createAdminUser();
		}
		System.runAs(u) {
			System.assert(Schema.sObjectType.APTask__c.fields.User__c.isUpdateable());
			ActionPlanCreationController apCreateController = doEditActionPlan();
			System.assertEquals(0, ActionPlansTestUtilities.getCompleted(apCreateController.actionPlan.Id), 'New AP should have no completed tasks');
			System.assertNotEquals(null, apCreateController.relatedFieldName, 'should have lazy loaded relatedFieldName');
		}
	}
}