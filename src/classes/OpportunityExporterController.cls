/**
 * @author Onofrio Falco
 *
 * @date Jul 2017
 *
 * @description Opportunity records exporter
 */
global with sharing class OpportunityExporterController {
    //Standard controller params
    private final ApexPages.StandardController stdController;
    private final ApexPages.StandardSetController stdSetController;
    private final Opportunity opportunity;
    private final List<Opportunity> opportunities;
    private final Map<String,String> params;
    private String baseUrl;
    private static final String separator = '\n';

    //Visualforce params
    public String radioChoice {get; set;}
    public String bodyJson {get; set;}
    public static String fileName {get; set;}
    public static String renderAs {get; set;}
    public static String contentType {get; set;}

    //Remote action params
    public static String headerCsv {get; set;}
    public static String bodyCsv {get; set;}
    public static List<String> tableColumns {get; set;}
    private static Opportunity opportunity_st;
    private static List<Opportunity> opportunities_st;

    //Getter and setters
    public static List<Opportunity> getOpportunities() {
        return OpportunityExporterController.opportunities_st;
    }

    public static Opportunity getOpportunity() {
        return opportunity_st;
    }

    private static void setOpportunities(List<SObject> o) {
        if(opportunities_st == null) {
            opportunities_st = new List<Opportunity>();
        }
        if(!opportunities_st.isEmpty()) {
            opportunities_st.clear();
        }

        OpportunityExporterController.opportunities_st = (List<Opportunity>)o;

        System.debug(LoggingLevel.INFO, 'setOpportunities: ' + opportunities_st);

    }

    private static void setOpportunity(SObject o) {
        OpportunityExporterController.opportunity_st = (Opportunity)o;
    }

    /**
     * StandardController CONSTRUCTOR
     * @param  stdController [description]
     * @return               void
     *
     * @author Onofrio Falco
     */
    global OpportunityExporterController(ApexPages.StandardController stdController) {
        stdController = stdController;
        this.radioChoice = '';
        opportunity = (Opportunity)stdController.getRecord();
        params = ApexPages.currentPage().getParameters();
        baseUrl = Url.getCurrentRequestUrl().toExternalForm();

        System.debug(LoggingLevel.INFO, 'StandardController: Current request URL ' + baseUrl);

        if (baseUrl.containsIgnoreCase('pdf')) {
            //render as pdf
            renderAs = 'pdf';
            contentType = 'application/pdf;charset=utf-8';
        } else if (baseUrl.containsIgnoreCase('json')) {
            //render as json
            renderAs = 'html';
            contentType = 'application/x-JavaScript;charset=utf-8';
        } else if (baseUrl.containsIgnoreCase('csv')) {
            //render as csv
            renderAs = 'html';
            contentType = 'text/csv;charset=utf-8';
        } else {
            //default is html
            contentType = 'text/html;charset=utf-8';
            renderAs = 'html';
        }

        System.debug(LoggingLevel.FINEST, ' Content-Type: ' + contentType + ' | Render as: ' + renderAs + ' |');
        System.debug(LoggingLevel.DEBUG, 'StandardController: Opportunity Record ' + opportunity);


        if (opportunity == null || opportunity_st == null) {
            btnGoBack();
        }
    }

    /**
     * StandardSETController CONSTRUCTOR
     * @param  stdSetController [description]
     * @return                  is void
     *
     * @author Onofrio Falco
     */
    global OpportunityExporterController(ApexPages.StandardSetController stdSetController) {
        stdSetController = stdSetController;
        this.radioChoice = '';
        opportunities = (List<Opportunity>)stdSetController.getRecords();
        params = ApexPages.currentPage().getParameters();
        baseUrl = Url.getCurrentRequestUrl().toExternalForm();

        System.debug(LoggingLevel.INFO, 'StandardSetController: Current request URL ' + baseUrl);

        if (baseUrl.containsIgnoreCase('pdf')) {
            //render as pdf
            renderAs = 'pdf';
            contentType = 'application/pdf;charset=utf-8';
        } else if (baseUrl.containsIgnoreCase('json')) {
            //render as json
            renderAs = 'html';
            contentType = 'application/x-JavaScript;charset=utf-8';
        } else if (baseUrl.containsIgnoreCase('csv')) {
            //render as csv
            renderAs = 'html';
            contentType = 'application/csv;charset=utf-8';
        } else {
            //default is html
            renderAs = 'html';
            contentType = 'text/html;charset=utf-8';
        }
        
        System.debug(LoggingLevel.FINEST, ' Content-Type: ' + contentType + ' | Render as: ' + renderAs + ' |');
        System.debug(LoggingLevel.DEBUG, 'StandardSetController: Opportunity Records ' + opportunities);

        
        if (opportunities == null || opportunities_st == null) {
            btnGoBack();
        }
    }

    /**
     * Export records Main ACTION
     * @return page url
     *
     * @author Onofrio Falco
     */
    public PageReference btnExportRecords() {

        if (String.isEmpty(radioChoice)) {
            OpportunityExporterController.addMessage(ApexPages.Severity.ERROR, 'Select an export format');
            return 
                null;
        } 
        else
            if (radioChoice.toUpperCase() == 'CSV') {
                return 
                    render_Csv();
            }
        else
            if (radioChoice.toUpperCase() == 'PDF') {
                return 
                    render_Pdf();
            }
        else 
            if (radioChoice.toUpperCase() == 'JSON') {
                return 
                    render_Json();
            }
        else {

            OpportunityExporterController.addMessage(ApexPages.Severity.FATAL, 'An error has occurred');
            return 
                null;
        }
    }

    /**
     * Export as PDF ACTION 
     * @return page url
     * 
     * @author Onofrio Falco
     */
    public PageReference render_Pdf() {
        PageReference currentPage = ApexPages.currentPage();
        PageReference ref = Page.OpportunityListExporter_Pdf;
        ref.setRedirect(true);

        List<Attachment> attachments = new List<Attachment>();
        if (opportunities_st == null || opportunities_st.isEmpty()) {
            OpportunityExporterController.setOpportunities(opportunities);
        }

        Blob body;
        String defaultFilename = 'opportunity.pdf'; 
        Integer counter;
        Database.SaveResult dbRes = null;

        try {
            body = currentPage.getContentAsPDF();
        } catch (VisualforceException v) {
            body = Blob.valueOf('Some Text');


        } catch (Exception e) 
        {
            String fatalMsg = e.getMessage() + ' on line ' + e.getLineNumber();

            System.debug(LoggingLevel.ERROR, e.getMessage() + ' on line ' + e.getLineNumber());
            OpportunityExporterController.addMessage(ApexPages.Severity.FATAL, fatalMsg);
            return null;

        } finally {

            attachments = [Select Name from Attachment where Name Like 'opportunity%.pdf' order by CreatedDate desc];
            
            if (!attachments.isEmpty()) {
                Attachment singleAttachment = attachments.get(0);

                System.debug(LoggingLevel.DEBUG, 'Attachment Pdf: ' + singleAttachment.Name);

                String attachmentName = singleAttachment.Name.split('\\.')[0];
                String lastChar = attachmentName.substring(attachmentName.length() - 1);
                
                try {
                    counter = Integer.valueOf(lastChar);
                    defaultFilename = 'opportunity' + String.valueOf(counter) + '.pdf';
                } catch (TypeException t) {
                    //is not a digit
                    System.debug(LoggingLevel.ERROR, lastChar + ' is not a digit: ' + t.getMessage() + ' on line ' + t.getLineNumber());
                    defaultFilename = 'opportunity.pdf';
                }  
            }

            if(fileName != null) 
            {
                dbRes = Database.insert(new Attachment(Body = body, Name = defaultFilename, IsPrivate = false, 
                    ContentType = 'application/pdf;charset=utf-8', ParentId = getRandomOpportunity().Id));
            
            } else 
            {
                dbRes = Database.insert(new Attachment(Body = body, Name = defaultFilename, IsPrivate = false, 
                    ContentType = 'application/pdf;charset=utf-8', ParentId = getRandomOpportunity().Id));
            }
            
        
        }
        
        return 
            new PageReference(ref.getUrl());
    }

    /**
     * Export as JSON ACTION
     * @return  a pageReference url
     *
     * @author Onofrio Falco
     */
    public PageReference render_Json() {
        PageReference ref = Page.OpportunityListExporter_Json;
        ref.setRedirect(true);
        List<Opportunity> opportunities = getOpportunities();
        this.bodyJson = Json.serializePretty(opportunities);
        Blob body = Blob.valueOf(bodyJson);

        if(opportunities_st == null || opportunities_st.isEmpty()) {
            OpportunityExporterController.setOpportunities(opportunities);
        }

        Integer counter;
        List<Attachment> attachments = new List<Attachment>();
        String defaultFileName = 'opportunity.json';
        String lastChar;
        Database.SaveResult dbRes = null;
        
        try {
            attachments = [Select Name from Attachment where Name Like 'opportunity%.json' order by CreatedDate desc];

            if (!attachments.isEmpty()) {
                Attachment singleAttachment = attachments.get(0);

                System.debug(LoggingLevel.DEBUG, 'Attachment Json: ' + singleAttachment.Name);

                String attachmentName = singleAttachment.Name.split('\\.')[0];
                lastChar = attachmentName.substring(attachmentName.length() - 1);
                
                try {
                    counter = Integer.valueOf(lastChar);
                    defaultFileName = 'opportunity' + String.valueOf(counter) + '.json';
                } catch (TypeException t) {
                    //is not a digit
                    System.debug(LoggingLevel.ERROR, lastChar + ' is not a digit: ' + t.getMessage() + ' on line ' + t.getLineNumber());
                    defaultFileName = 'opportunity.json';
                }  
            }

        } catch(TypeException t) {
            System.debug(LoggingLevel.ERROR, lastChar + ' is not a digit: ' + t.getMessage() + ' on line ' + t.getLineNumber());
        
        } catch(Exception e) 
        {

            String fatalMsg = e.getMessage() + ' on line ' + e.getLineNumber();

            System.debug(LoggingLevel.ERROR, e.getMessage() + ' on line ' + e.getLineNumber());
            OpportunityExporterController.addMessage(ApexPages.Severity.FATAL, fatalMsg);
            return null;


        } finally {

            if(fileName != null) 
            {
                dbRes = Database.insert(new Attachment(Body = body, Name = fileName, IsPrivate = false, 
                    ContentType = 'application/x-Javascript;charset=utf-8', ParentId = getRandomOpportunity().Id));
            
            } else 
            {
                dbRes = Database.insert(new Attachment(Body = body, Name = defaultFilename, IsPrivate = false, 
                    ContentType = 'application/x-Javascript;charset=utf-8', ParentId = getRandomOpportunity().Id));
            }
            
        
        }

        return
            new PageReference(ref.getUrl());
    }

    /**
     * Export as CSV ACTION 
     * @return page url
     *
     * @author Onofrio Falco
     */
    public PageReference render_Csv() {
        PageReference ref = Page.OpportunityListExporter_Csv;
        ref.setRedirect(true);
        return 
            new PageReference(ref.getUrl());
    }

    /**
     * Back ACTION
     * @return go back to homepage
     *
     * @author Onofrio Falco
     */
    public PageReference btnGoBack() {
        return 
            new PageReference(baseUrl);
    }

    /**
     * Check URL ACTION
     *
     * @author Onofrio Falco
     */
    public void checkUrl() {
        if (!params.containsKey('id')) {
            OpportunityExporterController.addMessage(ApexPages.Severity.FATAL, 'Oops, you missed something');
        }
    }

    /**
     * ToString method overridden
     * @return toString
     *
     * @author Onofrio Falco
     */
    public override String toString() {
        return 
            (String)opportunity.get('Name') + ' (' + (Id)opportunity.get('Id') + ')';
    }

    /**
     * Radio button selectoptions
     * @return SelectOption radio list
     *
     * @author Onofrio Falco
     */
    public List<SelectOption> getExportOptions() {
        List<SelectOption> radioBtns = new List<SelectOption>();
        radioBtns.add(new SelectOption('csv', '.csv'));
        radioBtns.add(new SelectOption('pdf', '.pdf'));
        radioBtns.add(new SelectOption('json', '.json'));

        radioBtns.sort();
        return 
            radioBtns;
    }

    public static void addMessage(ApexPages.Severity severity, String message) {
        ApexPages.addMessage(new ApexPages.message(severity, message));
    }

    /**
     * Extract a random Opportunity from Standard Set controller
     * @return an Opportunity
     *
     * @author Onofrio Falco
     */
    public static Opportunity getRandomOpportunity() {
        Integer randGen = Math.mod(Math.abs(Crypto.getRandomInteger()), opportunities_st.size());
        return 
            opportunities_st.get(randGen);
    }

    /**
     * [getColumnHeaders_Remoting description]
     * called from Visualforce page "OpportunityListExporter_Pdf.page"
     * @param  jsonHeaders table headers in json
     * @return             a boolean
     *
     * @author Onofrio Falco
     */
    @RemoteAction
    global static Boolean getColumnHeaders_Remoting(String jsonHeaders) {
        tableColumns = new List<String>();
        OpportunityExporterController.headerCsv = '';

        List<String> objectDeserialized = (List<String>)Json.deserialize(jsonHeaders, List<String>.class);
        System.debug('Object deserialized: ' + objectDeserialized);
        
        Iterator<String> iter = objectDeserialized.iterator();
        while(iter.hasNext()) {
            String header = iter.next();
            headerCsv += header;
            if (iter.hasNext()) {
                headerCsv += ','; 
            }
            
            tableColumns.add(header);
        }

        //add separator
        OpportunityExporterController.headerCsv += separator;

        System.debug('Header CSV: ' + headerCsv);

        

        if(String.isNotBlank(headerCsv))
            return 
                true;
        else
            return 
                false;
    }

    /**
     * [asCsv_RemoteAction description]
     * called from Visualforce page "OpportunityListExporter_Csv.page"
     * @param  jsonHeader table header values as json
     * @return            csv text
     *
     * @author Onofrio Falco
     */
    @RemoteAction
    global static String getCsvString_Remoting() {
        OpportunityExporterController.bodyCsv = '"';
        Database.SaveResult dbRes = null;


        String comma = '",';
        
        Iterator<Opportunity> iterOppty = getOpportunities().iterator();
        while(iterOppty.hasNext()) {
            Opportunity opp = iterOppty.next();

            //build body csv string
            bodyCsv += opp.Name + comma + opp.Amount + comma + opp.ExpectedRevenue + 
            comma + opp.StageName + comma + opp.Probability + comma + opp.Type + comma + 
            opp.ForecastCategory + comma + opp.IsWon + '"';
            
            if (iterOppty.hasNext()) {
                bodyCsv += separator; //add separator
                bodyCsv += '"';
            }
        }

        bodyCsv += separator;
        headerCsv = headerCsv.trim();
        bodyCsv = bodyCsv.trim();


        System.debug('Body CSV: ' + bodyCsv);

        //CSV string regex
        //alternative:  (?:^|,)(\\\"(?:[^\\\"]+|\\\"\\\")*\\\"|[^,]*)
        Pattern p = Pattern.compile('^(?:(?:"((?:""|[^"])+)"|([^,]*))(?:$|,))+$');
        Matcher m = p.matcher(bodyCsv);

        if ((String.isBlank(headerCsv) || String.isBlank(bodyCsv)) && !m.find()) {
            return null;
        }


        Blob body = Blob.valueOf(headerCsv + bodyCsv);
        Integer counter;
        String defaultFileName = 'opportunity.csv';

        List<Attachment> attachments = [Select Name from Attachment where Name Like 'opportunity%.csv' order by CreatedDate desc];

        if(attachments.isEmpty()) {
            Attachment singleAttachment = attachments.get(0);
            System.debug(LoggingLevel.DEBUG, 'Attachment Csv: ' + singleAttachment.Name);

            String attachmentName = singleAttachment.Name.split('\\.')[0];
            String lastChar = attachmentName.substring(attachmentName.length() - 1);
            
            try {
                counter = Integer.valueOf(lastChar);
                defaultFileName = 'opportunity' + String.valueOf(counter) + '.csv';
            } catch (TypeException t) {
                //is not a digit
                System.debug(LoggingLevel.ERROR, lastChar + ' is not a digit: ' + t.getMessage() + ' on line ' + t.getLineNumber());
                defaultFileName = 'opportunity.csv';
            }  
        }

        if(fileName != null) 
        {
            dbRes = Database.insert(new Attachment(Body = body, Name = fileName, IsPrivate = false, 
                ContentType = 'text/csv;charset=utf-8', ParentId = getRandomOpportunity().Id));
        
        } else 
        {
            dbRes = Database.insert(new Attachment(Body = body, Name = defaultFilename, IsPrivate = false, 
                ContentType = 'text/csv;charset=utf-8', ParentId = getRandomOpportunity().Id));
        }
            
        

        return 
            Json.serializePretty(new String[] { headerCsv, bodyCsv });
    }

    /**
     * Set the content-type of Visualforce page
     * @param  renderAs     first attribute
     * @param  contentType  second attribute
     * @return             a boolean
     *
     * @author Onofrio Falco
     */
    @RemoteAction
    global static Boolean setContentType_Remoting(String rAs, String cType) {
        OpportunityExporterController.contentType = cType;
        OpportunityExporterController.renderAs = rAs;
        if(contentType == null && renderAs == null) {
            return false;

        }

        return true;
    }

    /**
     * UTILS: Used to read a delimited file.
     *
     * @author nicocrm
     */
    global class SSSCsvReader {
        private String delim = ',';
        // the input data
        private String[] buffer;
        
        global SSSCsvReader(String data) {
            this.buffer = data.split('\n'); 
        }
        
        global SSSCsvReader(String data, String delim) {
            this.buffer = data.split('\n'); 
            this.delim = delim;
        }
        
        /**
         * Read and parse next available line.  Return null if end of stream.
         */
        public String[] readLine() {
            if(buffer.size() == 0)
                return null;
            String line = this.buffer.remove(0);
            String[] parts = new String[] {};
            while(line != '') {
                Integer next = 0;
                if(line.startsWith('"')) {
                    line = line.substring(1); // strip initial
                    Integer quoteIndex = findQuote(line, 0);
                    while(quoteIndex == -1){
                        if(buffer.size() == 0) {
                            // EOT!
                            quoteIndex = line.length();
                        } else { 
                            // grab the next line
                            Integer skip = line.length();
                            line += '\n' + this.buffer.remove(0);
                            quoteIndex = findQuote(line, skip);
                        }
                    }
                    // advance to comma
                    next = quoteIndex + 1;
                    parts.add(line.substring(0, quoteIndex).replace('""', '"'));
                } else {
                    next = line.indexOf(this.delim, next);
                    if(next == -1)
                        next = line.length();
                    // NB in Substring, "endindex" is the index of the character AFTER the last index to get
                    parts.add(line.substring(0, next));
                }       
                if(next == line.length() - 1)
                    // case of a terminating comma.
                    parts.add('');
                line = next < line.length() ? line.substring(next+1) : '';
            }
            if(parts.size() == 0)
                // empty string - we still want to return something...
                parts.add('');
            return 
                parts;
        }
        
        private Pattern quotePattern = Pattern.compile('(?<!")"(?!")');

        /**
         * Find next quote in the line
         */
        private Integer findQuote(String line, Integer skip) {
            Matcher m = quotePattern.matcher(line);
            m.region(skip, m.regionEnd());
            if(!m.find())
                return -1;
            return 
                m.start();
        }
    }
}