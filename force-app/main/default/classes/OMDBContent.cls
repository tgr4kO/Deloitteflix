public with sharing class OMDBContent {

    // DTO para mapear el JSON de OMDb
    public class OMDbResponse {
        @AuraEnabled public String title;                   // Name in Content__c
        @AuraEnabled public String year;                    // no en Content__c
        @AuraEnabled public String rated;                   // Rating__c in Content__c
        @AuraEnabled public String released;                // Publication_date__c in Content__c
        @AuraEnabled public String season;                  // Season__c.Number__c
        @AuraEnabled public String episode;                 // Episode__c.Episode_number__c
        @AuraEnabled public String runtime;                 // Duration__c in Content__c
       @AuraEnabled public String genre;                    // Category__c in Content__c
       @AuraEnabled public String director;                 // Director__c
       @AuraEnabled public String actors;                   // Cast__c
       @AuraEnabled public String plot;                     // Synopsis__c
       @AuraEnabled public String awards;                   // Awards__c
       @AuraEnabled public String poster;                   // Movie_poster_url__c
       @AuraEnabled public String imdbID;                   // IMDBId__c
       @AuraEnabled public String seriesID;                 // Season_ID__c
       @AuraEnabled public String type;                     // movie, series, episode
       @AuraEnabled public String response;
       @AuraEnabled public String imdbRating;
    }

    /**
     * Parsea el JSON de OMDb a un objeto Apex
     */
    public static OMDbResponse parse(String jsonResponse) {
        if (String.isBlank(jsonResponse)) throw new IllegalArgumentException('OMDb JSON empty');
        try {
            return (OMDbResponse) JSON.deserialize(jsonResponse, OMDbResponse.class);
        } catch (Exception e) {
            throw new IllegalArgumentException('Error parseando JSON OMDb: ' + e.getMessage());
        }
    }

    /**
     * Convierte un OMDbResponse en un SObject listo para insertar/upsert
     * No hace DML aquí.
     */
    public static SObject toRecord(OMDbResponse omdb) {
        if (omdb == null || omdb.response == 'False') return null;
    
        switch on omdb.type {
            when 'movie' {
                Content__c content = new Content__c();
                content.Name = omdb.title;
                content.Rating__c = omdb.rated;
                content.Publication_date__c = parseOmdbDate(omdb.released);
                content.Duration__c = parseRuntime(omdb.runtime);
                content.Category__c = (omdb.genre != null) ? omdb.genre.replace(', ', ';') : null;
                content.Director__c = omdb.director;
                content.Cast__c = omdb.actors;
                content.Synopsis__c = omdb.plot;
                content.Awards__c = omdb.awards;
                content.Movie_poster_url__c = (omdb.poster != 'N/A') ? omdb.poster : null;
                content.IMDBId__c = omdb.imdbID;
    
                // 👇 IMPORTANTE: valores válidos en tu picklist
                content.Content_type__c = 'Movie';      // valor EXACTO del picklist
                content.Content_status__c = 'Active';   // valor EXACTO del picklist
    
                return content;
            }
            when 'series' {
                Content__c content = new Content__c();
                content.Name = omdb.title;
                content.IMDBId__c = omdb.imdbID;
    
                content.Rating__c = omdb.rated;
                content.Publication_date__c = parseOmdbDate(omdb.released);
                content.Category__c = (omdb.genre != null) ? omdb.genre.replace(', ', ';') : null;
                content.Director__c = omdb.director;
                content.Cast__c = omdb.actors;
                content.Synopsis__c = omdb.plot;
                content.Awards__c = omdb.awards;
                content.Movie_poster_url__c = (omdb.poster != 'N/A') ? omdb.poster : null;
    
                // 👇 para series: duración 0 (o lo que hayáis definido)
                content.Duration__c = 0;
                content.Content_type__c = 'Series';     // valor EXACTO del picklist
                content.Content_status__c = 'Active';
    
                return content;
            }
            when 'episode' {
                Episode__c episode = new Episode__c();
                episode.Name = omdb.title;
                episode.Episode_number__c = (omdb.episode != null) ? Integer.valueOf(omdb.episode) : null;
                return episode;
            }
            when else {
                return null;
            }
        }
    }


    // ----------------------------
    // Parseo de fecha OMDb a Date
    // ----------------------------
    public static Date parseOmdbDate(String omdbDate) {
        if (String.isBlank(omdbDate) || omdbDate == 'N/A') return null;
        try {
            List<String> parts = omdbDate.split(' ');
            if (parts.size() != 3) return null;
            Integer day = Integer.valueOf(parts[0]);
            Integer year = Integer.valueOf(parts[2]);
            Map<String,Integer> months = new Map<String,Integer>{
                'Jan'=>1,'Feb'=>2,'Mar'=>3,'Apr'=>4,'May'=>5,'Jun'=>6,
                'Jul'=>7,'Aug'=>8,'Sep'=>9,'Oct'=>10,'Nov'=>11,'Dec'=>12
            };
            Integer month = months.get(parts[1]);
            if (month == null) return null;
            return Date.newInstance(year, month, day);
        } catch (Exception e) {
            return null;
        }
    }

    // ----------------------------
    // Parseo de runtime a Decimal
    // ----------------------------
    public static Decimal parseRuntime(String runtime) {
        if (String.isBlank(runtime) || runtime == 'N/A') return null;
        try {
            String numberOnly = runtime.replace(' min','');
            return Decimal.valueOf(numberOnly);
        } catch (Exception e) {
            return null;
        }
    }
    
    //Validacion de valores para category__c para evitar errores en la salida 
    public static String filterValidPicklistValues(
        Schema.SObjectField field,
        String incomingValues) {
        if (String.isBlank(incomingValues)) {
            return null;
        }
    
        // Valores permitidos en el picklist
        Set<String> allowedValues = new Set<String>();
        for (Schema.PicklistEntry ple : field.getDescribe().getPicklistValues()) {
            allowedValues.add(ple.getValue());
        }
    
        // Valores que vienen (separados por ;)
        List<String> values = incomingValues.split(';');
        List<String> validValues = new List<String>();
    
        for (String v : values) {
            if (allowedValues.contains(v)) {
                validValues.add(v);
            }
        }
    
        return validValues.isEmpty() ? null : String.join(validValues, ';');
    }



}

/* Ejemplo de JSon de vuelta de OMDB.com
{"Title":"Corporate Raiders from Dimension X",
"Year":"1989",
"Rated":"TV-Y7",
"Released":"27 Oct 1989",
"Season":"3",
"Episode":"25",
"Runtime":"23 min",
"Genre":"Animation, Action, Adventure",
"Director":"Bill Wolf",
"Writer":"David Wise, Fred Wolf, Kevin Eastman",
"Actors":"James Avery, Cam Clarke, Townsend Coleman",
"Plot":"White-collar criminals give new meaning to the term 'hostile take-over.' Casey Jones helps the Turtles uncover who's behind a new wave of corporate crime.",
"Language":"N/A",
"Country":"South Korea, Philippines, China, Hungary, Taiwan",
"Awards":"N/A",
"Poster":"https://m.media-amazon.com/images/M/MV5BMjI4MDc1ODUzMV5BMl5BanBnXkFtZTgwMjg4MzgzMjE@._V1_SX300.jpg",
"Ratings":[],
"Metascore":"N/A",
"imdbRating":"N/A",
"imdbVotes":"153",
"imdbID":"tt0767559",
"seriesID":"tt0131613",
"Type":"episode",
"Response":"True"
}
*/