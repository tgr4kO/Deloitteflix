trigger AvatarTrigger on Avatar__c (
    before insert,
    before delete,
    after insert,
    after update
) {
    AvatarTriggerHandler handler = AvatarTriggerHandler.getHandler();

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert((List<Avatar__c>) Trigger.new);
        }
        if (Trigger.isDelete) {
            handler.beforeDelete((List<Avatar__c>) Trigger.old);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            handler.afterInsert((List<Avatar__c>) Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.afterUpdate((List<Avatar__c>) Trigger.new, (Map<Id, Avatar__c>) Trigger.oldMap);
        }
    }
}