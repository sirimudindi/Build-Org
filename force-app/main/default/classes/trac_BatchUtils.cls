/**
 * Utility methods for supporting batch Apex
 * @author  Alex Kong, Traction on Demand
 * @date    2019-01-08
 */
public with sharing class trac_BatchUtils {

    /**
     * checks if batch is in a running (or soon to be running) state
     * @return Boolean, true if running, otherwise false
     */
    public static Boolean isBatchRunning(String apexClassName) {
        Boolean retval = false;
        List<String> statuses = new List<String>{
                trac_Constants.ASYNC_STATUS_HOLDING,
                trac_Constants.ASYNC_STATUS_QUEUED,
                trac_Constants.ASYNC_STATUS_PREPARING,
                trac_Constants.ASYNC_STATUS_PROCESSING
        };
        if (String.isNotBlank(apexClassName)) {
            List<AsyncApexJob> jobs = [
                    SELECT Id
                    FROM AsyncApexJob
                    WHERE ApexClass.Name = :apexClassName
                    AND Status IN :statuses
                    LIMIT 1
            ];
            if (!jobs.isEmpty()) {
                retval = true;
            }
        }
        return retval;
    }
}