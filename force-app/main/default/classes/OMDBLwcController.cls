public with sharing class OMDBLwcController {

    @AuraEnabled(cacheable=true)
    public static List<OMDBContent.OMDbResponse> search(String searchText) {
        // Protección básica: mismo criterio que en el enunciado (5 chars)
        if (String.isBlank(searchText) || searchText.length() < 5) {
            return new List<OMDBContent.OMDbResponse>();
        }

        try {
            Map<String, String> params = new Map<String, String>{
                's' => searchText
                // si quieres filtrar: 'type' => 'movie'
            };
            OMDBSearchResults res = OMDBContentService.searchOMDBContent(params);
            return (res != null && res.Search != null) ?
                res.Search :
                new List<OMDBContent.OMDbResponse>();
        } catch (Exception e) {
            throw new AuraHandledException('Error searching OMDb: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static OMDBContent.OMDbResponse getDetail(String imdbId) {
        if (String.isBlank(imdbId)) {
            throw new AuraHandledException('imdbID is required');
        }

        try {
            Map<String, String> params = new Map<String, String>{
                'i' => imdbId
            };
            OMDBSearchResults res = OMDBContentService.searchOMDBContent(params);
            if (res != null && res.Search != null && !res.Search.isEmpty()) {
                return res.Search[0];
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException('Error getting OMDb detail: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Content__c downloadToDb(String imdbId) {
        if (String.isBlank(imdbId)) {
            throw new AuraHandledException('imdbID is required');
        }

        try {
            // Sacamos la API key del custom setting
            String apiKey = OMDbConfig__c.getInstance().APIKey__c;
            if (String.isBlank(apiKey)) {
                throw new AuraHandledException('No OMDb API key configured.');
            }

            // Construimos endpoint directo (i= + apikey)
            Map<String, String> params = new Map<String, String>{
                'i'      => imdbId,
                'apikey' => apiKey
            };
            List<String> queryParts = new List<String>();
            for (String key : params.keySet()) {
                queryParts.add(key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8'));
            }
            String endpoint = 'https://www.omdbapi.com/?' + String.join(queryParts, '&');

            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpoint);
            req.setMethod('GET');
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                throw new AuraHandledException('OMDb error: HTTP ' + res.getStatusCode());
            }
            String body = res.getBody();
            if (String.isBlank(body)) {
                throw new AuraHandledException('OMDb returned empty body.');
            }

            Map<String, Object> check = (Map<String, Object>) JSON.deserializeUntyped(body);
            if (!check.containsKey('Response') || String.valueOf(check.get('Response')) != 'True') {
                String msg = check.containsKey('Error') ?
                    String.valueOf(check.get('Error')) :
                    'Unknown OMDb error';
                throw new AuraHandledException('OMDb API error: ' + msg);
            }

            // Aquí reutilizamos tu lógica de dominio
            Content__c content = ContentDomain.upsertContent(body);
            return content;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException('Error downloading to DB: ' + e.getMessage());
        }
    }
}