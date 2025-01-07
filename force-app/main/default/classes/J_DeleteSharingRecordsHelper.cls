/**
 * @description Helper class for deleting sharing records based on specified criteria.
 */
public class J_DeleteSharingRecordsHelper {
    /**
     * @description Retrieves the list of sharing records to delete based on the provided object and parent records.
     *
     * @param teamObjects list of team objects retrieved.
     * @param objNameShare The API name of the sharing object (e.g., AccountShare).
     * @return A list of SObjects representing the sharing records to delete.
     */
    public static list<sObject> getSharingRecordsToDelete(
        list<object> teamObjects,
        string objNameShare
    ) {
        list<sObject> lstsDeleteObjects = new List<sObject>();

        if (!teamObjects.isEmpty()) {
            lstsDeleteObjects = getLstsDeleteObjects(teamObjects, objNameShare);
        }

        return lstsDeleteObjects;
    }

    /**
     * @description Converts a list of team objects into a list of SObjects for deletion.
     *
     * @param teamObjects The list of team objects retrieved from SOQL.
     * @param objNameShare The API name of the sharing object.
     * @return A list of SObjects ready for deletion.
     */
    @TestVisible
    private static list<sObject> getLstsDeleteObjects(
        list<object> teamObjects,
        String objNameShare
    ) {
        list<sObject> lstsDeleteObject = new List<sObject>();
        sObject sObj;
        set<string> lstShareRecId = new Set<string>();
        for (object obj1 : teamObjects) {
            lstShareRecId = getLstShareRecId(obj1);

            if (lstShareRecId != null && lstShareRecId.size() > 0) {
                for (string recShareId : lstShareRecId) {
                    sObj = Schema.getGlobalDescribe().get(objNameShare).newSObject();
                    sObj.put('Id', recShareId);
                    lstsDeleteObject.add(sObj);
                }
            }
        }

        return lstsDeleteObject;
    }
	@TestVisible
    private static set<string> getLstShareRecId(object obj1) {
        set<string> lstShareRecIds = new Set<string>();
        String jsonStr = JSON.serialize(obj1);
        JSONParser parser = JSON.createParser(jsonStr);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                string fieldName = parser.getText();
                parser.nextToken();
                if (fieldName == 'Id') {
                    lstShareRecIds.add(parser.getText());
                }
            }
        }
        return lstShareRecIds;
    }
}