@isTest
public class TestPAshouldActiveForPAevent {

     @isTest static void TestPAstatus()
	{
        Account acc = new Account();
        acc.FirstName = 'Test Active';
        acc.LastName = 'Te';
        acc.Patient_Status__pc = 'Inactive';
        acc.PersonBirthdate = Date.newInstance(1996, 06, 09);
        insert acc;
        
        Event ev = new Event();
        ev.WhatId = acc.Id;
        ev.Subject = 'Patient Ambassador Event';
        ev.StartDateTime = system.today();
        ev.EndDateTime = system.today()+1;
       
        
        test.startTest();
            try
			{
				insert  ev;       
			}
			catch(Exception ex)
			{
				Boolean expectedExceptionThrown =  ex.getMessage().contains('Cannot create this event. Patient ambassador status is not Active.') ? true : false;
				System.AssertEquals(expectedExceptionThrown, true);                
			}
        test.stopTest();
    }
    
}