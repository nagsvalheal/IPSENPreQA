public class J_TeamSharingQueueable implements Queueable {
    private Set<Id> teamMemberIds;
    private String criteriaName;

    // Constructor to initialize required parameters
    public J_TeamSharingQueueable(Set<Id> teamMemberIds, String criteriaName) {
        this.teamMemberIds = teamMemberIds;
        this.criteriaName = criteriaName;
    }

    // Execute method where the logic for processing resides
    public void execute(QueueableContext context) {
        try {
            // Use the helper method to process the share records
            TeamSharing_HelperClass.createShareRecords(teamMemberIds, criteriaName);
        } catch (Exception ex) {
            System.debug('Error in TeamSharingQueueable execute method: ' + ex.getMessage());
            // Optional: Log the error to a custom object or notify admins
        }
    }
}