
//
//customize the attachToCase event
//
Coveo.$$(window).on('attachToCase', function(evt, arg) {
    let objectType = arg.result.raw.objecttype;

    //set the Reference Case lookup on the AttachedResult record to the Salesforce Id of the Case.
    if (objectType === 'Case') {
        arg.dataToAttach.customs["Reference_Case__c"] = arg.result.raw.sfid;
    }
});







