/**
 * @author 
 * @date 
 * @description IPSC-265.
 */
public with sharing class J_CoverageBenefitTriggerHandler {

    /**
     * @description Uploads a Coverage Benefit PDF for the specified CoverageBenefit IDs.
     * @param lstCovBenefitIds List of CoverageBenefit record IDs to generate and upload PDFs for.
     */
    public static void uploadCoverageBenefitPDF(List<Id> lstCovBenefitIds) {
        try {
            GenericLogger.debugLog('--lstCovBenefitIds---' + lstCovBenefitIds);

            // Build query parameters
            String sObjectType = 'CoverageBenefit';
            String fields = 'Id, Name, MemberId, Care_Program_Enrollee__r.Account.FirstName, '
                            + 'Care_Program_Enrollee__r.Account.LastName';
            String conditions = 'Id IN (\'' + String.join((lstCovBenefitIds), '\', \'') + '\')';

            // Fetch CoverageBenefit records using the utility method
            List<CoverageBenefit> lstCoverBenefitRecs = (List<CoverageBenefit>) COM_QueryUtility.executeQuery(
                sObjectType, fields, conditions, true
            );

            GenericLogger.debugLog('--lstCoverBenefitRecs---' + lstCoverBenefitRecs);

            if (lstCoverBenefitRecs != null && !lstCoverBenefitRecs.isEmpty()) {
                for (CoverageBenefit cb : lstCoverBenefitRecs) {
                    Id parentId = cb.Id;

                    PageReference pdf = Page.CoverageBenefitPDF;
                    pdf.getParameters().put('id', cb.Id);
                    Blob body = Test.isRunningTest() ? Blob.valueOf('Test Content') : pdf.getContent();
                    String base64 = EncodingUtil.base64Encode(body);

                    String filename;
                    String patientName = (cb.Care_Program_Enrollee__r.Account.FirstName != null)
                        ? cb.Care_Program_Enrollee__r.Account.FirstName + ' ' + cb.Care_Program_Enrollee__r.Account.LastName
                        : cb.Name;
                    filename = patientName + ' - Benefit Investigation Summary.PDF';

                    GenericLogger.debugLog('--filename----' + filename);
                    J_FileUpload_Custom.uploadFile(base64, filename, parentId);
                }
            }
        } catch (Exception e) {
            GenericLogger.exceptionLog(e);
           
        }
    }

    /**
     * @description Handles the after-insert trigger event for CoverageBenefit records.
     * @param lCoverageBenefits List of newly inserted CoverageBenefit records.
     */
    public void afterInsertMethod(List<CoverageBenefit> lCoverageBenefits) {
    try {
        List<String> lstCovBenIds = new List<String>();
        for (CoverageBenefit covBen : lCoverageBenefits) {
            lstCovBenIds.add(covBen.Id);
        }

        // Utilize the utility method for querying CoverageBenefit records
        String sObjectType = 'CoverageBenefit';
        String fields = 'Id, OwnerId, Care_Program_Enrollee__r.CareProgramId';
        String conditions = 'Id IN (\'' + String.join((lstCovBenIds), '\', \'') + '\')';

        List<CoverageBenefit> newCoverageBenefits = (List<CoverageBenefit>) COM_QueryUtility.executeQuery(
            sObjectType, fields, conditions, true
        );

        if (newCoverageBenefits != null && !newCoverageBenefits.isEmpty()) {
            Map<String, Map<String, String>> mCoverageBenefits = new Map<String, Map<String, String>>();
            for (CoverageBenefit covBen1 : newCoverageBenefits) {
                Map<String, String> covDetails = mCoverageBenefits.get(covBen1.Care_Program_Enrollee__r.CareProgramId) ?? new Map<String, String>();
                covDetails.put(covBen1.Id, covBen1.OwnerId);
                mCoverageBenefits.put(covBen1.Care_Program_Enrollee__r.CareProgramId, covDetails);
            }
            TeamSharing_HelperClass.insertShareRecords('CoverageBenefit', 'CoverageBenefitShare', mCoverageBenefits);
        }
    } catch (Exception e) {
        GenericLogger.exceptionLog(e);
    }
}


    /**
     * @description Handles the after-delete trigger event for CoverageBenefit records.
     * @param lCoverageBenefits List of CoverageBenefit records being deleted.
     */
    public void afterDeleteMethod(List<CoverageBenefit> lCoverageBenefits) {
        try {
            Set<String> lstDeRecords = new Set<String>();
            for (CoverageBenefit covBen : lCoverageBenefits) {
                lstDeRecords.add(covBen.Id);
            }
            if (!lstDeRecords.isEmpty()) {
                TeamSharing_HelperClass.DeleteSharingRecords('CoverageBenefitShare', lstDeRecords);
            }
        } catch (Exception e) {
            GenericLogger.exceptionLog(e);
          
        }
    }
}