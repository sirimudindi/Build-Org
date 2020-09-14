/**
 * Created by akong on 1/8/2019.
 */

@IsTest
private class trac_BatchUtilsTest {
    @IsTest
    static void testIsBatchRunning() {
        System.assert(!trac_BatchUtils.isBatchRunning(trac_Constants.QOC_BATCH_CLASS_DOMAIN_CONTACT_OWNER), 'Batch job should not be running right now.');
    }
}