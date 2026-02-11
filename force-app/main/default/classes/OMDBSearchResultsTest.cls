@IsTest
private class OMDBSearchResultsTest {
    
    @IsTest
    static void testParseSearchArray() {
        String json = '{' +
            '"Search": [' +
                '{"title":"Movie 1","year":"2020","type":"movie","imdbID":"tt1","response":"True"},' +
                '{"title":"Movie 2","year":"2021","type":"series","imdbID":"tt2","response":"True"}' +
            '],' +
            '"totalResults":"2",' +
            '"Response":"True"' +
        '}';

        OMDBSearchResults res = OMDBSearchResults.parse(json);
        System.assertNotEquals(null, res);
        System.assertEquals('True', res.Response);
        System.assertEquals(2, res.totalResults);
        System.assertNotEquals(null, res.Search);
        System.assertEquals(2, res.Search.size());
        System.assertEquals('Movie 1', res.Search[0].title);
    }

    @IsTest
    static void testParseSingleObjectWithResponseTrue() {
        String json = '{' +
            '"title":"Single Movie",' +
            '"year":"2022",' +
            '"type":"movie",' +
            '"imdbID":"tt3",' +
            '"response":"True",' +
            '"Response":"True"' +
        '}';

        OMDBSearchResults res = OMDBSearchResults.parse(json);
        System.assertNotEquals(null, res.Search);
        System.assertEquals(1, res.Search.size());
        System.assertEquals('Single Movie', res.Search[0].title);
        System.assertEquals('True', res.Response);
    }

    @IsTest
    static void testGetFirstOrSingleFromSearchArray() {
        String json = '{' +
            '"Search": [' +
                '{"title":"Movie 1","year":"2020","type":"movie","imdbID":"tt1","response":"True"}' +
            '],' +
            '"totalResults":"1",' +
            '"Response":"True"' +
        '}';

        OMDBContent.OMDbResponse first = OMDBSearchResults.getFirstOrSingle(json);
        System.assertNotEquals(null, first);
        System.assertEquals('Movie 1', first.title);
    }

    @IsTest
    static void testGetFirstOrSingleFallbackToSingleObject() {
        // JSON sin campo Search ni Response -> fuerza el fallback
        String json = '{' +
            '"title":"Fallback Movie",' +
            '"year":"2020",' +
            '"type":"movie",' +
            '"imdbID":"ttX"' +
        '}';

        OMDBContent.OMDbResponse first = OMDBSearchResults.getFirstOrSingle(json);
        System.assertNotEquals(null, first);
        System.assertEquals('Fallback Movie', first.title);
    }

    @IsTest
    static void testGetFirstOrSingleEmptyReturnsNull() {
        OMDBContent.OMDbResponse first = OMDBSearchResults.getFirstOrSingle('');
        System.assertEquals(null, first);
    }

    @IsTest
    static void testParseEmptyJsonThrows() {
        try {
            OMDBSearchResults.parse('');
            System.assert(false, 'Debe lanzar IllegalArgumentException con JSON vacío');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('OMDb Search JSON empty'));
        }
    }
}