public with sharing class OMDBContentService {

    private static final String BASE_URL = 'https://www.omdbapi.com/';

    /**
     * Busca contenido en OMDb según parámetros
     */
    public static OMDBSearchResults searchOMDBContent(Map<String,String> params) {
        validateParams(params);

        // ✅ Obtener API key desde Custom Setting
        String apiKey = OMDbConfig__c.getInstance().APIKey__c;
        if(String.isBlank(apiKey)) {
			throw new IllegalArgumentException('No hay API Key configurada en OMDbConfig__c');
        }
        params.put('apikey', apiKey);

        // Filtrar type válido si está presente
        if (params.containsKey('type')) {
            Set<String> allowed = new Set<String>{'movie','series','episode'};
            if (!allowed.contains(params.get('type'))) {
                throw new IllegalArgumentException('Tipo inválido. Debe ser movie, series o episode.');
            }
        }

        String endpoint = buildEndpoint(params);
        HttpResponse res = sendRequest(endpoint);
        verifyResponse(res);

        return OMDBSearchResults.parse(res.getBody());
    }

    private static void validateParams(Map<String,String> params) {
        if (params == null || params.isEmpty()) throw new IllegalArgumentException('El mapa de parámetros no puede estar vacío.');
        if (!params.containsKey('s') && !params.containsKey('i') && !params.containsKey('t')) {
            throw new IllegalArgumentException('Se requiere al menos "s", "i" o "t".');
        }
    }

    public static String buildEndpoint(Map<String,String> params) {
        List<String> queryParts = new List<String>();
        for (String key : params.keySet()) {
            queryParts.add(key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8'));
        }
        return BASE_URL + '?' + String.join(queryParts, '&');
    }

    public static HttpResponse sendRequest(String endpoint) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Http http = new Http();
        try {
            return http.send(req);
        } catch (CalloutException e) {
            throw new CalloutException('HTTP Callout failed: ' + e.getMessage());
        }
    }

    private static void verifyResponse(HttpResponse res) {
        if (res.getStatusCode() != 200) throw new CalloutException('OMDb API returned status: ' + res.getStatusCode());
        String body = res.getBody();
        if (String.isBlank(body)) throw new CalloutException('OMDb API returned empty body.');
        Map<String,Object> check = (Map<String,Object>) JSON.deserializeUntyped(body);
        if (!check.containsKey('Response') || check.get('Response') != 'True') {
            String errorMsg = (check.containsKey('Error')) ? (String) check.get('Error') : 'Unknown OMDb error';
            throw new CalloutException('OMDb API returned error: ' + errorMsg);
        }
    }
}