public class J_CreateTeamSharingQueueable implements Queueable {
    private list<sobject> teamObjects = new list<sobject>();

    // Constructor to initialize required parameters
    public J_CreateTeamSharingQueueable(list<object> teamObjects) {
        for(object teamObj:teamObjects){
            this.teamObjects.add((sObject)teamObj);
        }
        
    }

    // Execute method where the logic for processing resides
    public void execute(QueueableContext context) {
        try {
            COM_DatabaseOperationsUtility.insertOperation(teamObjects, J_CreateTeamSharingQueueable.class.toString(), false);                    
        } catch (Exception ex) {
            System.debug('Error in TeamSharingQueueable execute method: ' + ex.getMessage());
            // Optional: Log the error to a custom object or notify admins
        }
    }
}