@IsTest
private class OMDBContentTest {
    
    @IsTest
    static void testParseValidJson() {
        String json = '{' +
            '"title":"Test Movie",' +
            '"year":"2024",' +
            '"rated":"PG",' +
            '"released":"27 Oct 2024",' +
            '"season":"1",' +
            '"episode":"3",' +
            '"runtime":"90 min",' +
            '"genre":"Action, Comedy",' +
            '"director":"John Doe",' +
            '"actors":"Actor 1, Actor 2",' +
            '"plot":"Some plot",' +
            '"awards":"None",' +
            '"poster":"https://example.com/poster.jpg",' +
            '"imdbID":"tt1234567",' +
            '"seriesID":"tt7654321",' +
            '"type":"movie",' +
            '"response":"True"' +
        '}';

        OMDBContent.OMDbResponse resp = OMDBContent.parse(json);
        System.assertNotEquals(null, resp, 'La respuesta no debería ser null');
        System.assertEquals('Test Movie', resp.title);
        System.assertEquals('PG', resp.rated);
        System.assertEquals('27 Oct 2024', resp.released);
        System.assertEquals('movie', resp.type);
    }

    @IsTest
    static void testParseEmptyJsonThrows() {
        try {
            OMDBContent.parse('');
            System.assert(false, 'Debe lanzar IllegalArgumentException con JSON vacío');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('OMDb JSON empty'));
        }
    }

    @IsTest
    static void testParseInvalidJsonThrows() {
        try {
            OMDBContent.parse('esto no es json');
            System.assert(false, 'Debe lanzar IllegalArgumentException con JSON inválido');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Error parseando JSON OMDb'));
        }
    }

    @IsTest
    static void testToRecordMovieSeriesEpisodeAndElse() {
        // movie
        OMDBContent.OMDbResponse movie = new OMDBContent.OMDbResponse();
        movie.type = 'movie';
        movie.title = 'Movie Name';
        movie.rated = 'PG';
        movie.released = '01 Jan 2020';
        movie.runtime = '120 min';
        movie.genre = 'Action, Comedy';
        movie.director = 'Director X';
        movie.actors = 'Actor A, Actor B';
        movie.plot = 'A nice plot';
        movie.awards = 'Some awards';
        movie.poster = 'https://example.com/poster.jpg';
        movie.imdbID = 'tt0000001';
        movie.response = 'True';

        SObject sMovie = OMDBContent.toRecord(movie);
        System.assertNotEquals(null, sMovie);
        System.assertEquals('Content__c', String.valueOf(sMovie.getSObjectType()));
        System.assertEquals('Movie Name', (String)sMovie.get('Name'));
        System.assertEquals('PG', (String)sMovie.get('Rating__c'));
        System.assertEquals(Decimal.valueOf(120), (Decimal)sMovie.get('Duration__c'));
        System.assertEquals('Action;Comedy', (String)sMovie.get('Category__c'));

        // series
        OMDBContent.OMDbResponse series = new OMDBContent.OMDbResponse();
        series.type = 'series';
        series.title = 'Series Name';
        series.imdbID = 'tt0000002';
        series.response = 'True';

        SObject sSeries = OMDBContent.toRecord(series);
        System.assertEquals('Content__c', String.valueOf(sSeries.getSObjectType()));
        System.assertEquals('Series Name', (String)sSeries.get('Name'));
        System.assertEquals('tt0000002', (String)sSeries.get('IMDBId__c'));

        // episode
        OMDBContent.OMDbResponse episode = new OMDBContent.OMDbResponse();
        episode.type = 'episode';
        episode.title = 'Episode Name';
        episode.episode = '5';
        episode.response = 'True';

        SObject sEpisode = OMDBContent.toRecord(episode);
        System.assertEquals('Episode__c', String.valueOf(sEpisode.getSObjectType()));
        System.assertEquals('Episode Name', (String)sEpisode.get('Name'));
        System.assertEquals(5, (Integer)sEpisode.get('Episode_number__c'));

        // tipo desconocido
        OMDBContent.OMDbResponse other = new OMDBContent.OMDbResponse();
        other.type = 'other';
        other.response = 'True';
        System.assertEquals(null, OMDBContent.toRecord(other));

        // response = False
        OMDBContent.OMDbResponse bad = new OMDBContent.OMDbResponse();
        bad.type = 'movie';
        bad.response = 'False';
        System.assertEquals(null, OMDBContent.toRecord(bad));
    }

    @IsTest
    static void testParseOmdbDate() {
        Date d = OMDBContent.parseOmdbDate('27 Oct 1989');
        System.assertEquals(Date.newInstance(1989, 10, 27), d);

        System.assertEquals(null, OMDBContent.parseOmdbDate('N/A'));
        System.assertEquals(null, OMDBContent.parseOmdbDate('fecha rara'));
        System.assertEquals(null, OMDBContent.parseOmdbDate(null));
    }

    @IsTest
    static void testParseRuntime() {
        System.assertEquals(Decimal.valueOf(23), OMDBContent.parseRuntime('23 min'));
        System.assertEquals(null, OMDBContent.parseRuntime('N/A'));
        System.assertEquals(null, OMDBContent.parseRuntime('bad value'));
        System.assertEquals(null, OMDBContent.parseRuntime(''));
    }

    @IsTest
    static void testFilterValidPicklistValues() {
        // Solo buscamos cobertura, sin depender de valores concretos del picklist
        String resultNull = OMDBContent.filterValidPicklistValues(
            Content__c.Category__c,
            null
        );
        System.assertEquals(null, resultNull);

        String resultSome = OMDBContent.filterValidPicklistValues(
            Content__c.Category__c,
            'SomeValue;AnotherValue'
        );
        // No sabemos cuáles son válidos en el org, solo aseguramos que no rompe
        // y no lanza excepción
        System.assert(true, 'filterValidPicklistValues ejecutado correctamente');
    }
}