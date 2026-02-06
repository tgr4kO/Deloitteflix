@IsTest
private class AccountTriggerHandlerTest {

    // ... testCreatePrimaryAvatarOnInsert ya estaba

    @IsTest
    static void testCalculateSubscriptionEndDateOnInsert() {
        Date startDate = Date.today();
        Integer duration = 3;

        Account acc = new Account(
            Name = 'Sub Test',
            Subscription_start_date__c = startDate,
            Subscription_duration__c = '6',
            Email__c = 'test@example.com',
            NIF__c = '12345678R'
        );

        Test.startTest();
        insert acc;
        Test.stopTest();

        Account reloaded = [
            SELECT Subscription_start_date__c, Subscription_end_date__c,
                   Subscription_duration__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            startDate.addMonths(duration),
            reloaded.Subscription_end_date__c,
            'End date debe ser start + duration meses (insert)'
        );
    }

    @IsTest
    static void testCalculateSubscriptionEndDateOnUpdateWhenChanged() {
        Date startDate = Date.today();
        Integer duration = 3;

        Account acc = new Account(
            Name = 'Sub Update',
            Subscription_start_date__c = startDate,
            Subscription_duration__c = '6',
            Email__c = 'test@example.com',
            NIF__c = '12345678R'
        );
        insert acc;

        // Ahora cambiamos la duración
        acc.Subscription_duration__c = String.valueOf(6);

        Test.startTest();
        update acc;
        Test.stopTest();

        Account reloaded = [
            SELECT Subscription_end_date__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            startDate.addMonths(6),
            reloaded.Subscription_end_date__c,
            'End date debe recalcularse al cambiar duración'
        );
    }

    @IsTest
    static void testCalculateSubscriptionEndDateNotRecalculatedIfNoChange() {
        Date startDate = Date.today();
        Integer duration = 3;

        Account acc = new Account(
            Name = 'Sub No Change',
            Subscription_start_date__c = startDate,
            Subscription_duration__c = '6',
            Email__c = 'test@example.com',
            NIF__c = '12345678R'
        );
        insert acc;

        Account beforeUpdate = [
            SELECT Subscription_end_date__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        // Update que no cambia ni start ni duration
        acc.Name = 'Sub No Change Updated';

        Test.startTest();
        update acc;
        Test.stopTest();

        Account afterUpdate = [
            SELECT Subscription_end_date__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            beforeUpdate.Subscription_end_date__c,
            afterUpdate.Subscription_end_date__c,
            'End date no debería cambiar si no cambian start ni duration'
        );
    }
}