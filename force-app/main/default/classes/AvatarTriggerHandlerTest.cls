@IsTest
private class AvatarTriggerHandlerTest {

    @IsTest
    static void testMaxFourAvatarsPerAccount() {
        Account acc = new Account(Name = 'Avatar Limit', Email__c = 'test@example.com', NIF__c = '12345678R');
        insert acc;

        List<Avatar__c> firstFour = new List<Avatar__c>();
        for (Integer i = 0; i < 4; i++) {
            firstFour.add(new Avatar__c(
                Account__c = acc.Id,
                Primary_avatar__c = (i == 0) // el primero primario, da igual aquí
            ));
        }
        insert firstFour;

        // Quinto avatar debería petar
        Avatar__c fifth = new Avatar__c(
            Account__c = acc.Id
        );

        Test.startTest();
        try {
            insert fifth;
            System.assert(false, 'Debería lanzar error por más de 4 avatares');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Your Account already has 4 avatars'),
                'Mensaje de error incorrecto: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

        @IsTest
    static void testAvoidPrimaryAvatarDeletion() {
        Account acc = new Account(Name = 'Primary Delete', Email__c = 'test@example.com', NIF__c = '12345678R');
        insert acc;

        Avatar__c primary = new Avatar__c(
            Account__c = acc.Id,
            Primary_avatar__c = true
        );
        insert primary;

        Test.startTest();
        try {
            delete primary;
            System.assert(false, 'No debería poder borrarse un avatar primario');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('You can not delete a primary Avatar'),
                'Mensaje de error incorrecto: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
}