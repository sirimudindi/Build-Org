public class EinsteinBotCaseSearch {  
  
    public class CaseOutput {  
      
        @InvocableVariable( required=true )  
        public String sStatus;  
    }  
      
    public class CaseInput {  
      
        @InvocableVariable( required=true )  
        public String sCaseNumber;  
          
    }  
  
    @InvocableMethod(label='Get Case Status')  
    public static List < CaseOutput > fetchCaseStatus( List < CaseInput > listCaseInputs ) {  
      
        List < CaseOutput > objOutputs = new List < CaseOutput >();  
        CaseOutput objOutput = new CaseOutput();  
        Set < String > strCaseNumbers = new Set < String >();  
        for ( CaseInput objCaseInput : listCaseInputs )  
            strCaseNumbers.add( objCaseInput.sCaseNumber );  
        objOutput.sStatus = [ SELECT Status FROM Case WHERE CaseNumber IN: strCaseNumbers LIMIT 1].Status;  
        objOutputs.add( objOutput );   
        return objOutputs;  
      
    }  
  
}