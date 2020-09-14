/**
 * @author Lizhu li, Traction on Demand
 * @date 2020-02-23
 */
@IsTest
public with sharing class Trac_TriggerHandlerBaseTest {
    static trac_TriggerHandlerBase tb = new trac_TriggerHandlerBase();

    @isTest
    static void handleBeforeInsert() {
        Exception resultException;

        Test.startTest();
        try {
            tb.handleBeforeInsert();
        } catch(Exception e) {
            resultException = e;
        }
        Test.stopTest();

        System.assertEquals(null, resultException, 'There shouldn’t be an Exception in this scenario');
    }

    @isTest
    static void handleBeforeUpdate() {
        Exception resultException;

        Test.startTest();
        try {
            tb.handleBeforeUpdate();
        } catch(Exception e) {
            resultException = e;
        }
        Test.stopTest();

        System.assertEquals(null, resultException, 'There shouldn’t be an Exception in this scenario');
    }

    @isTest
    static void handleAfterInsert() {
        Exception resultException;

        Test.startTest();
        try {
            tb.handleAfterInsert();
        } catch(Exception e) {
            resultException = e;
        }
        Test.stopTest();

        System.assertEquals(null, resultException, 'There shouldn’t be an Exception in this scenario');
    }

    @isTest
    static void handleAfterUpdate() {
        Exception resultException;

        Test.startTest();
        try {
            tb.handleAfterUpdate();
        } catch(Exception e) {
            resultException = e;
        }
        Test.stopTest();

        System.assertEquals(null, resultException, 'There shouldn’t be an Exception in this scenario');
    }
}