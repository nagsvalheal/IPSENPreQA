@IsTest
public class GenericMetadataProviderTest {
	@IsTest static void getInstanceTest(){
        Test.startTest();
        GenericMetadataProvider instance1 = GenericMetadataProvider.getInstance();
        Assert.areNotEqual(null, instance1, 'Expected instance1 to be initialized');
        Test.stopTest();
    }
    
    @IsTest static void getRecordFromGeneralSettingTest(){
        Test.startTest();
        Integer result = GenericMetadataProvider.getRecordFromGeneralSetting();
        Assert.areNotEqual(null, result, 'Expected result to not be null');
        Test.stopTest();
    }
}