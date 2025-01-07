/**
 * @description Batch class to process records from the J_SP_Inbound__c object and create or update 
 *              related J_Order__c and J_SP_Status_Update__c records.
 */
global class JourneySPInboundBatchClass implements Database.Batchable<sObject> {
    
    /**
     * @description Queries J_SP_Inbound__c records with a status of 'Created' for batch processing.
     * @param bc The batchable context.
     * @return A QueryLocator for processing records.
     */
    global Database.QueryLocator start(Database.BatchableContext bc) {
        // collect the batches of records or objects to be passed to executee
         
        String query = 'SELECT Id, Name, J_Claim_CoPay_Amount__c, J_Claim_CoPay_Applied__c, J_Claim_CoPay_Asst_Amt__c, J_Claim_CoPay_Elg__c,Enrollee_ID__c,'
+' J_Claim_Co_Ins_Amt__c, J_Claim_Co_Ins_percent__c, J_Claim_OOP_Met__c, J_Claim_PPayer_Paid_Amt__c,'
 +' J_Claim_Pt_Paid_Amt__c, J_Claim_Type__c, J_HCP_FirstName__c, J_HCP_LastName__c, J_HCP_Location__c, J_HCP_NPI__c, '
+' J_HUB_Patient_ID__c, J_INS_PP_BIN__c, J_INS_PP_Group_ID__c, J_INS_PP_ID__c, J_INS_PP_Name__c, J_INS_PP_PBM__c,'
 +' J_INS_PP_PCN__c, J_INS_PP_Plan_Name__c, J_INS_PP_Type__c, J_INS_SecP_BIN__c, J_INS_SecP_Group_ID__c, J_INS_SecP_ID__c,'
 +' J_INS_SecP_Name__c, J_INS_SecP_PCN__c, J_INS_SecP_Plan_Name__c, J_INS_SecP_State__c, J_INS_SecP_Type__c, '
+' J_Import_Status__c,J_Journey_Patient_Id__c, J_PA_Appeal_Date__c, J_PA_Date__c, J_PA_Exp_Date__c, J_PA_Req__c,'
 +' J_Product_Name__c, J_Program_Name__c, J_RX_DATE__c, J_RX_Day_Supply__c, J_RX_Dosage_Type__c, J_RX_Fill__c,'
 +' J_RX_NDC__c, J_RX_Num__c, J_RX_Qty__c, J_RX_Refil_Date__c, J_RX_Refil_Remaining__c, J_RX_Ship_Date__c,'
 +' J_RX_Shipment_ID__c, J_RX_Shipment_Type__c, J_RX_UOM__c, J_Record_Entry_Date__c, J_Record_type__c, J_SP_Loc_NCPDP__c,'
+' J_SP_Name__c, J_SP_Patient_Id__c, J_SP_Unique_Id__c, J_SR__c, J_Status_Date__c, J_Status__c, J_Sub_Status__c,'
 +' J_Concurrent_Txt__c, J_Error_Information__c, J_Patient_Gender__c, J_Patient_State__c, J_Prescriber_Address_1__c,'
 +' J_Prescriber_Address_2__c, J_Prescriber_City__c, J_Prescriber_DEA__c, J_Prescriber_Fax__c, J_Prescriber_Phone__c,'
 +' J_Prescriber_State__c, J_Prescriber_Zip__c, J_Primary_Dx_Code__c, J_Secondary_Dx_Code__c, J_SP_City__c, J_SP_Resta_Flg__c'
 +' FROM J_SP_Inbound__c where J_Import_Status__c=\'Created\'';
        return Database.getQueryLocator(query);
    }

/**
     * @description Processes batches of J_SP_Inbound__c records, creating or updating associated J_Order__c 
     *              and J_SP_Status_Update__c records, and updating import status.
     * @param bc The batchable context.
     * @param jSPList List of J_SP_Inbound__c records to process.
     */
    global void execute(Database.BatchableContext bc, List<J_SP_Inbound__c> jSPList) {
        // Initialize collections
        Set<String> setShipmentRecords = new Set<String>();
        Set<String> setEnrolleeID = new Set<String>();
        Map<String, Id> mapPatientIDPatientMap = new Map<String, Id>();
        Map<String, J_Order__c> mapOrderNameOrder = new Map<String, J_Order__c>();
        List<J_Order__c> insertJOrder = new List<J_Order__c>();
        List<J_SP_Status_Update__c> insertDAStatus = new List<J_SP_Status_Update__c>();
        Set<Id> accPatientId = new Set<Id>();
        List<J_SP_Inbound__c> updateStatus = new List<J_SP_Inbound__c>();
        Set<Id> stagingStatusIDSet = new Set<Id>();
        Set<Id> setInboundDataForUpdate = new Set<Id>();
        //String description = 'There is an update in the ';
        
        // Process inbound records
        processInboundRecords(jSPList, setEnrolleeID, setShipmentRecords);
        
        // Fetch CareProgramEnrollee records
        List<CareProgramEnrollee> cpEnrollee = getCareProgramEnrollee(setEnrolleeID);
        
        // Populate mapPatientIDPatientMap
        populatePatientMap(cpEnrollee, mapPatientIDPatientMap);
        
        // Process each record based on type (Shipment or Status)
        processRecords(jSPList, mapPatientIDPatientMap, mapOrderNameOrder, insertJOrder, insertDAStatus, updateStatus, accPatientId, stagingStatusIDSet);
        
        // Upsert J_Order records
        upsertJOrderRecords(insertJOrder, stagingStatusIDSet, updateStatus, setInboundDataForUpdate);
        
        // Insert Status Updates
        insertStatusUpdates(insertDAStatus, stagingStatusIDSet, updateStatus);
        
        // Final updates
        finalUpdates(updateStatus, insertJOrder);
    }
    /**
     * @description Populates Enrollee ID and Shipment records from J_SP_Inbound__c records.
     * @param jSPList List of J_SP_Inbound__c records to process.
     * @param setEnrolleeID Set to store unique Enrollee IDs.
     * @param setShipmentRecords Set to store unique Shipment IDs.
     */
    private void processInboundRecords(List<J_SP_Inbound__c> jSPList, Set<String> setEnrolleeID, Set<String> setShipmentRecords) {
        for (J_SP_Inbound__c jsp : jSPList) {
            setEnrolleeID.add(jsp.Enrollee_ID__c);
            if (jsp.J_Record_type__c == 'Shipment') {
                setShipmentRecords.add(jsp.J_SP_Unique_Id__c);
            }
        }
    }

    private List<CareProgramEnrollee> getCareProgramEnrollee(Set<String> setEnrolleeID) {
        String conditionIds = '(\'' + String.join(new List<String>(setEnrolleeID), '\', \'') + '\')';
        String sObjectType = 'CareProgramEnrollee';
        String fields = 'id, AccountId, Enrollee_ID__c, CC_Owner__c';
        String conditions = 'Enrollee_ID__c IN' + conditionIds;

        List<CareProgramEnrollee> newCareProgramEnrollees = COM_QueryUtility.executeQuery(
            sObjectType,
            fields,
            conditions,
            true // Assuming true for read-only query
        );
        return newCareProgramEnrollees;
    }

    private void populatePatientMap(List<CareProgramEnrollee> cpEnrollee, Map<String, Id> mapPatientIDPatientMap) {
        for (CareProgramEnrollee cpe : cpEnrollee) {
            mapPatientIDPatientMap.put(cpe.Enrollee_ID__c, cpe.Id);
        }
    }

    private void processRecords(List<J_SP_Inbound__c> jSPList, 
    Map<String, Id> mapPatientIDPatientMap, 
    Map<String, J_Order__c> mapOrderNameOrder,
    List<J_Order__c> insertJOrder, 
    List<J_SP_Status_Update__c> insertDAStatus, 
    List<J_SP_Inbound__c> updateStatus, 
    Set<Id> accPatientId, 
    Set<Id> stagingStatusIDSet) {
    
    for (J_SP_Inbound__c jsp : jSPList) {
        if (mapPatientIDPatientMap.get(jsp.Enrollee_ID__c) != null) {
            // Process Shipment Records
            if (jsp.J_Record_type__c == 'Shipment') {
                createShipmentRecord(jsp, mapPatientIDPatientMap, mapOrderNameOrder, insertJOrder, insertDAStatus);
            } 
            // Process Status Records
            else if (jsp.J_Record_type__c == 'Status') {
                insertDAStatus.add(populateStatusFields(jsp, mapPatientIDPatientMap));
            }

            // Add processed Enrollee ID for reference
            accPatientId.add(mapPatientIDPatientMap.get(jsp.Enrollee_ID__c));

            // Set import status to "Success" for successfully processed records
            jsp.J_Import_Status__c = 'Success'; 
        } else {
            // Handle invalid enrollee scenarios
            handleInvalidEnrollee(jsp, updateStatus, stagingStatusIDSet);
        }

        // Add the record to the update status list for final updates
        updateStatus.add(jsp);
    }
}


    private void createShipmentRecord(J_SP_Inbound__c jsp, Map<String, Id> mapPatientIDPatientMap, Map<String, J_Order__c> mapOrderNameOrder,
                                      List<J_Order__c> insertJOrder, List<J_SP_Status_Update__c> insertDAStatus) {
        J_Order__c jOrder = mapOrderNameOrder.containsKey(jsp.J_SP_Unique_Id__c) ? mapOrderNameOrder.get(jsp.J_SP_Unique_Id__c) : new J_Order__c();
        jOrder.Unique_Record_ID__c = jsp.J_SP_Unique_Id__c;
        jOrder.Record_Entry_Date__c = jsp.J_Record_Entry_Date__c;
        jOrder.RX_DATE__c = jsp.J_RX_DATE__c;
        jOrder.J_SP_Order_Number__c = jsp.J_RX_Num__C;
        jOrder.SP_Name__c = jsp.J_SP_Name__c;
        jOrder.RX_UOM__c = jsp.J_RX_UOM__c;
        jOrder.J_Refills_Remaining__c = jsp.J_RX_Refil_Remaining__c;
        jOrder.J_NDC_Number__c = jsp.J_RX_NDC__c;
        jOrder.J_Quantity__c = jsp.J_RX_Day_Supply__c;
        setUnitDose(jsp, jOrder);
        jOrder.J_Total_Daily_Dose_in_mg__c = String.valueOf(jsp.J_RX_Qty__c);
        jOrder.J_Order_Ship_Date__c = jsp.J_RX_Ship_Date__c;
        jOrder.J_Dosage_Type__c = jsp.J_RX_Dosage_Type__c;
        jOrder.J_SP_Refill_Date__c = jsp.J_RX_Refil_Date__c;
        jOrder.J_SP_Shipment_Type__c = jsp.J_RX_Shipment_Type__c;
        jOrder.Care_Program_Enrollee__c = mapPatientIDPatientMap.get(jsp.Enrollee_ID__c);
        jOrder.J_DA_Inbound_Record_Id__c = jsp.Id;

        insertJOrder.add(jOrder);
        insertDAStatus.add(populateStatusFields(jsp, mapPatientIDPatientMap));
    }

    private void setUnitDose(J_SP_Inbound__c jsp, J_Order__c jOrder) {
        if (jsp.J_RX_UOM__c != null) {
            if (jsp.J_RX_UOM__c.equalsIgnoreCase('mg')) {
                jOrder.Unit_Starting_Dose__c = 'Milligram (mg)';
                jOrder.Unit_Daily_Dose__c = 'Milligram (mg)';
            } else if (jsp.J_RX_UOM__c.equalsIgnoreCase('ml')) {
                jOrder.Unit_Starting_Dose__c = 'Milliliter (ml)';
                jOrder.Unit_Daily_Dose__c = 'Milliliter (ml)';
            } else if (jsp.J_RX_UOM__c.equalsIgnoreCase('mcg')) {
                jOrder.Unit_Starting_Dose__c = 'Microgram (mcg)';
                jOrder.Unit_Daily_Dose__c = 'Microgram (mcg)';
            } else {
                jOrder.Unit_Starting_Dose__c = jsp.J_RX_UOM__c;
                jOrder.Unit_Daily_Dose__c = jsp.J_RX_UOM__c;
            }
        }
    }

    private void handleInvalidEnrollee(J_SP_Inbound__c jsp, List<J_SP_Inbound__c> updateStatus, Set<Id> stagingStatusIDSet) {
        jsp.J_Import_Status__c = 'Failure'; // Set import status for invalid records
        updateStatus.add(jsp);
        stagingStatusIDSet.add(jsp.Id);
    }

    private void upsertJOrderRecords(List<J_Order__c> insertJOrder, Set<Id> stagingStatusIDSet, List<J_SP_Inbound__c> updateStatus, Set<Id> setInboundDataForUpdate) {
        if (!insertJOrder.isEmpty()) {
            COM_DatabaseOperationsUtility.updateOperation(insertJOrder, 'JourneySPInboundBatchClass', true);
        }
    }

    private void insertStatusUpdates(List<J_SP_Status_Update__c> insertDAStatus, Set<Id> stagingStatusIDSet, List<J_SP_Inbound__c> updateStatus) {
        if (!insertDAStatus.isEmpty()) {
            COM_DatabaseOperationsUtility.insertOperationForBatch(insertDAStatus, false, true);
        }
    }

    private void finalUpdates(List<J_SP_Inbound__c> updateStatus, List<J_Order__c> insertJOrder) {
        if (!updateStatus.isEmpty()) {
            COM_DatabaseOperationsUtility.updateOperation(updateStatus, 'JourneySPInboundBatchClass', true);
        }
    }

   
    @TestVisible
    private static J_SP_Status_Update__c populateStatusFields(
    J_SP_Inbound__c jsp, 
    Map<String, Id> mapPatientIDPatientMap
) {
    J_SP_Status_Update__c spStatus = new J_SP_Status_Update__c();
    
    spStatus.Record_Entry_Date__c = jsp.J_Record_Entry_Date__C;
    spStatus.J_Case_Number__c = jsp.J_SR__c;
    spStatus.J_Program__c = jsp.J_Program_Name__c;
    spStatus.J_Status_Date__c = jsp.J_Status_Date__c;
    spStatus.J_SP_Status__c = jsp.J_Status__c;
    spStatus.J_SubStatus__c = jsp.J_Sub_Status__c;
    
    // Assign Patient ID
    assignPatientIds(spStatus, jsp, mapPatientIDPatientMap);

    // Assign Prescriber and HCP details
    assignPrescriberDetails(spStatus, jsp);

    // Assign Insurance Details
    assignInsuranceDetails(spStatus, jsp);

    // Assign Copay Details
    assignCopayDetails(spStatus, jsp);

    // Assign Miscellaneous Fields
    assignMiscellaneousFields(spStatus, jsp);

    return spStatus;
}

private static void assignPatientIds(
    J_SP_Status_Update__c spStatus, 
    J_SP_Inbound__c jsp, 
    Map<String, Id> mapPatientIDPatientMap
) {
    spStatus.J_SP_Journey_Patient_Id__c = mapPatientIDPatientMap.get(jsp.Enrollee_ID__c) == null 
        ? jsp.Enrollee_ID__c 
        : mapPatientIDPatientMap.get(jsp.Enrollee_ID__c);

    spStatus.Care_Program_Enrollee__c = mapPatientIDPatientMap.get(jsp.Enrollee_ID__c) == null 
        ? jsp.Enrollee_ID__c 
        : mapPatientIDPatientMap.get(jsp.Enrollee_ID__c);

    spStatus.J_SP_Patient_ID__c = jsp.J_SP_Patient_Id__C;
    spStatus.J_SP_Hub_Patient_Id__c = jsp.J_HUB_Patient_ID__c;
}

private static void assignPrescriberDetails(
    J_SP_Status_Update__c spStatus, 
    J_SP_Inbound__c jsp
) {
    spStatus.J_SP_HCP_Last_Name__c = jsp.J_HCP_LastName__c;
    spStatus.J_SP_HCP_First_Name__c = jsp.J_HCP_FirstName__c;
    spStatus.J_Practice_Location__c = jsp.J_HCP_Location__c;
    spStatus.J_Prescriber_Address_1__c = jsp.J_Prescriber_Address_1__c;
    spStatus.J_Prescriber_Address_2__c = jsp.J_Prescriber_Address_2__c;
    spStatus.J_Prescriber_City__c = jsp.J_Prescriber_City__c;
    spStatus.J_Prescriber_State__c = jsp.J_Prescriber_State__c;
    spStatus.J_Prescriber_Zip__c = jsp.J_Prescriber_Zip__c;
    spStatus.J_Prescriber_Phone__c = jsp.J_Prescriber_Phone__c;
    spStatus.J_Prescriber_Fax__c = jsp.J_Prescriber_Fax__c;
    spStatus.J_SP_HCP_NPI__c = jsp.J_HCP_NPI__c;
    spStatus.J_Prescriber_DEA__c = jsp.J_Prescriber_DEA__c;
}

private static void assignInsuranceDetails(
    J_SP_Status_Update__c spStatus, 
    J_SP_Inbound__c jsp
) {
    spStatus.J_SP_PP_Insurance_Type__c = jsp.J_INS_PP_Type__c;
    spStatus.J_SP_PP_GroupNumber__c = jsp.J_INS_PP_Group_ID__c;
    spStatus.J_SP_PP_Payer_Id__c = jsp.J_INS_PP_ID__c;
    spStatus.J_SP_RxBin_Number__c = jsp.J_INS_PP_BIN__c;
    spStatus.J_Primary_Payer_PCN__c = jsp.J_INS_PP_PCN__c;
    spStatus.J_SP_INS_PP_Name__c = jsp.J_INS_PP_Name__c;
    spStatus.J_SP_PP_GroupPlanNumber__c = jsp.J_INS_PP_Plan_Name__c;
    spStatus.J_SP_PP_PBM_Policy_Numb__c = jsp.J_INS_PP_PBM__c;
    spStatus.J_SP_Sec_Insurance_Type__c = jsp.J_INS_SecP_Type__c;
    spStatus.J_SP_Sec_Payer_Id__c = jsp.J_INS_SecP_ID__c;
    spStatus.J_Secondary_Payer_BIN__c = jsp.J_INS_SecP_BIN__c;
    spStatus.J_Secondary_Payer_PCN__c = jsp.J_INS_SecP_PCN__c;
    spStatus.J_SP_INS_Sec_Name__c = jsp.J_INS_SecP_Name__c;
    spStatus.J_SP_INS_Sec_State__c = jsp.J_INS_SecP_State__c;
}

private static void assignCopayDetails(
    J_SP_Status_Update__c spStatus, 
    J_SP_Inbound__c jsp
) {
    spStatus.J_Co_Insurance_Percent__c = jsp.J_Claim_Co_Ins_percent__c;
    spStatus.J_Co_Insurance_Amt__c = jsp.J_Claim_Co_Ins_Amt__c;
    spStatus.J_Co_Pay_Amount__c = jsp.J_Claim_CoPay_Amount__c;
    spStatus.J_CopayAssistAmount__c = jsp.J_Claim_CoPay_Asst_Amt__c;
    spStatus.J_Total_Patient_payment__c = jsp.J_Claim_Pt_Paid_Amt__c;

    spStatus.J_Co_pay_card_eligible__c = (jsp.J_Claim_CoPay_Elg__c != null 
        && (jsp.J_Claim_CoPay_Elg__c.toUpperCase() == 'Y'));

    spStatus.J_Co_Pay_Card_Applied__c = (jsp.J_Claim_CoPay_Applied__c != null 
        && (jsp.J_Claim_CoPay_Applied__c.toUpperCase() == 'Y'));

    spStatus.J_pat_OOPMet__c = (jsp.J_Claim_OOP_Met__c != null 
        && (jsp.J_Claim_OOP_Met__c.toUpperCase() == 'Y'));
}

private static void assignMiscellaneousFields(
    J_SP_Status_Update__c spStatus, 
    J_SP_Inbound__c jsp
) {
    spStatus.J_SP_Resta_Flg__c = (jsp.J_SP_Resta_Flg__c != null 
        && (jsp.J_SP_Resta_Flg__c.toUpperCase() == 'Y'));
    spStatus.J_Unique_Record_ID__c = jsp.J_SP_Unique_Id__c;
    spStatus.J_DA_Inbound_Record_Id__c = jsp.Id;
}

   
  /**
     *@description Final cleanup after batch processing completes.
     *
     * @param bc The batch context instance provided by the system.
     */   
    global void finish(Database.BatchableContext bc) {
        GenericLogger.debugLog('***JourneySPInboundBatchClass processed successfully***');
    }
}