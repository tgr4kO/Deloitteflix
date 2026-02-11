@IsTest
private class OMDBContentServiceTest {

    // -------------------------------------
    // 1) TestSetup: crea la config una vez
    //    en una transacción separada
    // -------------------------------------
    @TestSetup
    static void setupData() {
        // Asumo que OMDbConfig__c es un Custom Setting Jerárquico
        // y que el campo APIKey__c existe.
        OMDbConfig__c config = new OMDbConfig__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            APIKey__c    = 'TEST_API_KEY'
        );
        insert config;
    }

    // --------------------------
    // 2) Mocks de callout HTTP
    // --------------------------
    private class OMDBSuccessMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            String body = '{' +
                '"Search":[{' +
                    '"title":"Mock Movie","year":"2024","type":"movie","imdbID":"ttMock","response":"True"' +
                '}],' +
                '"totalResults":"1",' +
                '"Response":"True"' +
            '}';
            res.setBody(body);
            return res;
        }
    }

    private class OMDBErrorBodyMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"Response":"False","Error":"Movie not found!"}');
            return res;
        }
    }

    private class OMDBHttpStatusErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"Response":"False","Error":"Server error"}');
            return res;
        }
    }

    // --------------------------
    // 3) Tests unitarios
    // --------------------------

    @IsTest
    static void testBuildEndpoint() {
        Map<String, String> params = new Map<String, String>{
            's'    => 'Batman',
            'type' => 'movie',
            'page' => '1'
        };
        String endpoint = OMDBContentService.buildEndpoint(params);
        System.assert(endpoint.startsWith('https://www.omdbapi.com/?'));
        System.assert(endpoint.contains('s=Batman'));
        System.assert(endpoint.contains('type=movie'));
        System.assert(endpoint.contains('page=1'));
    }

    @IsTest
    static void testSearchOMDBContentSuccess() {
        Map<String, String> params = new Map<String, String>{
            's'    => 'Test',
            'type' => 'movie'
        };

        Test.setMock(HttpCalloutMock.class, new OMDBSuccessMock());

        Test.startTest();
        OMDBSearchResults results = OMDBContentService.searchOMDBContent(params);
        Test.stopTest();

        System.assertNotEquals(null, results);
        System.assertEquals('True', results.Response);
        System.assertNotEquals(null, results.Search);
        System.assertEquals(1, results.Search.size());
        System.assertEquals('Mock Movie', results.Search[0].title);
    }

    @IsTest
    static void testSearchOMDBContentInvalidParams() {
        // params vacíos
        try {
            OMDBContentService.searchOMDBContent(new Map<String,String>());
            System.assert(false, 'Debe lanzar IllegalArgumentException si el mapa está vacío');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('no puede estar vacío'));
        }

        // falta s, i, t
        try {
            OMDBContentService.searchOMDBContent(new Map<String,String>{ 'page' => '1' });
            System.assert(false, 'Debe lanzar IllegalArgumentException si falta s/i/t');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Se requiere al menos "s", "i" o "t"'));
        }
    }

    @IsTest
    static void testSearchOMDBContentInvalidType() {
        Map<String, String> params = new Map<String, String>{
            's'    => 'Test',
            'type' => 'invalidType'
        };

        Test.setMock(HttpCalloutMock.class, new OMDBSuccessMock());

        try {
            OMDBContentService.searchOMDBContent(params);
            System.assert(false, 'Debe lanzar IllegalArgumentException por type inválido');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Tipo inválido'));
        }
    }

    @IsTest
    static void testSearchOMDBContentResponseFalse() {
        Map<String, String> params = new Map<String, String>{
            's' => 'Test'
        };

        Test.setMock(HttpCalloutMock.class, new OMDBErrorBodyMock());

        try {
            Test.startTest();
            OMDBContentService.searchOMDBContent(params);
            Test.stopTest();
            System.assert(false, 'Debe lanzar CalloutException cuando Response = False');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('OMDb API returned error'));
        }
    }

    @IsTest
    static void testSearchOMDBContentHttpStatusError() {
        Map<String, String> params = new Map<String, String>{
            's' => 'Test'
        };

        Test.setMock(HttpCalloutMock.class, new OMDBHttpStatusErrorMock());

        try {
            Test.startTest();
            OMDBContentService.searchOMDBContent(params);
            Test.stopTest();
            System.assert(false, 'Debe lanzar CalloutException cuando statusCode != 200');
        } catch (CalloutException e) {
            System.assert(e.getMessage().contains('OMDb API returned status'));
        }
    }

    @IsTest
    static void testSearchOMDBContentNoApiKeyConfigured() {
        // En este test simulamos que NO hay APIKey
        // Borramos el registro del custom setting. OJO: este método NO hace callout
        // porque la clase corta antes si apiKey está en blanco, así que no hay
        // problema de DML + callout aquí.
        delete [SELECT Id FROM OMDbConfig__c LIMIT 1];

        Map<String, String> params = new Map<String, String>{
            's' => 'Test'
        };

        Test.setMock(HttpCalloutMock.class, new OMDBSuccessMock());

        try {
            OMDBContentService.searchOMDBContent(params);
            System.assert(false, 'Debe lanzar IllegalArgumentException si no hay APIKey configurada');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('No hay API Key configurada'));
        }
    }
}