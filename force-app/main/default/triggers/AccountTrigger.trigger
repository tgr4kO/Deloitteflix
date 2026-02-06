trigger AccountTrigger on Account (
    before insert,
    before update,
    after insert
) {
    AccountTriggerHandler handler = AccountTriggerHandler.getHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert((List<Account>) Trigger.new);
            handler.calculateSubscriptionEndDate((List<Account>) Trigger.new);
        } else if (Trigger.isUpdate) {
            handler.beforeUpdate((List<Account>) Trigger.new, (Map<Id, Account>) Trigger.oldMap);
            handler.calculateSubscriptionEndDate((List<Account>) Trigger.new);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert((List<Account>) Trigger.new);
        }
    }
}