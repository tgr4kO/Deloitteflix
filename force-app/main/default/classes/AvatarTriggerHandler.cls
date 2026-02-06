public class AvatarTriggerHandler {

    private static AvatarTriggerHandler instance;

    public static AvatarTriggerHandler getHandler() {
        if (instance == null) {
            instance = new AvatarTriggerHandler();
        }
        return instance;
    }

    // Métodos de entrada

    public void beforeInsert(List<Avatar__c> newList) {
        checkNumAvataresDeCuenta(newList);
    }

    public void beforeDelete(List<Avatar__c> oldList) {
        avoidPrimaryAvatarDeletion(oldList);
    }

    public void afterInsert(List<Avatar__c> newList) {
        disableOtherPrimaryAvatars(newList);
    }

    public void afterUpdate(List<Avatar__c> newList, Map<Id, Avatar__c> oldMap) {
        disableOtherPrimaryAvatars(newList);
    }

    // --- US-0016: máximo 4 avatares por cuenta ---

    public void checkNumAvataresDeCuenta(List<Avatar__c> newList) {
        if (newList == null || newList.isEmpty()) return;

        // Recoger las cuentas implicadas
        Set<Id> accountIds = new Set<Id>();
        for (Avatar__c av : newList) {
            if (av.Account__c != null) {
                accountIds.add(av.Account__c);
            }
        }
        if (accountIds.isEmpty()) return;

        // Contar avatares existentes por cuenta
        Map<Id, Integer> countsByAccount = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Account__c accId, COUNT(Id) cnt
            FROM Avatar__c
            WHERE Account__c IN :accountIds
            GROUP BY Account__c
        ]) {
            countsByAccount.put(
                (Id) ar.get('accId'),
                (Integer) ar.get('cnt')
            );
        }

        // Incluir los nuevos avatares en el conteo y hacer addError si > 4
        for (Avatar__c av : newList) {
            if (av.Account__c == null) continue;

            Integer currentCount =
                countsByAccount.containsKey(av.Account__c)
                ? countsByAccount.get(av.Account__c)
                : 0;

            currentCount++;
            countsByAccount.put(av.Account__c, currentCount);

            if (currentCount > 4) {
                av.addError('Your Account already has 4 avatars');
            }
        }
    }

    // --- US-0017 y US-0018 los añadimos debajo ---
    public void avoidPrimaryAvatarDeletion(List<Avatar__c> oldList) {
        if (oldList == null || oldList.isEmpty()) return;
        
        for (Avatar__c av : oldList) {
            if (av.Primary_avatar__c == true) {
                av.addError('You can not delete a primary Avatar');
    		}
   		}
    }
    public void disableOtherPrimaryAvatars(List<Avatar__c> newList) {
        if (newList == null || newList.isEmpty()) return;
    
        // Solo nos interesan los que SON primarios
        Set<Id> accountIds = new Set<Id>();
        Map<Id, Id> newPrimaryByAccount = new Map<Id, Id>(); // AccountId → AvatarId (nuevo primary)
    
        for (Avatar__c av : newList) {
            // En afterUpdate podrías filtrar solo los que cambian de false->true,
            // pero para el ejercicio basta con chequear Primary__c == true
            if (av.Account__c != null && av.Primary_avatar__c == true) {
                accountIds.add(av.Account__c);
                newPrimaryByAccount.put(av.Account__c, av.Id);
            }
        }
    
        if (accountIds.isEmpty()) return;
    
        // Buscar todos los avatares primarios de esas cuentas
        List<Avatar__c> avatarsToUpdate = new List<Avatar__c>();
    
        for (Avatar__c existing : [
            SELECT Id, Account__c, Primary_avatar__c
            FROM Avatar__c
            WHERE Account__c IN :accountIds
                  AND Primary_avatar__c = true
        ]) {
            Id accId = existing.Account__c;
    
            // Si este es el que acabamos de marcar como primary, lo dejamos
            if (newPrimaryByAccount.containsKey(accId)
                && existing.Id == newPrimaryByAccount.get(accId)) {
                continue;
            }
    
            // Para todos los demás primarios de esa cuenta, desmarcamos
            existing.Primary_avatar__c = false;
            avatarsToUpdate.add(existing);
        }
    
        if (!avatarsToUpdate.isEmpty()) {
            try {
                update avatarsToUpdate;
            } catch (DmlException e) {
                // logging si quisieras
            }
        }
    }
}