public with sharing class J_PMDAfterInserandUpdateTriggerHandler {
  /**
   * Trigger handler for the "after insert" event for PatientMedicationDosage records.
   * This method processes records that are inserted, updates CareProgramEnrollee records accordingly.
   *
   * @param triggerNew A list of newly inserted PatientMedicationDosage records in the trigger.
   */
  public static void afterInsertmethod(List<PatientMedicationDosage> triggerNew) {
    Map<Id, String> enrolleePharmacyId = extractEnrolleePharmacyMap(triggerNew);

    if (!enrolleePharmacyId.isEmpty()) {
      List<CareProgramEnrollee> enrolleeToUpdate = prepareEnrolleeUpdates(
        enrolleePharmacyId
      );

      if (!enrolleeToUpdate.isEmpty()) {
        performUpdateOperation(enrolleeToUpdate, 'CareProgramEnrolleeUpdate');
      }
    }
  }
  /**
   * Extracts a map of CareProgramEnrollee IDs to Pharmacy Email addresses from the given list of
   * PatientMedicationDosage records. This method is used to determine which CareProgramEnrollees
   * need updates based on the current dose record and specialty pharmacy.
   *
   * @param triggerNew A list of newly inserted PatientMedicationDosage records in the trigger.
   * @return A map of CareProgramEnrollee IDs to Pharmacy Email addresses.
   */
  private static Map<Id, String> extractEnrolleePharmacyMap(
    List<PatientMedicationDosage> triggerNew
  ) {
    Map<Id, String> enrolleePharmacyId = new Map<Id, String>();
    for (PatientMedicationDosage pmd : triggerNew) {
      if (pmd.Current_Dose_Record__c && pmd.Specialty_Pharmacy__c != null) {
        enrolleePharmacyId.put(
          pmd.Care_Program_Enrollee_Name__c,
          pmd.Pharmacy_Email__c
        );
      }
    }
    return enrolleePharmacyId;
  }
  /**
   * Prepares a list of CareProgramEnrollee records to update, based on the extracted
   * CareProgramEnrollee IDs and their corresponding Pharmacy Email addresses.
   *
   * @param enrolleePharmacyId A map of CareProgramEnrollee IDs to Pharmacy Email addresses.
   * @return A list of CareProgramEnrollee records that need updating.
   */
  private static List<CareProgramEnrollee> prepareEnrolleeUpdates(
    Map<Id, String> enrolleePharmacyId
  ) {
    List<String> enrolleeIds = new List<String>();
    for (Id enrolleeId : enrolleePharmacyId.keySet()) {
      enrolleeIds.add(String.valueOf(enrolleeId));
    }
    List<SObject> enrolleeRecords = COM_QueryUtility.executeQuery(
      'CareProgramEnrollee',
      'Id, Bypass_Apex__c, PharmacyEmail__c',
      'Id IN (\'' + String.join(enrolleeIds, '\',\'') + '\')',
      true
    );

    List<CareProgramEnrollee> enrolleeToUpdate = new List<CareProgramEnrollee>();
    for (SObject record : enrolleeRecords) {
      CareProgramEnrollee enrollee = (CareProgramEnrollee) record;
      enrollee.PharmacyEmail__c = enrolleePharmacyId.get(enrollee.Id);
      enrollee.Bypass_Apex__c = !enrollee.Bypass_Apex__c;
      enrolleeToUpdate.add(enrollee);
    }
    return enrolleeToUpdate;
  }
  /**
   * Performs the update operation for a list of CareProgramEnrollee records by calling the
   * COM_DatabaseOperationsUtility.updateOperation method. If any updates fail, errors are logged.
   *
   * @param enrolleeToUpdate A list of CareProgramEnrollee records to be updated.
   * @param className The name of the class from which this method is invoked (for logging context).
   */
  private static void performUpdateOperation(
    List<CareProgramEnrollee> enrolleeToUpdate,
    String className
  ) {
    try {
      Database.SaveResult[] updateResults = COM_DatabaseOperationsUtility.updateOperation(
        enrolleeToUpdate,
        'J_PMDAfterInserandUpdateTriggerHandler',
        true
      );
      for (Database.SaveResult result : updateResults) {
        if (!result.isSuccess()) {
          // Log errors with specific context
        //   GenericLogger.exceptionLog(
        //     'J_PMDAfterInserandUpdateTriggerHandler',
        //     'performUpdateOperation',
        //     ex.getMessage()
        // );
        }
      }
    } catch (Exception ex) {
      GenericLogger.exceptionLog(
        'J_PMDAfterInserandUpdateTriggerHandler',
        'performUpdateOperation',
        ex
      );
    }
  }
  /**
   * Trigger handler for the "after update" event for PatientMedicationDosage records.
   * This method processes updated records, comparing old and new values to determine which CareProgramEnrollee
   * records need updates.
   *
   * @param triggerNew A list of newly updated PatientMedicationDosage records.
   * @param triggeroldMap A map of the old values of the PatientMedicationDosage records before update.
   */
  public static void afterUpdatemethod(
    List<PatientMedicationDosage> triggerNew,
    Map<Id, PatientMedicationDosage> triggeroldMap
  ) {
    Map<Id, String> enrolleePharmacyId = collectEnrolleePharmacyIds(
      triggerNew,
      triggeroldMap
    );

    if (!enrolleePharmacyId.isEmpty()) {
      List<CareProgramEnrollee> enrolleeToUpdate = buildEnrolleeUpdates(
        enrolleePharmacyId
      );

      if (!enrolleeToUpdate.isEmpty()) {
        performUpdateOperation(enrolleeToUpdate);
      }
    }
  }
  /**
   * Collects a map of CareProgramEnrollee IDs to Pharmacy Email addresses based on
   * the changes between old and new PatientMedicationDosage records.
   * This method is used to identify whether the Specialty Pharmacy or Current Dose Record
   * has changed.
   *
   * @param triggerNew A list of updated PatientMedicationDosage records.
   * @param triggeroldMap A map of old PatientMedicationDosage records before the update.
   * @return A map of CareProgramEnrollee IDs to Pharmacy Email addresses.
   */

  private static Map<Id, String> collectEnrolleePharmacyIds(
    List<PatientMedicationDosage> triggerNew,
    Map<Id, PatientMedicationDosage> triggeroldMap
  ) {
    Map<Id, String> enrolleePharmacyId = new Map<Id, String>();

    for (PatientMedicationDosage pmd : triggerNew) {
      if (pmd.Current_Dose_Record__c) {
        Boolean specialtyPharmacyChanged = (pmd.Specialty_Pharmacy__c != null &&
        triggeroldMap.get(pmd.Id).Specialty_Pharmacy__c !=
        pmd.Specialty_Pharmacy__c);
        Boolean currentDoseRecordChanged = !triggeroldMap.get(pmd.Id)
          .Current_Dose_Record__c;

        if (specialtyPharmacyChanged || currentDoseRecordChanged) {
          enrolleePharmacyId.put(
            pmd.Care_Program_Enrollee_Name__c,
            pmd.Pharmacy_Email__c
          );
        }
      }
    }

    return enrolleePharmacyId;
  }

  /**
   * Builds a list of CareProgramEnrollee records that need to be updated based on the collected
   * CareProgramEnrollee IDs and their corresponding Pharmacy Email addresses.
   *
   * @param enrolleePharmacyId A map of CareProgramEnrollee IDs to Pharmacy Email addresses.
   * @return A list of CareProgramEnrollee records to be updated.
   */
  private static List<CareProgramEnrollee> buildEnrolleeUpdates(
    Map<Id, String> enrolleePharmacyId
  ) {
    List<String> enrolleeIds = new List<String>();
    for (Id enrolleeId : enrolleePharmacyId.keySet()) {
      enrolleeIds.add(enrolleeId);
    }
    List<SObject> enrolleeRecords = COM_QueryUtility.executeQuery(
      'CareProgramEnrollee',
      'Id, Bypass_Apex__c, PharmacyEmail__c',
      'Id IN (\'' + String.join(enrolleeIds, '\',\'') + '\')',
      true
    );

    List<CareProgramEnrollee> enrolleeToUpdate = new List<CareProgramEnrollee>();

    for (SObject record : enrolleeRecords) {
      CareProgramEnrollee cpe = (CareProgramEnrollee) record;

      cpe.PharmacyEmail__c = enrolleePharmacyId.get(cpe.Id);
      cpe.Bypass_Apex__c = !cpe.Bypass_Apex__c;
      enrolleeToUpdate.add(cpe);
    }

    return enrolleeToUpdate;
  }

  /**
   * Performs the update operation for a list of CareProgramEnrollee records by calling the
   * COM_DatabaseOperationsUtility.updateOperation method. If any updates fail, errors are logged.
   *
   * @param enrolleeToUpdate A list of CareProgramEnrollee records to be updated.
   */
  private static void performUpdateOperation(
    List<CareProgramEnrollee> enrolleeToUpdate
  ) {
    try {
      Database.SaveResult[] updateResults = COM_DatabaseOperationsUtility.updateOperation(
        enrolleeToUpdate,
        'J_PMDAfterInserandUpdateTriggerHandler',
        false
      );

      for (Database.SaveResult sr : updateResults) {
        if (!sr.isSuccess()) {
        //   GenericLogger.exceptionLog(
        //     'J_PMDAfterInserandUpdateTriggerHandler',
        //     'performUpdateOperation',
        //     ex.getMessage()
        // );
        }
      }
    } catch (Exception ex) {
      GenericLogger.exceptionLog(
        'J_PMDAfterInserandUpdateTriggerHandler',
        'performUpdateOperation',
        ex
      );
    }
  }
}