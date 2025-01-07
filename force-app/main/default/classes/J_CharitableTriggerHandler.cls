/**
*   @author         Arkadii Sychov
*   @date           10/29/20
*   @description    IPSC-265. Check on existence of active record for Charitable
**/
public with sharing class J_CharitableTriggerHandler {
    /**
     * @description     Checks if there are any existing active charitable records for the provided charitable records.
     *                  It validates if the enrollment dates overlap with existing records and adds an error if applicable.
     * @param mcharitables A map of J_Charitable__c records (Key: Id of J_Charitable__c, Value: J_Charitable__c record)
     */
   
    public void checkOnExistingActiveCharitable(Map<Id, J_Charitable__c> mcharitables) {
        Map<Id, J_Charitable__c> mpatientIdTocharitablesActiveFromTrigger = getActiveCharitablesFromList(mcharitables.values());

        if (!mpatientIdTocharitablesActiveFromTrigger.isEmpty()) {
            J_CopayTriggerHandler copayTriggerHandler = new J_CopayTriggerHandler();
            Map<Id, J_Charitable__c> mcharitablesActiveExisted = getActiveCharitablesExisted(
                new List<Id>(mcharitables.keySet()), 
                new List<Id>(mpatientIdTocharitablesActiveFromTrigger.keySet())
            );
            Map<Id, J_Copay__c> accountIdsByCopay = copayTriggerHandler.getActiveCopayExisted(
                new List<Id>(), 
                new List<Id>(mpatientIdTocharitablesActiveFromTrigger.keySet())
            );
            validateCharitablesAgainstExistingRecords(mcharitables.values(), mcharitablesActiveExisted, accountIdsByCopay);
        }
    }

    /**
     * @description     Validates the provided charitable records against existing records and copays.
     *                  It checks for overlaps in enrollment dates and adds errors if applicable.
     * @param charitables A list of J_Charitable__c records to validate.
     * @param existingCharitables A map of existing active charitable records.
     * @param existingCopays A map of existing copay records.
     */
    private void validateCharitablesAgainstExistingRecords(
        List<J_Charitable__c> charitables,
        Map<Id, J_Charitable__c> existingCharitables,
        Map<Id, J_Copay__c> existingCopays
    ) {
        for (J_Charitable__c charitable : charitables) {
            if (!existingCharitables.isEmpty()) {
                checkOverlapWithCharitables(charitable, existingCharitables.values());
            }
            if (!existingCopays.isEmpty()) {
                checkOverlapWithCopays(charitable, existingCopays.values());
            }
        }
    }

    /**
     * @description     A helper class to represent a date range with start and end dates.
     */
    public class DateRange {
        public Date startDate;
        public Date endDate;
    
        /**
         * @description     Constructor to initialize the DateRange object with start and end dates.
         * @param startDate The start date of the range.
         * @param endDate The end date of the range.
         */
        public DateRange(Date startDate, Date endDate) {
            this.startDate = startDate;
            this.endDate = endDate;
        }
    }
    
    /**
     * @description     Checks for overlap between the provided charitable record and existing charitable records.
     *                  If an overlap is found, an error is added to the charitable record.
     * @param charitable The J_Charitable__c record to check for overlap.
     * @param existingCharitables A list of existing active charitable records.
     */
    public void checkOverlapWithCharitables(J_Charitable__c charitable, List<J_Charitable__c> existingCharitables) {
        for (J_Charitable__c existingCharitable : existingCharitables) {
            DateRange charitableRange = new DateRange(charitable.J_Enrollment_Start_Date__c, charitable.J_Enrollment_End_Date__c);
            DateRange existingRange = new DateRange(existingCharitable.J_Enrollment_Start_Date__c, existingCharitable.J_Enrollment_End_Date__c);
            
            if (isDateRangeOverlap(charitableRange, existingRange)) {
                charitable.addError(Label.J_ThereIsExistingActivePAPTPAPRecordOnTheseDates);
            }
        }
    }
    
    /**
     * @description     Checks for overlap between the provided charitable record and existing copay records.
     *                  If an overlap is found, an error is added to the charitable record.
     * @param charitable The J_Charitable__c record to check for overlap.
     * @param existingCopays A list of existing copay records.
     */
    private void checkOverlapWithCopays(J_Charitable__c charitable, List<J_Copay__c> existingCopays) {
        for (J_Copay__c existingCopay : existingCopays) {
            DateRange charitableRange = new DateRange(charitable.J_Enrollment_Start_Date__c, charitable.J_Enrollment_End_Date__c);
            DateRange copayRange = new DateRange(existingCopay.J_EnrollmentStartDate__c, existingCopay.J_EnrollmentEndDate__c);
            
            if (isDateRangeOverlap(charitableRange, copayRange)) {
                charitable.addError(Label.J_ThereIsExistingActiveCopayRecordOnTheseDates);
            }
        }
    }
    
    /**
     * @description     Checks if there is an overlap between two date ranges.
     * @param range1 The first DateRange object.
     * @param range2 The second DateRange object.
     * @return        Boolean Returns true if the date ranges overlap, false otherwise.
     */
    private Boolean isDateRangeOverlap(DateRange range1, DateRange range2) {
        return (range1.startDate >= range2.startDate && range1.startDate <= range2.endDate) || 
               (range1.endDate >= range2.startDate && range1.endDate <= range2.endDate) || 
               (range1.startDate <= range2.startDate && range1.endDate >= range2.endDate);
    }
    
    /**
     * @description     Updates the end date of each charitable record to be 12 months after the start date.
     * @param charitables A list of J_Charitable__c records to update.
     */
    public void updateEndDate(List<J_Charitable__c> charitables){
        for(J_Charitable__c charitable : charitables){
            if(charitable.J_Enrollment_Start_Date__c != null){
                charitable.J_Enrollment_End_Date__c = charitable.J_Enrollment_Start_Date__c.addMonths(12);
            }
        }
    }

    /**
     * @description     Retrieves active charitable records from a given list of charitable records.
     *                  Only records with a specific status and program type are considered.
     * @param lcharitables A list of J_Charitable__c records.
     * @return            A map of active charitable records, where the key is the Care_Program_Enrollee__c Id
     *                    and the value is the J_Charitable__c record.
     */
    private Map<Id, J_Charitable__c> getActiveCharitablesFromList(List<J_Charitable__c> lcharitables) {
        Map<Id, J_Charitable__c> mcharitables = new Map<Id, J_Charitable__c>();
        for (J_Charitable__c charitable : lcharitables) {
            if (String.isNotBlank(charitable.J_CharitableStatus__c) && String.isNotBlank(charitable.J_CharitableProgramType__c)
                    && String.isNotBlank(charitable.Care_Program_Enrollee__c)
                    && charitable.J_CharitableStatus__c.equalsIgnoreCase(J_ObjectUtils.CHARITABLE_CHARITABLE_STATUS_PL_ACTIVE)
                    && (charitable.J_CharitableProgramType__c.equalsIgnoreCase(J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP)
                    || charitable.J_CharitableProgramType__c.equalsIgnoreCase(J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_TPAP))
                    ) {
                mcharitables.put(charitable.Care_Program_Enrollee__c, charitable);
            }
        }

        return mcharitables;
    }

    /**
     * @description     Retrieves existing active charitable records from the database, excluding records that are already
     *                  being processed in the current trigger.
     * @param lcharitableIdsFromTrigger A list of J_Charitable__c record IDs from the current trigger.
     * @param laccountIds A list of Care_Program_Enrollee__c IDs to filter the records.
     * @return            A map of existing active charitable records (Key: Care_Program_Enrollee__c, Value: J_Charitable__c record).
     */
    public Map<Id, J_Charitable__c> getActiveCharitablesExisted(List<Id> lcharitableIdsFromTrigger, List<Id> laccountIds) {
        List<J_Charitable__c> lcharitableExisted = [
                SELECT Id, Care_Program_Enrollee__c, J_CharitableStatus__c, J_CharitableProgramType__c, J_Enrollment_Start_Date__c, J_Enrollment_End_Date__c
                FROM J_Charitable__c
                WHERE J_CharitableStatus__c = :J_ObjectUtils.CHARITABLE_CHARITABLE_STATUS_PL_ACTIVE
                AND (J_CharitableProgramType__c = :J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_PAP
                OR J_CharitableProgramType__c = :J_ObjectUtils.CHARITABLE_CHARITABLE_PROGRAM_TYPE_PL_TPAP)
                AND Id NOT IN :lcharitableIdsFromTrigger
                AND Care_Program_Enrollee__c IN :laccountIds WITH SECURITY_ENFORCED
        ];
        
        Map<Id, J_Charitable__c> mcharitables = new Map<Id, J_Charitable__c>();
        if (!lcharitableExisted.isEmpty()) {
            mcharitables = getActiveCharitablesFromList(lcharitableExisted);
        }

        return mcharitables;
    }
}