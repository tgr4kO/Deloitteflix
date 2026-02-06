public with sharing class ContentSelector {
    
    @AuraEnabled(cacheable=true)
    public static Content__c getContentById(Id contentId) {
        if (contentId == null) return null;

        return [
            SELECT Name, Movie_poster_url__c, Content_type__c, Category__c
            FROM Content__c
            WHERE Id = :contentId
            LIMIT 1
        ];
    }
    
    public static List<Content__c> getSeries(){
        return  [
                SELECT Name, Movie_poster_url__c, Content_type__c, Category__c
                FROM Content__c
                WHERE Content_type__c = 'Serie'
            ];
    }
    
    public static List<Content__c> getMovies(){
        return  [
                SELECT Name, Movie_poster_url__c, Content_type__c, Category__c
                FROM Content__c
                WHERE Content_type__c = 'Movie'
            ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Content__c> getContentByClient(Id accId){
        if (accId == null) return null;
        List<Content__c> results = NEW List<Content__c>();
        Account acc = [Select Subscription_type__c From Account where Id = :accId LIMIT 1];
        String contentType = acc.Subscription_type__c;
        if(contentType == 'Total'){
            results.addall(getSeries());
            results.addall(getMovies());
        } else if(contentType == 'Serie'){
            results.addall(getSeries());
        } else if(contentType == 'Movies and documentaries'){
            results.addall(getMovies());
    	}
        return results;
	}
}