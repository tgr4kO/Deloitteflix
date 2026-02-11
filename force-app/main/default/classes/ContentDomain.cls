public with sharing class ContentDomain {

    // 🔹 Helper para obtener RecordTypeId por DeveloperName
    private static Id getRtId(String devName) {
        Map<String, Schema.RecordTypeInfo> infos =
            Schema.SObjectType.Content__c.getRecordTypeInfosByDeveloperName();
        Schema.RecordTypeInfo info = infos.get(devName);
        return (info != null) ? info.getRecordTypeId() : null;
    }

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

        // (Opcional, pero recomendable) solo movies/series
        if (omdbResponse.type != 'movie' && omdbResponse.type != 'series') {
            throw new IllegalArgumentException('Solo se pueden upsertar movies o series en Content__c.');
        }

        // 3️⃣ Buscar si ya existe Content__c con mismo IMDBId
        Content__c content;
        List<Content__c> existing = [
            SELECT Id, Name, Rating__c, Publication_date__c, Duration__c, Category__c,
                   Director__c, Cast__c, Synopsis__c, Awards__c, Movie_poster_url__c,
                   IMDBId__c, Content_type__c, Content_status__c, RecordTypeId
            FROM Content__c
            WHERE IMDBId__c = :omdbResponse.imdbID
            LIMIT 1
        ];
        content = existing.isEmpty() ? new Content__c() : existing[0];

        // 4️⃣ Mapear campos comunes desde OMDbResponse
        content.Name = omdbResponse.title;
        content.Publication_date__c = OMDBContent.parseOmdbDate(omdbResponse.released);

        // ✅ Rating + Category usando tu helper
        // 👇 ADAPTA estos valores a tu org
        String defaultRating   = 'Not Rated'; // valor real del picklist Rating__c
        String defaultCategory = 'Other';     // valor real del picklist Category__c
        
        content.Rating__c = filterValidPicklistValues(
            Content__c.Rating__c, 
            omdbResponse.rated,
            defaultRating
        );
        
        String genre = (omdbResponse.genre != null)
            ? omdbResponse.genre.replace(', ', ';')
            : null;

        content.Category__c = filterValidPicklistValues(
            Content__c.Category__c, 
            genre,
            defaultCategory
        );

        content.Director__c         = omdbResponse.director;
        content.Cast__c             = omdbResponse.actors;
        content.Synopsis__c         = omdbResponse.plot;
        content.Awards__c           = omdbResponse.awards;
        content.Movie_poster_url__c = (omdbResponse.poster == 'N/A') ? null : omdbResponse.poster;
        content.IMDBId__c           = omdbResponse.imdbID;

        // 5️⃣ Lógica específica según tipo OMDb (movie / series)

        if (omdbResponse.type == 'series') {
            // Duración: regla de negocio → 0 para series
            content.Duration__c = 0;

            // Picklist Content_type__c
            content.Content_type__c = 'Serie';  // 👈 EXACTO como en tu picklist

            // RecordType para series (DeveloperName de tu RT)
            Id serieRtId = getRtId('Serie'); // 👈 CAMBIA 'Serie_RT' por tu DeveloperName real
            if (serieRtId != null) {
                content.RecordTypeId = serieRtId;
            }
        } else if (omdbResponse.type == 'movie') {
            // Duración parseada desde runtime
            content.Duration__c = OMDBContent.parseRuntime(omdbResponse.runtime);
            if (content.Duration__c == null) {
                content.Duration__c = 0; // por si viene N/A
            }

            content.Content_type__c = 'Movie';  // 👈 EXACTO como en tu picklist

            // RecordType para pelis (DeveloperName de tu RT)
            Id movieRtId = getRtId('Movie'); // 👈 CAMBIA 'Movie_RT' por tu DeveloperName real
            if (movieRtId != null) {
                content.RecordTypeId = movieRtId;
            }
        }

        // 6️⃣ Content_status__c por defecto si está vacío
        if (String.isBlank(content.Content_status__c)) {
            content.Content_status__c = 'Active'; // 👈 valor real del picklist de estado
        }

        // DEBUG para asegurarnos de que se está asignando bien
        System.debug('### OMDb type: ' + omdbResponse.type);
        System.debug('### Content_type__c final: ' + content.Content_type__c);
        System.debug('### RecordTypeId final: ' + content.RecordTypeId);
        System.debug('### Duration__c final: ' + content.Duration__c);

        // 7️⃣ Upsert por IMDBId__c (campo externo)
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