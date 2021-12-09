public with sharing class AuthHelper 
{
    private static String BASE_URL = 'https://api.einstein.ai/v2';
    private static String OAUTH2 = BASE_URL + '/oauth2/token';
    
	public static String getAccessToken() 
    {
        einsteinplay__Einstein_Settings__c settings = einsteinplay__Einstein_Settings__c.getOrgDefaults();
        JWT jwt = new JWT('RS256');
        String accessToken = '';
        string email = settings.einsteinplay__Einstein_EMail__c;
        
        //if (settings.einsteinplay__CertName__c == null) {
        	ContentVersion base64Content;
            // Try to retrieve certificate
  
            base64Content = [SELECT Title, VersionData FROM ContentVersion where Title='einstein_platform_ocr2' AND IsLatest=true LIMIT 1];

            String keyContents = base64Content.VersionData.tostring();
            keyContents = keyContents.replace('-----BEGIN RSA PRIVATE KEY-----', '');
            keyContents = keyContents.replace('-----END RSA PRIVATE KEY-----', '');
            keyContents = keyContents.replace('\n', '');
            jwt.pkcs8 = keyContents;
            jwt.cert = settings.einsteinplay__CertName__c;

            // Get a new token
            jwt.iss = 'developer.force.com';
            jwt.sub = email;
            jwt.aud = OAUTH2;
            jwt.exp = '3600';      
        
            //accessToken = Einstein_JWTBearerFlow.getAccessToken(OAUTH2, jwt);
       		accessToken = getAccessToken(OAUTH2, jwt);
                
        return accessToken;
    }
    
    public static String getAccessToken(String tokenEndpoint, JWT jwt) {
    
        String access_token = ''; 
        System.debug('**5');
        String body = 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=' + jwt.issue();        
        
        HttpRequest req = new HttpRequest();                                   
        req.setMethod('POST');        
        req.setEndpoint(tokenEndpoint);        
        req.setHeader('Content-type', 'application/x-www-form-urlencoded');        
        req.setBody(body);        
        System.debug('**6');
        Http http = new Http();                      
        HTTPResponse res = http.send(req);               
        if ( res.getStatusCode() == 200 ) 
        {            
            System.JSONParser parser = System.JSON.createParser(res.getBody());           
            while (parser.nextToken() != null) 
            {                
                if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) 
                {                    
                    parser.nextToken();                    
                    access_token = parser.getText();                    
                    break;                
                }            
            }        
        }        
        return access_token;
    }
}