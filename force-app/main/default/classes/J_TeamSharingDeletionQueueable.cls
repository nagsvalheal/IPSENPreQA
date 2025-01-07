public class J_TeamSharingDeletionQueueable implements Queueable {
    private Map<String, String> careProgTeamMemDetails;
    private String criteriaName;

    // Constructor to initialize required parameters
    public J_TeamSharingDeletionQueueable(Map<String, String> careProgTeamMemDetails, String criteriaName) {
        this.careProgTeamMemDetails = careProgTeamMemDetails;
        this.criteriaName = criteriaName;
    }

    // Execute method where the logic for processing resides
    public void execute(QueueableContext context) {
        try {
            // Use the helper method to process the share records
           TeamSharing_HelperClass.deleteShareRecords(this.careProgTeamMemDetails, this.criteriaName);
            
            
        } catch (Exception ex) {
            System.debug('Error in TeamSharingQueueable execute method: ' + ex.getMessage());
            // Optional: Log the error to a custom object or notify admins
        }
    }
}