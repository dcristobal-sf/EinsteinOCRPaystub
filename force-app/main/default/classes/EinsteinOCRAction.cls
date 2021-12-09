global class EinsteinOCRAction {
    private final static string Boundary = '1ff13444ed8140c7a32fc4e6451aa76d';
    
	/*public static OCRResult getDownloadUrl(string documentId, string covidRecordId)
    {
        List<ContentVersion> versions = [SELECT VersionData, FileType FROM ContentVersion WHERE ContentDocumentId =: documentId];

        if(!versions.isEmpty())
        {
			/*create ContentDocumentLink  record 
			ContentDocumentLink conDocLink = New ContentDocumentLink();
			conDocLink.LinkedEntityId = covidRecordId;
			conDocLink.ContentDocumentId = documentId;
			conDocLink.shareType = 'V';
			insert conDocLink;*/
        /*    System.debug('Record: '+covidRecordId);
            return ContructHttpRequest(versions.get(0), documentId, covidRecordId);
        }

        return null;
    }*/

    @InvocableMethod(label='Get Name from Paystub' description='Returns name in the paystub.')
    public static void OCRGetNamePaystub(List<PaystubInfo> paystubInfo) 
    {
        System.debug('********* >>>>');
        
        ContentVersion contentVersion = [SELECT VersionData FROM ContentVersion WHERE Id =:paystubInfo[0].contentVersionId LIMIT 1];
        
        string authToken = AuthHelper.getAccessToken();
        //OCRResult res = new OCRResult();
        
        System.debug(authToken);
        
        HttpRequest request = new HttpRequest();
        request.setHeader('Authorization', 'Bearer ' + authToken);
        request.setHeader('Cache-Control', 'no-cache');
        request.setHeader('Content-Type', GetContentType());
        request.setBodyAsblob(build(contentVersion));
        request.setMethod('POST');
        
        request.setEndpoint('https://api.einstein.ai/v2/vision/ocr');
        
        Http http = new Http();
        HTTPResponse response = http.send(request);
        
        //res.imageBase64 = EncodingUtil.base64Encode(contentVersion.VersionData);
        //res.imageType = contentVersion.FileType;
        
        String name = scanResult(response.getBody(), paystubInfo[0].column, paystubInfo[0].row);
        
        System.debug('***********');
        System.debug('Column: '+paystubInfo[0].column);
        System.debug('Row: '+paystubInfo[0].row);
        System.debug('Read: '+name);
        System.debug('***********');
        
        setPaystubName (name, paystubInfo[0].objectId, paystubInfo[0].objectName, paystubInfo[0].attributeName, paystubInfo[0].searchContact);
        //res.result = response.getBody();
        //TestResult testResult = debugResult(keyWords);
        //res.result = testResult.toString();
        //res.text = resultBoundaries(keyWords);
        
        //setTestStatus (covidRecordId, documentId, testResult.resultType, testResult.resultText);

        /*if(!string.isBlank(paystubId))
        {
            //Meter la respuesta en la ubicación adecuada
        }*/

        return;
    }
    
    @future 
    public static void setPaystubName (String name, Id objectId, String objectName, String attributeName, Boolean searchContact) {
          
  		List<sobject> recs = Database.query('select '+attributeName+' from '+objectName+' where Id=\''+objectId+'\' limit 1');
       	recs[0].put(attributeName,name);  
  
  		
        /*
        Paystub__c aPaystub = [Select Id, Name__c from Paystub__c where Id=:paystubId LIMIT 1];
        aPaystub.Name__c = name;
        */
        if(searchContact == true && name.length()>5) {
        	String searchquery='FIND\''+name+'\'IN ALL FIELDS RETURNING Contact(Name)';
        	List<List<Contact>>searchList=search.query(searchquery);
			System.debug(searchList);
        	if(searchList.size()>0) {
        		Contact[] searchContacts = (Contact[])searchList[0];
           		recs[0].put('Contact__c',searchContacts[0].Id);
        	}
        }
        update recs;
    }
        
    
    public static Blob build(ContentVersion contentVersion) {
        String body = '';
        body += WriteBoundary();
       // body += WriteBodyParameter('modelId', 'tabulatev2');
        body += WriteBodyParameter('modelId', EncodingUtil.urlEncode('tabulatev2', 'UTF-8'));
        body += WriteBoundary();
        body += WriteBodyParameter('task', 'table');
        body += WriteBoundary();
         
        body += WriteBoundary();
        //body += WriteBodyParameter('sampleLocation', filename);

        body += WriteBodyParameter('sampleBase64Content', EncodingUtil.base64Encode(contentVersion.VersionData));
        body += WriteBoundary(EndingType.CrLf);
        Blob bodyBlob = EncodingUtil.base64Decode(body);
        return bodyBlob;
    }
    
    public static string WriteBoundary() 
    {
        string value = '--' + Boundary + '\r\n';
        blob valueBlob = blob.valueOf(value);
        return EncodingUtil.base64Encode(valueBlob);
    }
    
    public enum EndingType 
    {
        Cr,
        CrLf,
        None
    }
    
    public static string WriteBoundary(EndingType ending) 
    {
        string value = '';
        
        if (ending == EndingType.Cr) 
        {
            //  The file's base64 was padded with a single '=',
            //  so it was replaced with '\r'. Now we have to
            //  prepend the boundary with '\n' to complete
            //  the line break.
            value += '\n';
        } else if (ending == EndingType.None) 
        {
            //  The file's base64 was not padded at all,
            //  so we have to prepend the boundary with
            //  '\r\n' to create the line break.
            value += '\r\n';
        }
        //  Else:
        //  The file's base64 was padded with a double '=',
        //  so they were replaced with '\r\n'. We don't have to
        //  do anything to the boundary because there's a complete
        //  line break before it.
        
        value += '--' + Boundary + '--';
        
        blob valueBlob = blob.valueOf(value);
        
        return EncodingUtil.base64Encode(valueBlob);
    }
    
    public static string WriteBodyParameter(string key, string value) 
    {
        string contentDisposition = 'Content-Disposition: form-data; name="' + key + '"';
        string contentDispositionCrLf = contentDisposition + '\r\n\r\n';
        blob contentDispositionCrLfBlob = blob.valueOf(contentDispositionCrLf);
        string contentDispositionCrLf64 = EncodingUtil.base64Encode(contentDispositionCrLfBlob);
        string content = SafelyPad(contentDisposition, contentDispositionCrLf64, '\r\n\r\n');
        string valueCrLf = value + '\r\n';
        blob valueCrLfBlob = blob.valueOf(valueCrLf);
        string valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob);
        
        content += SafelyPad(value, valueCrLf64, '\r\n');
        
        return content;
    }
    
    public static String getBoundary() 
    {
        return Boundary;
    }
    
    public static string GetContentType() 
    {
        return 'multipart/form-data; charset="UTF-8"; boundary="' + Boundary + '"';
    }
    
    public static string SafelyPad(string value, string valueCrLf64, string lineBreaks) 
    {
        string valueCrLf = '';
        blob valueCrLfBlob = null;
        
        while (valueCrLf64.endsWith('=')) {
            value += ' ';
            valueCrLf = value + lineBreaks;
            valueCrLfBlob = blob.valueOf(valueCrLf);
            valueCrLf64 = EncodingUtil.base64Encode(valueCrLfBlob);
        }
        
        return valueCrLf64;
    }
    
    public static String scanResult (string result, Integer column, Integer row) {
        JSONParser parser = JSON.createParser(result);
        boolean takeNext = true;
        Probability prob = null;
        while (parser.nextToken() != null) {
        	if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
            		if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                    	prob = (Probability)parser.readValueAs(Probability.class);
                    	// For debugging purposes, serialize again to verify what was parsed.
                    	//String s = JSON.serialize(prob);
                    	//system.debug('Serialized probability: ' + prob);
                        if(prob.attributes.cellLocation.colIndex == column) {
                        	if(prob.attributes.cellLocation.rowIndex == row) {
                            	return prob.label;
                        	} 
                        }
                    	// Skip the child start array and start object markers.
                    	parser.skipChildren();
                    }
                }
            }
        }
        return '';
    }
    
    public class Probability {
    	public Double probability;
    	public String label;
        Attributes attributes;
    	BoundingBox boundingBox;
    
    	public Probability(Double probability, String label, Attributes attributes, BoundingBox boundingBox) {
        	probability = probability;
        	label = label;
            attributes = attributes;
        	boundingBox = boundingBox;
    	}
	}  
 
	public class BoundingBox {
    	public Integer minX;
        public Integer minY;
    	public Integer maxX;
        public Integer maxY;
	}
    
    public class Attributes {
    	CellLocation cellLocation;
        public Integer pageNumber;
        public Attributes (CellLocation cellLocation, Integer pageNumber) {
            cellLocation = cellLocation;
            pageNumber = pageNumber;
        }
	}
    
    public class CellLocation {
    	public Integer colIndex;
        public Integer rowIndex;
	}
    
    global class PaystubInfo {
    	@InvocableVariable(label='ContentVersion Id' description='Id of ContentVersion where doc is attached' required=true)
    	global ID contentVersionId;

    	@InvocableVariable(label='Object Id' description='Id of the object where text is being set' required=true)
    	global ID objectId;
        
        @InvocableVariable(label='Document Column' description='Column of the doc where text is being read' required=true)
    	global Integer column;
        
        @InvocableVariable(label='Document Row' description='Row of the doc where text is being read' required=true)
    	global Integer row;
        
        @InvocableVariable(label='Object Name' description='API Name of object whose attribuute is being set' required=true)
    	global String objectName;
        
        @InvocableVariable(label='Attribute Name' description='API Name of attribute being set' required=true)
    	global String attributeName;
        
        @InvocableVariable(label='Search Contact' description='Flag to search Contact linked' required=true)
    	global Boolean searchContact;
    }
}