/**
 * @author Onofrio Falco
 *
 * @date Jul 2017
 *
 * @description Opportunity records exporter
 */
global with sharing class OpportunityExporterController {
    //Standard controller params
    private ApexPages.StandardController stdController;
    private ApexPages.StandardSetController stdSetController;
    private String baseUrl;
    private final Opportunity opportunity;
    private final List<Opportunity> opportunities;
    private Map<String,String> params;
    private static final String separator = '\n';

    //Visualforce params
    public String renderAs {get; set;}
    public String contentType {get; set;}
    public String radioChoice {get; set;}
    public String fileName {get; set;}
    public String bodyJson {get; set;}

    //Remote action params
    public static String headerCsv {get; set;}
    public static String bodyCsv {get; set;}
    public static List<String> tableColumns {get; set;}
    private static Opportunity opportunity_st;
    private static List<Opportunity> opportunities_st;

    //getter and setters
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
    }

    private static void setOpportunity(SObject o) {
        OpportunityExporterController.opportunity_st = (Opportunity)o;
    }

    /**
     * StandardController constructor
     * @param  stdController [description]
     * @return               void
     *
     * @author Onofrio Falco
     */
    global OpportunityExporterController(ApexPages.StandardController stdController) {
        stdController = stdController;
        this.radioChoice = '';
        opportunity = (Opportunity)stdController.getRecord();
        OpportunityExporterController.opportunity_st = opportunity;
        params = ApexPages.currentPage().getParameters();
        baseUrl = Url.getSalesforceBaseUrl().toExternalForm();
        
        System.debug(LoggingLevel.DEBUG, 'Opportunity Record: ' + opportunity);
        if (opportunity == null || opportunity_st == null) {
            btnGoBack();
        }

        contentType = 'text/html;charset=utf-8';
        renderAs = 'html';
    }

    /**
     * StandardSETController constructor
     * @param  stdSetController [description]
     * @return                  is void
     *
     * @author Onofrio Falco
     */
    global OpportunityExporterController(ApexPages.StandardSetController stdSetController) {
        stdSetController = stdSetController;
        this.radioChoice = '';
        opportunities = (List<Opportunity>)stdSetController.getRecords();
        OpportunityExporterController.opportunities_st = opportunities;
        params = ApexPages.currentPage().getParameters();
        baseUrl = Url.getSalesforceBaseUrl().toExternalForm();
        
        System.debug(LoggingLevel.DEBUG, 'Opportunity Records: ' + opportunities);
        if ((opportunities == null || opportunities.isEmpty()) && (opportunities_st == null || opportunities_st.isEmpty())) {
            btnGoBack();
        }

        contentType = 'text/html;charset=utf-8';
        renderAs = 'html';
    }

    /**
     * Export records Main action
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
     * Export as PDF action 
     * @return page url
     * 
     * @author Onofrio Falco
     */
    public PageReference render_Pdf() {
        PageReference currentPage = stdController.view();
        PageReference ref = Page.OpportunityListExporter_Pdf;
        ref.setRedirect(true);

        Blob body;
        String filename = 'opportunity.pdf'; 
        Integer counter;

        try {
            body = currentPage.getContentAsPDF();
        } catch (VisualforceException e) {
            body = Blob.valueOf('Some Text');
        } finally {
            Attachment exist = [Select Name from Attachment where Name Like 'opportunity%'];
            if (exist != null) {
                String attachmentName = exist.Name.split('.')[0];
                String lastChar = attachmentName.substring(attachmentName.length() - 1);
                try {
                    counter = Integer.valueOf(lastChar);
                    filename = 'opportunity' + String.valueOf(counter) + '.pdf';
                } catch (TypeException t) {
                    //is not a digit
                    System.debug(LoggingLevel.ERROR, lastChar + ' is not a digit: ' + t.getMessage() + ' on line ' + t.getLineNumber());
                    filename = 'opportunity.pdf';
                }  
            }
            
            insert new Attachment(Body = body, Name = filename, IsPrivate = false, 
                ContentType = 'application/pdf;charset=utf-8');
        }
        
        contentType = 'application/pdf;charset=utf-8';
        renderAs = 'pdf';
        return 
            new PageReference(ref.getUrl());
    }

    /**
     * Export as JSON action
     * @return  a pageReference url
     *
     * @author Onofrio Falco
     */
    public PageReference render_Json() {
        PageReference ref = Page.OpportunityListExporter_Json_Csv;
        ref.setRedirect(true);
        List<Opportunity> opportunities = getOpportunities();
        this.bodyJson = Json.serializePretty(opportunities);
        contentType = 'application/json;charset=utf8';
        renderAs = 'json';
        return
            new PageReference(ref.getUrl());
    }

    /**
     * Export as CSV action 
     * @return page url
     *
     * @author Onofrio Falco
     */
    public PageReference render_Csv() {
        PageReference ref = Page.OpportunityListExporter_Json_Csv;
        ref.setRedirect(true);
        OpportunityExporterController.headerCsv = '"';
        OpportunityExporterController.bodyCsv = '"';
        contentType = 'text/csv;charset=utf-8';
        renderAs = 'csv';
        return 
            new PageReference(ref.getUrl());
    }

    @RemoteAction
    global static Boolean getColumnHeaders_Remoting(String jsonHeaders) {

        List<String> headers = (List<String>) Json.deserializeStrict(jsonHeaders, List<String>.class);
        Iterator<String> iter = headers.iterator();
        while(iter.hasNext()) {
            String header = iter.next();
            headerCsv += header;
            headerCsv += '"';
            if (iter.hasNext()) {
                headerCsv += ','; 
            }
            
            tableColumns.add(header);
        }

        //add separator
        OpportunityExporterController.headerCsv += separator;

        System.debug('Header CSV: ' + headerCsv);

        //CSV string regex
        //alternative:  (?:^|,)(\\\"(?:[^\\\"]+|\\\"\\\")*\\\"|[^,]*)
        Pattern p = Pattern.compile('^(?:(?:"((?:""|[^"])+)"|([^,]*))(?:$|,))+$');
        Matcher m = p.matcher(headerCsv);

        if(String.isNotBlank(headerCsv) && m.find())
            return 
                true;
        else
            return 
                false;
    }

    /**
     * [asCsv_RemoteAction description]
     * called from Visualforce page "OpportunityListExporter.page"
     * @param  jsonHeader table header values as json
     * @return            csv text
     *
     * @author Onofrio Falco
     */
    @RemoteAction
    global static String getCsvString_Remoting() {
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

        return 
            Json.serializePretty(new String[] { headerCsv, bodyCsv });
    }

    /**
     * Back action
     * @return go back to homepage
     *
     * @author Onofrio Falco
     */
    public PageReference btnGoBack() {
        return 
            new PageReference(baseUrl);
    }

    /**
     * Check URL action
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