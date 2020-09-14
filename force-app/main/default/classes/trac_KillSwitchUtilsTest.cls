@IsTest
private class trac_KillSwitchUtilsTest {

    @IsTest
    private static void isDisabled_NonExistingMethod() {
        Test.startTest();

        Boolean result = trac_KillSwitchUtils.isDisabled('example');

        Test.stopTest();

        System.assertNotEquals(null, result, 'The isDisabled method should never return null.');
        System.assertEquals(false, result, 'The isDisabled method should return false for non-existing methods.');
    }

    @IsTest
    private static void isDisabled() {
        Test.startTest();

        Boolean result = trac_KillSwitchUtils.isDisabled('trac_AccountSyncOwner_queueAccountOwnerChange');

        Test.stopTest();

        System.assertNotEquals(null, result, 'The isDisabled method should never return null.');
        System.assertEquals(false, result, 'The isDisabled method should return false for the queueAccountOwnerChange method.');
    }
}