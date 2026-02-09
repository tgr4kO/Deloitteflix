public with sharing class OMDBSearchResults {

    public List<OMDBContent.OMDbResponse> Search { get; set; }
    public Integer totalResults { get; set; }
    public String Response { get; set; }

    /**
     * Parsea JSON de búsqueda OMDb (s=) a OMDBSearchResults
     */
    public static OMDBSearchResults parse(String jsonResponse) {
        if (String.isBlank(jsonResponse)) throw new IllegalArgumentException('OMDb Search JSON empty');
    
        Map<String, Object> obj = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        OMDBSearchResults result = new OMDBSearchResults();
    
        if (obj.containsKey('Search')) {
            // Búsqueda por s=
            List<Object> searchList = (List<Object>) obj.get('Search');
            result.Search = new List<OMDBContent.OMDbResponse>();
            for (Object o : searchList) {
                result.Search.add((OMDBContent.OMDbResponse) JSON.deserialize(JSON.serialize(o), OMDBContent.OMDbResponse.class));
            }
        } else if (obj.containsKey('Response') && obj.get('Response') == 'True') {
            // Búsqueda por i= o t=
            result.Search = new List<OMDBContent.OMDbResponse>();
            OMDBContent.OMDbResponse single = OMDBContent.parse(jsonResponse);
            result.Search.add(single);
        }
    
        result.Response = (String) obj.get('Response');
        result.totalResults = obj.containsKey('totalResults') ? Integer.valueOf((String)obj.get('totalResults')) : null;
    
        return result;
    }


    /**
     * Método helper para obtener un OMDbResponse válido
     * Funciona tanto para búsquedas por s= (Search) como i= o t=
     */
    public static OMDBContent.OMDbResponse getFirstOrSingle(String jsonResponse) {
        if (String.isBlank(jsonResponse)) return null;

        // Intentamos parsear como búsqueda múltiple
        OMDBSearchResults results;
        try {
            results = OMDBSearchResults.parse(jsonResponse);
            if (results.Search != null && !results.Search.isEmpty()) {
                return results.Search[0];
            }
        } catch(Exception e) {
            // ignoramos, quizá no es JSON de Search
        }

        // Si no hay Search o falla, parseamos directamente como un solo objeto
        try {
            return OMDBContent.parse(jsonResponse);
        } catch(Exception e) {
            System.debug('Error parseando JSON como OMDb single object: ' + e.getMessage());
            return null;
        }
    }
}