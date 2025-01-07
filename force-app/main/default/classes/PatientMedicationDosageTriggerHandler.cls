/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 12-16-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class PatientMedicationDosageTriggerHandler {

  /**
 * @description This method updates parent record IDs in the `PatientMedicationDosage` list by:
 * 1. Extracting treatment plan IDs from the provided `dosageList`.
 * 2. Fetching a map of treatment plans and their corresponding patient IDs.
 * 3. Updating patient IDs in the dosages.
 * 4. Fetching medication statements for the patients.
 * 5. Creating new `MedicationStatement` records if necessary.
 * 6. Inserting the new medication statements.
 * 7. Updating the `ParentRecordId` in the `PatientMedicationDosage` records with the newly created medication statements.
 *
 * @param dosageList A list of `PatientMedicationDosage` records representing the medication dosages
 *                   that need to be processed and updated with corresponding patient and medication information.
 *
 * @throws None (Currently, there is no explicit exception handling in the method).
 * 
 * @note The method makes several sub-method calls to handle different parts of the processing, such as 
 *       fetching treatment plans, creating medication statements, and inserting records.
 */

  public void updateParentRecordId(List<PatientMedicationDosage> dosageList) {
    try{
    Set<Id> treatmentPlanIDs = extractTreatmentPlanIds(dosageList);
    Map<Id, Id> treatMentPatientMap = fetchTreatmentPlanPatientMap(
      treatmentPlanIDs
    );

    Set<Id> patientIds = updatePatientIdsInDosages(
      dosageList,
      treatMentPatientMap
    );
    Map<Id, Id> patientMedicationMap = fetchMedicationStatements(patientIds);

    Id medicationCodeId = fetchMedicationCodeId('Sohonos');
    List<MedicationStatement> newMedicationStatements = createMedicationStatements(
      dosageList,
      patientMedicationMap,
      medicationCodeId
    );

    if (!newMedicationStatements.isEmpty()) {
      Database.SaveResult[] insertResults = COM_DatabaseOperationsUtility.insertOperation(
        newMedicationStatements,
        'MedicationStatementInsert',
        false
      );

      updatePatientMedicationMap(patientMedicationMap, newMedicationStatements);
    }

    updateParentRecordIds(dosageList, patientMedicationMap);
  }catch (Exception ex) {
    // Log any exceptions for debugging
    GenericLogger.exceptionLog(
        'PatientMedicationDosageHandler',
        'updateParentRecordId',
        ex
    );
}
  }
/**
 * @description Extracts a set of treatment plan IDs from the provided `PatientMedicationDosage` list.
 * 
 * @param dosageList A list of `PatientMedicationDosage` records.
 * @return A set of unique treatment plan IDs.
 */
  private Set<Id> extractTreatmentPlanIds(
    List<PatientMedicationDosage> dosageList
  ) {
    Set<Id> treatmentPlanIDs = new Set<Id>();
    for (PatientMedicationDosage tr : dosageList) {
      treatmentPlanIDs.add(tr.Treatment_Plan__c);
    }
    return treatmentPlanIDs;
  }
/**
 * @description Fetches a map of treatment plan IDs to patient IDs, based on the provided set of treatment plan IDs.
 * 
 * @param treatmentPlanIDs A set of treatment plan IDs to fetch patient information for.
 * @return A map where the key is the treatment plan ID, and the value is the corresponding patient ID (AccountId).
 */
  private Map<Id, Id> fetchTreatmentPlanPatientMap(Set<Id> treatmentPlanIDs) {
    Map<Id, Id> treatMentPatientMap = new Map<Id, Id>();
    if (!treatmentPlanIDs.isEmpty()) {
        List<String> treatmentPlanIdList = new List<String>();
        for (Id planId : treatmentPlanIDs) {
            treatmentPlanIdList.add(planId);
        }
        List<SObject> cases = COM_QueryUtility.executeQuery(
            'Case',
            'Id, Care_Program_Enrollee__c, Care_Program_Enrollee__r.AccountId',
            'Id IN (\'' + String.join(treatmentPlanIdList, '\',\'') + '\')',
            true
        );
      for (SObject record : cases) {
        Case c = (Case) record;
        treatMentPatientMap.put(c.Id, c.Care_Program_Enrollee__r.AccountId);
      }
    }
    return treatMentPatientMap;
  }
/**
 * @description Updates the patient IDs in the `PatientMedicationDosage` list based on the treatment plan-patient map.
 * 
 * @param dosageList A list of `PatientMedicationDosage` records to update.
 * @param treatMentPatientMap A map of treatment plan IDs to patient IDs.
 * @return A set of patient IDs that were updated in the dosage records.
 */
  private Set<Id> updatePatientIdsInDosages(
    List<PatientMedicationDosage> dosageList,
    Map<Id, Id> treatMentPatientMap
  ) {
    Set<Id> patientIds = new Set<Id>();
    for (PatientMedicationDosage dl : dosageList) {
      Id patientId = treatMentPatientMap.get(dl.Treatment_Plan__c);
      patientIds.add(patientId);
      if (dl.Patient__c == null) {
        dl.Patient__c = patientId;
      }
    }
    return patientIds;
  }
/**
 * @description Fetches existing medication statements for the provided patient IDs.
 * 
 * @param patientIds A set of patient IDs for which medication statements need to be fetched.
 * @return A map where the key is the patient ID and the value is the corresponding medication statement ID.
 */
  private Map<Id, Id> fetchMedicationStatements(Set<Id> patientIds) {
    Map<Id, Id> patientMedicationMap = new Map<Id, Id>();
    if (!patientIds.isEmpty()) {
        List<String> patientIdList = new List<String>();
        for (Id patientId : patientIds) {
            patientIdList.add(String.valueOf(patientId)); // Convert Id to String
        }
        List<SObject> medicationStatements = COM_QueryUtility.executeQuery(
            'MedicationStatement',
            'Id, PatientId',
            'PatientId IN (\'' + String.join(patientIdList, '\',\'') + '\')',
            false
        );
        system.debug('medicationStatements'+medicationStatements);
      for (SObject record : medicationStatements) {
        MedicationStatement ms = (MedicationStatement) record;
        patientMedicationMap.put(ms.PatientId, ms.Id);
          system.debug('patientMedicationMap'+ patientMedicationMap);
      }
    }
    return patientMedicationMap;
  }
  
/**
 * @description Fetches the ID of the medication code with the specified name.
 * 
 * @param codeName The name of the medication code.
 * @return The ID of the medication code if found, or null if no matching code exists.
 */
  private Id fetchMedicationCodeId(String codeName) {
    List<SObject> codeSetBundles = COM_QueryUtility.executeQuery(
      'CodeSetBundle',
      'Id',
      'Name = \'' + codeName + '\'',
      false
    );
     
    
    if (!codeSetBundles.isEmpty()) {
      return ((CodeSetBundle) codeSetBundles[0]).Id;
     
    }
    return null;
  }
/**
 * @description Creates new `MedicationStatement` records for the provided `PatientMedicationDosage` list
 *              if no existing medication statement exists for a patient.
 * 
 * @param dosageList A list of `PatientMedicationDosage` records.
 * @param patientMedicationMap A map of patient IDs to their corresponding medication statement IDs.
 * @param medicationCodeId The ID of the medication code to be used for the new medication statements.
 * @return A list of new `MedicationStatement` records to be inserted.
 */
  private List<MedicationStatement> createMedicationStatements(
    List<PatientMedicationDosage> dosageList,
    Map<Id, Id> patientMedicationMap,
    Id medicationCodeId
  ) {
    List<MedicationStatement> msStatementList = new List<MedicationStatement>();
    if (medicationCodeId != null) {
      for (PatientMedicationDosage pat : dosageList) {
        if (!patientMedicationMap.containsKey(pat.Patient__c)) {
          MedicationStatement ms = new MedicationStatement();
          ms.PatientId = pat.Patient__c;
          ms.Status = 'Active';
          ms.MedicationCodeId = medicationCodeId;
          msStatementList.add(ms);
        }
      }
    }
    return msStatementList;
  }
/**
 * @description Updates the patient medication map by adding newly created medication statements.
 * 
 * @param patientMedicationMap A map of patient IDs to medication statement IDs.
 * @param newStatements A list of new `MedicationStatement` records to be added to the map.
 */
  private void updatePatientMedicationMap(
    Map<Id, Id> patientMedicationMap,
    List<MedicationStatement> newStatements
  ) {
    for (MedicationStatement ms : newStatements) {
      patientMedicationMap.put(ms.PatientId, ms.Id);
    }
  }
/**
 * @description Updates the `ParentRecordId` field of the `PatientMedicationDosage` records based on the patient medication map.
 * 
 * @param dosageList A list of `PatientMedicationDosage` records to update.
 * @param patientMedicationMap A map of patient IDs to medication statement IDs to use for updating the `ParentRecordId`.
 */
private void updateParentRecordIds(
  List<PatientMedicationDosage> dosageList,
  Map<Id, Id> patientMedicationMap
) {
  try {
      for (PatientMedicationDosage pm : dosageList) {
          if (patientMedicationMap.containsKey(pm.Patient__c)) {
              pm.ParentRecordId = patientMedicationMap.get(pm.Patient__c);
          }
      }
  } catch (Exception ex) {
      // Log the exception for debugging or monitoring
      GenericLogger.debugLog('Error occurred in updateParentRecordIds: ' + ex.getMessage());
  }
}
  
}