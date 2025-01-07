public class OT_consentData {
    /*
     * Takes in a purpose and returns the purpose ID
     * Add your Purposes and IDs here. The purpose name must match the
     * purpose names entered in trigger. 
     */ 
    public string getPurposeID(string purpose){
        Map<String, String> purposeIDs = new Map<String, String>();
        purposeIDs.put('Mail', '4e5f8f35-2421-45cc-a9a9-4e3d0d2bcdff');
        purposeIDs.put('Email', 'b4cdc483-c84f-41cd-9961-5285a0593d1a');
        purposeIDs.put('Phone', '2caab5e4-8be6-4599-ad2a-9718f680f8e6');
        purposeIDs.put('SMS', '7bdd6f95-4fdf-45ee-9e34-159a85f4a0f2');
        purposeIDs.put('Meetings', '02baec12-3ed4-4ccc-81b1-65d73a569cff');
        purposeIDs.put('Marketing Materials', '30ba0c45-35fb-43c4-bac4-d899408c7773');
        
        if(purpose == null){ return '';}
        else{ return purposeIDs.get(purpose);}
    }
    
    /*
     *  Generates the purposes schema that will be sent to OneTrust
     */ 
    public string buildPurposesSchema(List<OT_consentPurpose> selectedPurposes){
        string purposeSchema='';
        for(integer i=0; i<selectedPurposes.size(); i++){
            OT_consentPurpose purpose = selectedPurposes.get(i);
            string temp = '{"Id": "' + purpose.purposeId + '", "transactionType": "' + purpose.transactionType + '"}';
            if(i < (selectedPurposes.size()-1)){purposeSchema = purposeSchema+temp+',';}
            else{purposeSchema = purposeSchema+temp;}
        }
        return purposeSchema;
    }
    
    /*
     * Add the code for your expected payload here.
     * This code is generated in OneTrust and can be found under the Custom API tab of the Collection Point. 
     */
    public string SFDC_Collection_Point(string DataSubjectID,List<OT_consentPurpose> selectedPurposes){
        return( '{\n'+
                    '"identifier": "'+ DataSubjectID +'",\n'+
                    '"requestInformation": "eyJhbGciOiJSUzUxMiJ9.eyJvdEp3dFZlcnNpb24iOjEsInByb2Nlc3NJZCI6ImFhNmEzNmI5LWIyNjUtNDIwMy05MTBkLTYyYzY1NTJlMmYwNiIsInByb2Nlc3NWZXJzaW9uIjoxLCJpYXQiOiIyMDIxLTAzLTIyVDEzOjUyOjQyLjYxNyIsIm1vYyI6IkFQSSIsInN1YiI6IkVtYWlsIiwiaXNzIjpudWxsLCJ0ZW5hbnRJZCI6IjZiMTU0MmNkLTFkOTUtNGVlOS05OGJhLTViMmU3NjM5ZWFhYyIsImRlc2NyaXB0aW9uIjoiQ2FwdHVyZSBjb21tdW5pY2F0aW9uIGNoYW5uZWwgY29uc2VudHMgZnJvbSBIZWFsdGggQ2xvdWQgUGF0aWVudCBQb3J0YWwuIiwiY29uc2VudFR5cGUiOiJDT05ESVRJT05BTFRSSUdHRVIiLCJkb3VibGVPcHRJbiI6ZmFsc2UsInJlY29uZmlybUFjdGl2ZVB1cnBvc2UiOmZhbHNlLCJhdXRoZW50aWNhdGlvblJlcXVpcmVkIjpmYWxzZSwiZHluYW1pY0NvbGxlY3Rpb25Qb2ludCI6ZmFsc2UsInBvbGljeV91cmkiOm51bGwsImFsbG93Tm90R2l2ZW5Db25zZW50cyI6ZmFsc2UsInB1cnBvc2VzIjpbeyJpZCI6ImI0Y2RjNDgzLWM4NGYtNDFjZC05OTYxLTUyODVhMDU5M2QxYSIsInZlcnNpb24iOjEsInBhcmVudElkIjpudWxsLCJ0b3BpY3MiOltdLCJjdXN0b21QcmVmZXJlbmNlcyI6W119LHsiaWQiOiI0ZTVmOGYzNS0yNDIxLTQ1Y2MtYTlhOS00ZTNkMGQyYmNkZmYiLCJ2ZXJzaW9uIjoxLCJwYXJlbnRJZCI6bnVsbCwidG9waWNzIjpbXSwiY3VzdG9tUHJlZmVyZW5jZXMiOltdfSx7ImlkIjoiMzBiYTBjNDUtMzVmYi00M2M0LWJhYzQtZDg5OTQwOGM3NzczIiwidmVyc2lvbiI6MSwicGFyZW50SWQiOm51bGwsInRvcGljcyI6W10sImN1c3RvbVByZWZlcmVuY2VzIjpbXX0seyJpZCI6IjAyYmFlYzEyLTNlZDQtNGNjYy04MWIxLTY1ZDczYTU2OWNmZiIsInZlcnNpb24iOjEsInBhcmVudElkIjpudWxsLCJ0b3BpY3MiOltdLCJjdXN0b21QcmVmZXJlbmNlcyI6W119LHsiaWQiOiIyY2FhYjVlNC04YmU2LTQ1OTktYWQyYS05NzE4ZjY4MGY4ZTYiLCJ2ZXJzaW9uIjoxLCJwYXJlbnRJZCI6bnVsbCwidG9waWNzIjpbXSwiY3VzdG9tUHJlZmVyZW5jZXMiOltdfSx7ImlkIjoiN2JkZDZmOTUtNGZkZi00NWVlLTllMzQtMTU5YTg1ZjRhMGYyIiwidmVyc2lvbiI6MSwicGFyZW50SWQiOm51bGwsInRvcGljcyI6W10sImN1c3RvbVByZWZlcmVuY2VzIjpbXX1dLCJub3RpY2VzIjpbXSwiZHNEYXRhRWxlbWVudHMiOltdfQ.f5kIGrWHL5wDNRB3vritHqZ29NMN3R0VZ_m4jwgqSpZhdIDo8H0vBkQOXZVFADfxRYxvEJl7Lkk6byWIaNPbd0CK05x8jGh3wa-Slfph0hYRbJF4Kt7IpPzXa3KwxxEF82a2kw4FEyJ9pumJw38UpoypHNEGUkdFbvOeEKMmND_e4dO7MdedpXhKBL4eG-3FAp5J9E1It2XoPtfRPHi6ZdPhfymYlMSLcgsq-WeBcQGbnahLuJAokYNH40dI-aDaZ4kakKiZwzWZedneYqGTs7koVjs66q4hH1Q14c4shVdZL0zWCjr3EWrLnLIDoqfleckbTX2CZDWI_931KPXHVE4p-qlWJH4t9G28ES5L4fGqw79IzqNBAoPIWExkiQT47tun_EgpwAXsDfuQxI6V1_PQ15FMUtRlXAMnEAopm0WgP1dCSkiJVA5zX_kI1PwUqUVsdzPtDg60s2G0OFIIAVq-XhT4C_JjvmNHfeakE8mHhs9zOMxQ-KL2kjbEoB5Ua-s9vPt8uPga7uKzvrCLoRLU8PQ9HNiq0hxUdb_MKZFqycaIYOe-zqqgBRdFtifR9Ud1GQmiZ_8yaRBfPdhl-Ip0JbsYUHWRzEwz1JMp5547D41fY5CC21gtpUIfFTQZPFTHQzAHxtlTvHT3bpcfMpYaZE1j1ysrahfsQ9elgeE",\n'+
                    '"purposes" : [\n'+
                        buildPurposesSchema(selectedPurposes) +
                    '],\n'+
                    '"test": false\n'+         
               '}');
    }
}