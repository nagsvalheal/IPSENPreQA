/**********************************************************************************************
 * @Author:
 * @description This class is used to delete the team share records.
 ***********************************************************************************************/
public class TeamSharing_DeleteBatch implements Queueable {
    
    private string strObjName;
    private list<sobject> teamObjects = new list<sobject>();
    /**********************************************************************************************
    * @Author:
    * @description This method is used to delete the team share records.
    @param sObjectList it contains sobject in a list
    @param objName object name
***********************************************************************************************/
    public TeamSharing_DeleteBatch(list<object> sObjectList, string objName) {
        this.strObjName = objName;
        for(object teamObj:sObjectList){
            this.teamObjects.add((sObject)teamObj);
        }
    }
    /**********************************************************************************************
    * @Author:       
    * @description  This method is used to get the Team Share records to delete.
    @param context  QueueableContext    
***********************************************************************************************/

    public void execute(QueueableContext context) {
        // Prepare for optimized processing
        // List<sObject> lstsDeleteObjects = new List<sObject>();
        // Schema.SObjectType objType = Schema.getGlobalDescribe().get(strObjName); // Fetch schema describe once
        // if (objType == null) {
        //     throw new DmlException('Invalid object type: ' + strObjName);
        // }

        // // Process input objects
        // for (Object obj1 : lstsObjects) {
        //     try {
        //         Map<String, Object> teamRecord = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(obj1));
        //         String recId = (String) teamRecord.get('Id');

        //         // Create and prepare the sObject for deletion
        //         sObject sObj = objType.newSObject();
        //         sObj.put('Id', recId);
        //         lstsDeleteObjects.add(sObj);
        //     } catch (Exception e) {
        //         // Log or handle exceptions for individual records if necessary
        //         GenericLogger.exceptionLog('TeamSharing_DeleteBatch', 'execute', e);
        //     }
        // }

        // // Perform bulk delete operation
        // if (!lstsDeleteObjects.isEmpty()) {
        //     COM_DatabaseOperationsUtility.deleteOperationForBatch(lstsDeleteObjects, false, true);
        // }
        try {
            // COM_DatabaseOperationsUtility.insertOperation(teamObjects, J_CreateTeamSharingQueueable.class.toString(), false); 
            if(!teamObjects.isEmpty())
            {
                COM_DatabaseOperationsUtility.deleteOperationForBatch(this.teamObjects, false, true);  
                System.debug('permission deleted');
            }            
        } catch (Exception ex) {
            System.debug('Error in TeamSharingQueueable execute method: ' + ex.getMessage());
            // Optional: Log the error to a custom object or notify admins
        }
    }
}