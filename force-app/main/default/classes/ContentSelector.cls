public class ContentSelector {
    private final Content__c content;
    
    public ContentSelector (){
        content = [SELECT Name, Movie_poster_url__c, Content_type__c, Category__c FROM Content__c where Id = :ApexPages.currentPage().getParameters().get('id') LIMIT 1];
    }
    public Content__c getContentById(){
        return content;
    }
}