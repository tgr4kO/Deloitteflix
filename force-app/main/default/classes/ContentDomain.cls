public with sharing class ContentDomain {

    /**
     * Upsert de un Content__c desde un JSON OMDb
     * @param omdbJson JSON string de OMDb
     * @return el registro insertado/upsertado
     */
    public static Content__c upsertContent(String omdbJson) {
        if (String.isBlank(omdbJson)) {
            throw new IllegalArgumentException('El JSON de OMDb no puede estar vacío.');
        }

        // 1️⃣ Parsear JSON a OMDbResponse
        OMDBContent.OMDbResponse omdbResponse = OMDBContent.parse(omdbJson);

        if (omdbResponse == null || omdbResponse.response == 'False') {
            return null;
        }

        // 2️⃣ Solo movies/series se insertan como Content__c
        if (omdbResponse.type != 'movie' && omdbResponse.type != 'series') {
            throw new IllegalArgumentException('Solo se pueden upsertar movies o series en Content__c.');
        }

        // 3️⃣ Buscar si ya existe Content__c con mismo IMDBId
        Content__c content;
        List<Content__c> existing = [
            SELECT Id, Name, Rating__c, Publication_date__c, Duration__c, Category__c,
                   Director__c, Cast__c, Synopsis__c, Awards__c, Movie_poster_url__c, IMDBId__c
            FROM Content__c
            WHERE IMDBId__c = :omdbResponse.imdbID
            LIMIT 1
        ];
        content = existing.isEmpty() ? new Content__c() : existing[0];

        // 4️⃣ Mapear campos desde OMDbResponse
        content.Name = omdbResponse.title;
        content.Publication_date__c = OMDBContent.parseOmdbDate(omdbResponse.released);
        content.Duration__c = OMDBContent.parseRuntime(omdbResponse.runtime);

        // ✅ Validar Category__c contra picklist
        String defaultRating = 'Not Rated';   // poner un valor de tu picklist Rating__c
        String defaultCategory = 'Other';     // poner un valor de tu picklist Category__c
        
        content.Rating__c = filterValidPicklistValues(
            Content__c.Rating__c, 
            omdbResponse.rated,
            defaultRating
        );
        
        String genre = (omdbResponse.genre != null) ? omdbResponse.genre.replace(', ', ';') : null;
        content.Category__c = filterValidPicklistValues(
            Content__c.Category__c, 
            genre,
            defaultCategory
        );

        content.Director__c = omdbResponse.director;
        content.Cast__c = omdbResponse.actors;
        content.Synopsis__c = omdbResponse.plot;
        content.Awards__c = omdbResponse.awards;
        content.Movie_poster_url__c = omdbResponse.poster;
        content.IMDBId__c = omdbResponse.imdbID;

        // 5️⃣ Upsert por IMDBId__c (campo externo)
        upsert content IMDBId__c;

        return content;
    }

    // ----------------------------
    // Filtra los valores de un picklist para que solo deje los válidos
    // ----------------------------
    public static String filterValidPicklistValues(
        Schema.SObjectField field,
        String incomingValues,
        String defaultValue) {
        if (String.isBlank(incomingValues)) {
            return defaultValue;
        }
    
        // Valores permitidos en el picklist
        Set<String> allowedValues = new Set<String>();
        for (Schema.PicklistEntry ple : field.getDescribe().getPicklistValues()) {
            allowedValues.add(ple.getValue());
        }
    
        // Tomar todos los valores válidos
        List<String> values = incomingValues.split(';');
        List<String> validValues = new List<String>();
        for (String v : values) {
            v = v.trim();
            if (allowedValues.contains(v)) {
                validValues.add(v);
            }
        }
    
        // Si no hay ninguno válido, devolvemos default
        if (validValues.isEmpty()) {
            return defaultValue;
        }
    
        // Devolver todos concatenados por ";"
        return String.join(validValues, ';');
    }

  
}