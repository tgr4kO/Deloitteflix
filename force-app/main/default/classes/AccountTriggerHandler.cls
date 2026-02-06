public class AccountTriggerHandler {

    // Singleton 
    private static AccountTriggerHandler instance;

    public static AccountTriggerHandler getHandler() {
        if (instance == null) {
            instance = new AccountTriggerHandler();
        }
        return instance;
    }

    // --- MÉTODOS DE ENTRADA DESDE EL TRIGGER ---

    public void beforeInsert(List<Account> newList) {
        // De momento vacío, lo usaremos en US-0015
    }

    public void beforeUpdate(List<Account> newList, Map<Id, Account> oldMap) {
        // De momento vacío, lo usaremos en US-0015
    }

    public void afterInsert(List<Account> newList) {
        createPrimaryAvatar(newList);
    }

    // --- LÓGICA DE US-0014 ---

    public void createPrimaryAvatar(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) return;

        List<Avatar__c> avatarsToInsert = new List<Avatar__c>();

        for (Account acc : accounts) {
            if (acc.Id == null) continue;

            Avatar__c av = new Avatar__c();
            av.Account__c = acc.Id;
            av.Primary_avatar__c = true; // primary avatar
            avatarsToInsert.add(av);
        }

        if (!avatarsToInsert.isEmpty()) {
            try {
                insert avatarsToInsert;
            } catch (DmlException e) {
                // Podrías hacer logging; para el ejercicio basta con no reventar
            }
        }
    }

    // --- US-0015 añadirá aquí calculateSubscriptionEndDate ---
    public void calculateSubscriptionEndDate(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) return;

        Map<Id, Account> oldMap;
        
        if (Trigger.isUpdate) {
            oldMap = (Map<Id, Account>) Trigger.oldMap;
        } else {
            oldMap = null;
        }
    
        for (Account acc : accounts) {
    
            if (acc.Subscription_start_date__c == null ||
                acc.Subscription_duration__c == null) {
                continue;
            }
    
            Boolean hasChanged = true;
    
            if (Trigger.isUpdate && oldMap != null && oldMap.containsKey(acc.Id)) {
                Account oldAcc = oldMap.get(acc.Id);
    
                hasChanged =
                    acc.Subscription_start_date__c != oldAcc.Subscription_start_date__c ||
                    acc.Subscription_duration__c != oldAcc.Subscription_duration__c;
            }
    
            if (!hasChanged) continue;
    
            // PICKLIST → STRING → INTEGER
            Integer durationMonths;
            try {
                durationMonths = Integer.valueOf(acc.Subscription_duration__c);
            } catch (Exception e) {
                continue; // valor no numérico en el picklist
            }
    
            acc.Subscription_End_Date__c =
                acc.Subscription_start_date__c.addMonths(durationMonths);
        }
    }

}