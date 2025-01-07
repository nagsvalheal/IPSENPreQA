/**
* @description Handler for J_Copay__c trigger.
* @author Arkadii
* @date 10/29/20
*/
public with sharing class J_CopayTriggerHandler {
    /**
* @description Checks for existing active copay records to prevent overlaps.
* @param mCopays Map of Copay records from the trigger.
*/
    public void checkOnExistingActiveCopay(Map<Id, J_Copay__c> mCopays) {
        try {
            if (mCopays == null || mCopays.isEmpty()) {
                return; // No copays to process
            }
            
            // Get active copays from the provided map
            Map<Id, J_Copay__c> activeCopays = getActiveCopaysFromList(mCopays.values());
            if (activeCopays.isEmpty()) {
                return; // No active copays found
            }
            
            // Get active charitables for the active copays
            Map<Id, J_Charitable__c> existingCharitables = getActiveCharitables(activeCopays.values());
            
            // Get existing active copays excluding the current ones
            Map<Id, J_Copay__c> existingCopays = getActiveCopayExisted(
                new List<Id>(mCopays.keySet()), 
                new List<Id>(activeCopays.keySet())
            );
            
            // Validate copays against existing records
            validateCopays(mCopays.values(), existingCopays, existingCharitables);
        } catch (Exception e) {
            // Log the error for debugging purposes
            GenericLogger.exceptionLog('J_CopayTriggerHandler', 'checkOnExistingActiveCopay', e);
        }
    }
    
    /**
* @description Fetches active charitable records based on enrollee IDs.
* @param copays List of active copay records.
* @return Map of enrollee ID to J_Charitable__c records.
*/
    @TestVisible
    private Map<Id, J_Charitable__c> getActiveCharitables(List<J_Copay__c> copays) {
        List<Id> enrolleeIds = new List<Id>();
        for (J_Copay__c copay : copays) {
            if (copay.Care_Program_Enrollee__c != null) {
                enrolleeIds.add(copay.Care_Program_Enrollee__c);
            }
        }
        
        if (enrolleeIds.isEmpty()) {
            return new Map<Id, J_Charitable__c>();
        }
        
        // Utilize the utility method for querying J_Charitable__c records
        String sObjectType = 'J_Charitable__c';
        String fields = 'Id, Care_Program_Enrollee__c, J_CharitableStatus__c, J_Enrollment_Start_Date__c, J_Enrollment_End_Date__c';
        String conditions = 'J_CharitableStatus__c = \'' + J_ObjectUtils.CHARITABLE_CHARITABLE_STATUS_PL_ACTIVE + '\' ' +
            'AND Care_Program_Enrollee__c IN (\'' + String.join((enrolleeIds), '\', \'') + '\')';
        
        List<J_Charitable__c> charitables = (List<J_Charitable__c>) COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
        
        // Null check for charitables before constructing the map
        if (charitables == null || charitables.isEmpty()) {
            return new Map<Id, J_Charitable__c>();
        }
        
        return new Map<Id, J_Charitable__c>(charitables);
    }    
    /**
* @description Validates copays for overlapping dates with existing records.
* @param copays List of copays to validate.
* @param existingCopays Map of existing active copays.
* @param existingCharitables Map of existing active charitables.
*/
    @TestVisible
    private void validateCopays(
        List<J_Copay__c> copays, 
        Map<Id, J_Copay__c> existingCopays, 
        Map<Id, J_Charitable__c> existingCharitables
    ) {
        for (J_Copay__c copay : copays) {
            validateOverlapWithCopays(copay, existingCopays);
            validateOverlapWithCharitables(copay, existingCharitables);
        }
    }
    
    /**
* @description Validates overlap with existing copay records.
* @param copay Copay record to validate.
* @param existingCopays Map of existing active copays.
*/
    @TestVisible
    private void validateOverlapWithCopays(J_Copay__c copay, Map<Id, J_Copay__c> existingCopays) {
        // Create DateRange object for the copay record
        DateRange copayRange = new DateRange(copay.J_EnrollmentStartDate__c, copay.J_EnrollmentEndDate__c);
        
        for (J_Copay__c existingCopay : existingCopays.values()) {
            // Create DateRange object for each existing copay
            DateRange existingCopayRange = new DateRange(existingCopay.J_EnrollmentStartDate__c, existingCopay.J_EnrollmentEndDate__c);
            
            // Check for overlap using the refactored isOverlapping method
            if (isOverlapping(copayRange, existingCopayRange)) {
                copay.addError(Label.J_ThereIsExistingActiveCopayRecordOnTheseDates);
            }
        }
    }
    
    /**
* @description Validates overlap with existing charitable records.
* @param copay Copay record to validate.
* @param existingCharitables Map of existing active charitables.
*/
    @TestVisible
    private void validateOverlapWithCharitables(J_Copay__c copay, Map<Id, J_Charitable__c> existingCharitables) {
        // Create DateRange object for the copay record
        DateRange copayRange = new DateRange(copay.J_EnrollmentStartDate__c, copay.J_EnrollmentEndDate__c);
        
        for (J_Charitable__c charitable : existingCharitables.values()) {
            // Create DateRange object for each existing charitable record
            DateRange charitableRange = new DateRange(charitable.J_Enrollment_Start_Date__c, charitable.J_Enrollment_End_Date__c);
            
            // Check for overlap using the refactored isOverlapping method
            if (isOverlapping(copayRange, charitableRange)) {
                copay.addError(Label.J_ThereIsExistingActivePAPTPAPRecordOnTheseDates);
            }
        }
    }
    /**
* @description Wrapper Class for Dateranges.
*/
    public class DateRange {
        public Date start;
        public Date enddate;
        
        /**
* @description Constructor to initialize start and end dates.
* @param start Start date of the range.
* @param enddate End date of the range.
*/
        public DateRange(Date start, Date enddate) {
            this.start = start;
            this.enddate = enddate;
        }
    }
    /**
* @description Checks if two date ranges overlap.
* @param range1 First date range to check.
* @param range2 Second date range to check.
* @return True if the date ranges overlap, false otherwise.
*/
    @TestVisible
    private Boolean isOverlapping(DateRange range1, DateRange range2) {
        return (range1.start <= range2.enddate && range1.enddate >= range2.start);
    }
    private Map<Id, J_Copay__c> getActiveCopaysFromList(List<J_Copay__c> lcopays) {
        Map<Id, J_Copay__c> mCopays = new Map<Id, J_Copay__c>();
        for (J_Copay__c copay : lcopays) {
            if (String.isNotBlank(copay.Care_Program_Enrollee__c) && String.isNotBlank(copay.J_CurrentCopayStatus__c)
                && copay.J_CurrentCopayStatus__c.equalsIgnoreCase(J_ObjectUtils.COPAY_CURRENT_COPAY_STATUS_PL_ACTIVE)
               ) {
                   mCopays.put(copay.Care_Program_Enrollee__c, copay);
               }
        }
        
        return mCopays;
    }
    
    /**
*  @description Retrieves active copay records from the database, excluding the ones provided in the input list.
* The records are filtered based on their current copay status being "Active" and their association with the provided Care Program Enrollee IDs.
* 
* @param lCopayIdsFromTrigger List of Copay record IDs to exclude from the query.
* @param enrolleeIds List of Care Program Enrollee record IDs to filter the copay records.
* @return A map of active Copay records keyed by Care_Program_Enrollee__c ID.
*/
    public Map<Id, J_Copay__c> getActiveCopayExisted(List<Id> lCopayIdsFromTrigger, List<Id> enrolleeIds) {
        Map<Id, J_Copay__c> mCopays = new Map<Id, J_Copay__c>();
        
        try {
            // Define the SOQL query parameters
            String sObjectType = 'J_Copay__c';
            String fields = 'Id, Care_Program_Enrollee__c, J_CurrentCopayStatus__c, J_EnrollmentStartDate__c, J_EnrollmentEndDate__c';
            String conditions = 'J_CurrentCopayStatus__c = \'' + J_ObjectUtils.COPAY_CURRENT_COPAY_STATUS_PL_ACTIVE + '\' ' +
                'AND Id NOT IN (\'' + String.join((lCopayIdsFromTrigger), '\', \'') + '\') ' +
                'AND Care_Program_Enrollee__c IN (\'' + String.join((enrolleeIds), '\', \'') + '\')';
            
            // Execute the query using the utility method
            List<J_Copay__c> lcopaysExisted = (List<J_Copay__c>) COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            
            // Populate the map if records are found
            if (!lcopaysExisted.isEmpty()) {
                mCopays = getActiveCopaysFromList(lcopaysExisted);
            }
        } catch (Exception e) {
            // Log the error for debugging purposes
            GenericLogger.exceptionLog('J_CopayTriggerHandler', 'getActiveCopayExisted', e);
        }
        
        return mCopays;
    }
    
    
}