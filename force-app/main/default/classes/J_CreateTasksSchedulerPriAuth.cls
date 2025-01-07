public class J_CreateTasksSchedulerPriAuth {

    public void execute(SchedulableContext sc) {
        // Call your J_CreateTasksForPriorAuthorization class here
        J_CreateTasksForPriorAuthorization.priorAuthorizationExpiring();
    }
}