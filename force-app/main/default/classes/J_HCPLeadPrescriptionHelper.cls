public without sharing  class J_HCPLeadPrescriptionHelper {
     public static List<Lead_Prescription_Information__c> fetchPrescriptions(Id leadId) {
        return [SELECT Id, Lead__c, Dosage__c, Dosage_Unit__c, Sig__c, Frequency__c, No_of_Refills__c, Care_Program_Product__c,
                        Quantity__c, Directions__c, Total_Daily_Quantity__c, Ancillary_Supplies__c, Dosage_Type__c
                 FROM Lead_Prescription_Information__c WHERE Lead__c = :leadId WITH SECURITY_ENFORCED];
    }

    public static void processPrescriptions(List<Lead_Prescription_Information__c> lstPrescription, Id careProgramEnrolleeId, Id caseId, Id accountId, Id enrolleeHcpId) {
        List<CareProgramEnrolleeProduct> lstcpep = new List<CareProgramEnrolleeProduct>();
        Map<Id, Id> mapCPEP = new Map<Id, Id>();

        // Create Care Program Enrollee Products
        for (Lead_Prescription_Information__c lp : lstPrescription) {
            CareProgramEnrolleeProduct cpep = new CareProgramEnrolleeProduct(
                CareProgramEnrolleeId = careProgramEnrolleeId,
                CareProgramProductId = lp.Care_Program_Product__c,
                Status = 'Active'
            );
            lstcpep.add(cpep);
        }

        if (!lstcpep.isEmpty()) {
           // insert lstcpep;
           List<SObject> cpepRecordsToInsert = new List<SObject>();
            cpepRecordsToInsert.addAll(lstcpep);
           Database.SaveResult[] cpepInsertResults = COM_DatabaseOperationsUtility.insertOperation(
            cpepRecordsToInsert,
            'processPrescriptions',
            true
        );

            // for (CareProgramEnrolleeProduct cpep : lstcpep) {
            //     mapCPEP.put(cpep.CareProgramProductId, cpep.Id);
            // }
            for (Integer i = 0; i < cpepInsertResults.size(); i++) {
                if (cpepInsertResults[i].isSuccess()) {
                    CareProgramEnrolleeProduct cpep = lstcpep[i];
                    mapCPEP.put(cpep.CareProgramProductId, cpep.Id);
                } else {
                    System.debug('Failed to insert CareProgramEnrolleeProduct ' + cpepInsertResults[i].getErrors()[0].getMessage());
                }
            }
        }

        // Create Patient Medication Dosages
        List<PatientMedicationDosage> pMD = new List<PatientMedicationDosage>();

        for (Lead_Prescription_Information__c lp : lstPrescription) {
            PatientMedicationDosage dos = new PatientMedicationDosage();
            dos.Patient__c = accountId;
            dos.Treatment_Plan__c = caseId;
            dos.Patients_Current_Prescribed_Dose__c = lp.Dosage__c;
            dos.Unit_Daily_Dose__c = (lp.Dosage_Unit__c != null) ? convertData(lp.Dosage_Unit__c) : null;
            dos.Sig__c = lp.Sig__c;
            dos.Day_Supply__c = lp.Frequency__c;
            dos.DosageDefinitionType = lp.Dosage_Type__c;
            dos.No_of_Refills__c = lp.No_of_Refills__c;
            dos.Care_Program_Enrollee_Name__c = careProgramEnrolleeId;
            dos.Care_Program_Enrollee_Product__c = mapCPEP.get(lp.Care_Program_Product__c);
           // dos.Enrollee_HCP__c = enrolleeHcpId;
            dos.Current_Dose_Record__c = true;
            dos.J_Quantity__c = lp.Quantity__c;
            dos.J_Directions__c = lp.Directions__c;
            dos.J_TotalDailyQuantity__c = lp.Total_Daily_Quantity__c;
            dos.J_Ancillary_Supplies__c = lp.Ancillary_Supplies__c;
            pMD.add(dos);
        }

        if (!pMD.isEmpty() && Schema.sObjectType.PatientMedicationDosage.fields.Treatment_Plan__c.isCreateable()) {
           // insert pMD;
           List<SObject> pMDRecordsToInsert = new List<SObject>();
            pMDRecordsToInsert.addAll(pMD);
           Database.SaveResult[] pMDInsertResults =COM_DatabaseOperationsUtility.insertOperation(
            pMDRecordsToInsert,
            'processPrescriptions',
            true
        );
        }
    }

    private static String convertData(String dosageUnit) {
        if (dosageUnit == 'mg' || dosageUnit.contains('Milligram')) {
            return 'Milligram (mg)';
        }
        if (dosageUnit == 'mcg' || dosageUnit.contains('Microgram')) {
            return 'Microgram (mcg)';
        }
        if (dosageUnit == 'ml' || dosageUnit.contains('Milliliter')) {
            return 'Milliliter (ml)';
        }
        if (dosageUnit.contains('Units')) {
            return 'Units (U)';
        }
        if (dosageUnit.contains('Caps')) {
            return 'Capsules';
        }
        return dosageUnit;
    }

}