@isTest
public class J_ConvertCountry_State_ValuesTest {
    
    @isTest   
    Public static void testCountryState()
    {     
        J_ConvertCountry_State_Values.Request r = new J_ConvertCountry_State_Values.Request ();
        r.iCountry = 'US';
        r.iState ='AL';
        
        J_ConvertCountry_State_Values.Request r1 = new J_ConvertCountry_State_Values.Request ();
        r1.iCountry = 'United States';
        r1.iState ='Texas';
        
        J_ConvertCountry_State_Values.Request r2 = new J_ConvertCountry_State_Values.Request ();
        r2.iCountry = 'abcd';
        r2.iState ='abcd';
        
        Test.startTest();
        J_ConvertCountry_State_Values.getCountryState(new List<J_ConvertCountry_State_Values.Request>{r});
        J_ConvertCountry_State_Values.getCountryState(new List<J_ConvertCountry_State_Values.Request>{r1});
        J_ConvertCountry_State_Values.getCountryState(new List<J_ConvertCountry_State_Values.Request>{r2});
        J_ConvertCountry_State_Values.getState ('AL');
        J_ConvertCountry_State_Values.getState ('Texas');
        J_ConvertCountry_State_Values.getState ('abcd');
        Test.stopTest();
    }
}