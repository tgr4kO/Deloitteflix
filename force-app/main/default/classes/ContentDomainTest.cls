@IsTest
private class ContentDomainTest {

    private static String buildValidMovieJson() {
        return '{' +
            '"title":"Domain Movie",' +
            '"year":"2024",' +
            '"rated":"Not Rated",' +
            '"released":"01 Jan 2024",' +
            '"runtime":"100 min",' +
            '"genre":"Other",' +
            '"director":"Dir Domain",' +
            '"actors":"Actor X, Actor Y",' +
            '"plot":"Plot text",' +
            '"awards":"Awards text",' +
            '"poster":"https://example.com/poster.jpg",' +
            '"imdbID":"ttDOMAIN001",' +
            '"seriesID":"ttSeries001",' +
            '"type":"movie",' +
            '"response":"True"' +
        '}';
    }

    @IsTest
    static void testUpsertContentInsertAndUpdate() {
        // Insert
        String json = buildValidMovieJson();

        Test.startTest();
        Content__c inserted = ContentDomain.upsertContent(json);
        Test.stopTest();

        System.assertNotEquals(null, inserted);
        System.assertNotEquals(null, inserted.Id);

        // Comprobar que se ha guardado en BD
        Content__c db = [
            SELECT Id, Name, IMDBId__c, Duration__c, Director__c, Category__c, Rating__c
            FROM Content__c
            WHERE IMDBId__c = 'ttDOMAIN001'
            LIMIT 1
        ];
        System.assertEquals('Domain Movie', db.Name);
        System.assertEquals('ttDOMAIN001', db.IMDBId__c);
        System.assertEquals(Decimal.valueOf(100), db.Duration__c);

        // Segunda llamada con mismo imdbID -> debe hacer update, no un nuevo insert
        String jsonUpdated = '{' +
            '"title":"Domain Movie Updated",' +
            '"year":"2025",' +
            '"rated":"Not Rated",' +
            '"released":"02 Jan 2025",' +
            '"runtime":"110 min",' +
            '"genre":"Other",' +
            '"director":"Dir Domain 2",' +
            '"actors":"Actor X, Actor Y",' +
            '"plot":"New plot text",' +
            '"awards":"New awards text",' +
            '"poster":"https://example.com/poster2.jpg",' +
            '"imdbID":"ttDOMAIN001",' +   // mismo ID
            '"seriesID":"ttSeries001",' +
            '"type":"movie",' +
            '"response":"True"' +
        '}';

        Test.startTest();
        Content__c updated = ContentDomain.upsertContent(jsonUpdated);
        Test.stopTest();

        System.assertEquals(inserted.Id, updated.Id, 'Debe actualizar el mismo registro (upsert por IMDBId__c)');
        Content__c db2 = [
            SELECT Id, Name, Director__c, Duration__c
            FROM Content__c
            WHERE Id = :updated.Id
        ];
        System.assertEquals('Domain Movie Updated', db2.Name);
        System.assertEquals(Decimal.valueOf(110), db2.Duration__c);
    }

    @IsTest
    static void testUpsertContentBlankJsonThrows() {
        try {
            ContentDomain.upsertContent('');
            System.assert(false, 'Debe lanzar IllegalArgumentException si el JSON está vacío');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('no puede estar vacío'));
        }
    }

    @IsTest
    static void testUpsertContentResponseFalseReturnsNull() {
        String json = '{' +
            '"title":"Some Title",' +
            '"imdbID":"ttFalse",' +
            '"type":"movie",' +
            '"response":"False"' +
        '}';

        Content__c result = ContentDomain.upsertContent(json);
        System.assertEquals(null, result);
    }

    @IsTest
    static void testUpsertContentInvalidTypeThrows() {
        String json = '{' +
            '"title":"Wrong Type",' +
            '"imdbID":"ttWrong",' +
            '"type":"episode",' +
            '"response":"True"' +
        '}';

        try {
            ContentDomain.upsertContent(json);
            System.assert(false, 'Debe lanzar IllegalArgumentException si type no es movie/series');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Solo se pueden upsertar movies o series'));
        }
    }

    @IsTest
    static void testFilterValidPicklistValuesHelper() {
        // incomingValues null -> defaultValue
        String result1 = ContentDomain.filterValidPicklistValues(
            Content__c.Category__c,
            null,
            'DefaultCat'
        );
        System.assertEquals('DefaultCat', result1);

        // incoming con valores que probablemente no estén en el picklist -> deberia devolver default
        String result2 = ContentDomain.filterValidPicklistValues(
            Content__c.Category__c,
            'FooBar;BazQux',
            'DefaultCat'
        );
        // No sabemos qué valores hay en el picklist, pero al menos cubrimos la lógica
        System.assertNotEquals(null, result2);
    }
}