/**
 * @description       : A utility class for handling various operations related to Care Program Enrollees,
 *                      including retrieving enrollee details, fax numbers, and associated files.
 * @author            : Mickram
 * @group             : 
 * @modified by       : Vijay
 * @last modified on  : 13-12-2024
 */
public with sharing class J_SendFaxLwc{ 
     /**
     * @description       : Retrieves the enrollee ID based on the provided record ID and its object type.
     *                      If the object type maps to another related enrollee record, the method follows the
     *                      relationship to fetch the appropriate enrollee ID.
     * @param recordId    : The ID of the record for which the enrollee ID is to be retrieved.
     * @return            : The ID of the enrollee, or the provided record ID if no mapping is found.
     */

@AuraEnabled(cacheable = true)
public static string getEnrolleeId(Id recordId) {
    try {
        Schema.SObjectType objectType = recordId.getSObjectType();

        if (objectType == Schema.CareProgramEnrollee.SObjectType) {
            return recordId;
        }

        String query = getQueryForObjectType(objectType);
        if (String.isBlank(query)) {
            return recordId;
        }

        return executeQueryAndExtractEnrolleeId(query, objectType);
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
}

private static String getQueryForObjectType(Schema.SObjectType objectType) {
    Map<Schema.SObjectType, String> objectQueryMap = new Map<Schema.SObjectType, String>{
        Schema.Case.SObjectType => 'SELECT Care_Program_Enrollee__c FROM Case WHERE Id = :recordId',
        Schema.CoverageBenefit.SObjectType => 'SELECT Care_Program_Enrollee__c FROM CoverageBenefit WHERE Id = :recordId',
        Schema.CarePreauth.SObjectType => 'SELECT Care_Program_Enrollee__c FROM CarePreauth WHERE Id = :recordId',
        Schema.Appeal__c.SObjectType => 'SELECT Authorization__r.Care_Program_Enrollee__c FROM Appeal__c WHERE Id = :recordId',
        Schema.J_Copay__c.SObjectType => 'SELECT Care_Program_Enrollee__c FROM J_Copay__c WHERE Id = :recordId',
        Schema.J_Charitable__c.SObjectType => 'SELECT Care_Program_Enrollee__c FROM J_Charitable__c WHERE Id = :recordId'
    };
    return objectQueryMap.get(objectType);
}

private static String executeQueryAndExtractEnrolleeId(String query, Schema.SObjectType objectType) {
    List<SObject> records = Database.query(query);

    if (records.isEmpty()) {
        return null;
    }

    SObject firstRecord = records[0];

    if (objectType == Schema.Appeal__c.SObjectType) {
        SObject authorization = firstRecord.getSObject('Authorization__r');
        return authorization != null ? (String)authorization.get('Care_Program_Enrollee__c') : null;
    }

    return (String)firstRecord.get('Care_Program_Enrollee__c');
}

/**
     * @description       : Retrieves the name of the Care Program Enrollee associated with the given record ID.
     * @param recordId    : The ID of the record for which the enrollee name is to be retrieved.
     * @return            : The name of the Care Program Enrollee.
     */
    
    @AuraEnabled (cacheable = true)
    public static string getEnrolleeName(id recordId){
        string enrolleeName;
        
        Schema.SObjectType objectType = recordId.getSobjectType();
        if (objectType == Schema.Case.SObjectType) {
            // Query the Case and get the Care_Program_Enrollee__c field
            String sObjectType = 'Case';
      		String fields = 'id, Care_Program_Enrollee__c';
        	String conditions = 'id = \'' + recordId + '\'';
        
            List<Case> cases=(List<Case>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            Case relatedCase = cases[0];
            recordId = relatedCase.Care_Program_Enrollee__c;
        }
        else if (objectType == Schema.CoverageBenefit.SObjectType) {
            // Query the CoverageBenefit and get the Care_Program_Enrollee__c field
            String sObjectType = 'CoverageBenefit';
      		String fields = 'id, Care_Program_Enrollee__c';
        	String conditions = 'id = \'' + recordId + '\'';
        
            List<CoverageBenefit> cb=(List<CoverageBenefit>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            CoverageBenefit relatedCB = cb[0];
            recordId = relatedCB.Care_Program_Enrollee__c;
        }
        else if (objectType == Schema.CarePreauth.SObjectType) {
                String sObjectType = 'CarePreauth';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<CarePreauth> pa=(List<CarePreauth>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	CarePreauth relatedPriAuth = pa[0];
                recordId = relatedPriAuth.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.Appeal__c.SObjectType) {
                Appeal__c relatedAppeal = [SELECT id, Authorization__r.Care_Program_Enrollee__c FROM Appeal__c WHERE id = :recordId WITH SECURITY_ENFORCED LIMIT 1];
                recordId = relatedAppeal.Authorization__r.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.J_Copay__c.SObjectType) {
           		String sObjectType = 'J_Copay__c';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<J_Copay__c> copay=(List<J_Copay__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	J_Copay__c relatedCopay = copay[0];
                recordId = relatedCopay.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.J_Charitable__c.SObjectType) {
          	    String sObjectType = 'J_Charitable__c';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<J_Charitable__c> pap=(List<J_Charitable__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	J_Charitable__c relatedPAP = pap[0];
                recordId = relatedPAP.Care_Program_Enrollee__c;
            }
        	    String sObjectType = 'CareProgramEnrollee';
      		    String fields = 'id, name';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<CareProgramEnrollee> cpEnrollee=(List<CareProgramEnrollee>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	CareProgramEnrollee cpe = cpEnrollee[0];
                enrolleeName = cpe.Name;
        	    return enrolleeName;
        
    }
    /**
     * @description       : Retrieves the fax number of the organization associated with the Care Program Enrollee
     *                      linked to the provided record ID.
     * @param recordId    : The ID of the record for which the organization fax number is to be retrieved.
     * @return            : The fax number of the organization.
     */
    @AuraEnabled (cacheable = true)
    public static string getCpFaxNum(id recordId){
        string cpFaxNum;
        
        Schema.SObjectType objectType = recordId.getSobjectType();
        if (objectType == Schema.Case.SObjectType) {
            // Query the Case and get the Care_Program_Enrollee__c field
           		String sObjectType = 'Case';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<Case> cases=(List<Case>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	Case relatedCase = cases[0];
           		recordId = relatedCase.Care_Program_Enrollee__c;
        }
        else if (objectType == Schema.CoverageBenefit.SObjectType) {
            // Query the CoverageBenefit and get the Care_Program_Enrollee__c field
        	    String sObjectType = 'CoverageBenefit';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<CoverageBenefit> cb=(List<CoverageBenefit>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	CoverageBenefit relatedCB = cb[0];
                recordId = relatedCB.Care_Program_Enrollee__c;
        }
        else if (objectType == Schema.CarePreauth.SObjectType) {
            	String sObjectType = 'CarePreauth';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<CarePreauth> pa=(List<CarePreauth>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	CarePreauth relatedPriAuth = pa[0];
                recordId = relatedPriAuth.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.Appeal__c.SObjectType) {
                Appeal__c relatedAppeal = [SELECT id, Authorization__r.Care_Program_Enrollee__c FROM Appeal__c WHERE id = :recordId WITH SECURITY_ENFORCED LIMIT 1];
                recordId = relatedAppeal.Authorization__r.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.J_Copay__c.SObjectType) {
                String sObjectType = 'J_Copay__c';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<J_Copay__c> copay=(List<J_Copay__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	J_Copay__c relatedCopay = copay[0];
                recordId = relatedCopay.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.J_Charitable__c.SObjectType) {
                String sObjectType = 'J_Charitable__c';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<J_Charitable__c> pap=(List<J_Charitable__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	J_Charitable__c relatedPAP = pap[0];
                recordId = relatedPAP.Care_Program_Enrollee__c;
            }
         
        CareProgramEnrollee cpe1= [select id, name, CareProgram.Organisation_Fax_number__c from CareProgramEnrollee where id =:recordId WITH SECURITY_ENFORCED ];
        cpFaxNum = cpe1.CareProgram.Organisation_Fax_number__c;
        return cpFaxNum;
        
    }
    /**
     * @description       : Retrieves the fax number of the healthcare provider associated with the Care Program Enrollee
     *                      linked to the provided record ID.
     * @param recordId    : The ID of the record for which the HCP fax number is to be retrieved.
     * @return            : The fax number of the healthcare provider.
     */
    @AuraEnabled (cacheable = true)
    public static string getFaxNum(Id recordId){
        string faxNum; 
        
       Schema.SObjectType objectType = recordId.getSobjectType();
        if (objectType == Schema.Case.SObjectType) {
            // Query the Case and get the Care_Program_Enrollee__c field
          	    String sObjectType = 'Case';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<Case> cases=(List<Case>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	Case relatedCase = cases[0];
                recordId = relatedCase.Care_Program_Enrollee__c;
        }
        else if (objectType == Schema.CoverageBenefit.SObjectType) {
            // Query the CoverageBenefit and get the Care_Program_Enrollee__c field
           	    String sObjectType = 'CoverageBenefit';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<CoverageBenefit> cb=(List<CoverageBenefit>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	CoverageBenefit relatedCB = cb[0];
                recordId = relatedCB.Care_Program_Enrollee__c;
        }
        else if (objectType == Schema.CarePreauth.SObjectType) {
                String sObjectType = 'CarePreauth';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<CarePreauth> pa=(List<CarePreauth>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	CarePreauth relatedPriAuth = pa[0];
                recordId = relatedPriAuth.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.Appeal__c.SObjectType) {
                Appeal__c relatedAppeal = [SELECT id, Authorization__r.Care_Program_Enrollee__c FROM Appeal__c WHERE id = :recordId WITH SECURITY_ENFORCED LIMIT 1];
                recordId = relatedAppeal.Authorization__r.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.J_Copay__c.SObjectType) {
                String sObjectType = 'J_Copay__c';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<J_Copay__c> copay=(List<J_Copay__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	J_Copay__c relatedCopay = copay[0];
                recordId = relatedCopay.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.J_Charitable__c.SObjectType) {
            	String sObjectType = 'J_Charitable__c';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<J_Charitable__c> pap=(List<J_Charitable__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	J_Charitable__c relatedPAP = pap[0];
                recordId = relatedPAP.Care_Program_Enrollee__c;
            }
    	PatientMedicationDosage dosage = [select id,Enrollee_HCP__r.HCP__r.Fax, Enrollee_HCP__r.HCP__c, Specialty_Pharmacy__c from PatientMedicationDosage where Care_Program_Enrollee_Name__c =:recordId
                                         AND Current_Dose_Record__c = true
                                         WITH SECURITY_ENFORCED
                                        ORDER BY LastModifiedDate DESC 
                                  		LIMIT 1];
        	faxNum = dosage.Enrollee_HCP__r.HCP__r.Fax;
        return faxNum;
        
    }
    /**
     * @description       : Retrieves the fax number of the specialty pharmacy associated with the Care Program Enrollee
     *                      linked to the provided record ID.
     * @param recordId    : The ID of the record for which the pharmacy fax number is to be retrieved.
     * @return            : The fax number of the specialty pharmacy.
     */
    @AuraEnabled (cacheable = true)
    public static string getPharFax(id recordId){
        
        string pharFax;
        
        Schema.SObjectType objectType = recordId.getSobjectType();
        if (objectType == Schema.Case.SObjectType) {
            // Query the Case and get the Care_Program_Enrollee__c field
          	    String sObjectType = 'Case';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<Case> cases=(List<Case>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	Case relatedCase = cases[0];
                recordId = relatedCase.Care_Program_Enrollee__c;
        }
        else if (objectType == Schema.CoverageBenefit.SObjectType) {
            // Query the CoverageBenefit and get the Care_Program_Enrollee__c field
           	    String sObjectType = 'CoverageBenefit';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<CoverageBenefit> cb=(List<CoverageBenefit>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	CoverageBenefit relatedCB = cb[0];
                recordId = relatedCB.Care_Program_Enrollee__c;
        }
        else if (objectType == Schema.CarePreauth.SObjectType) {
                String sObjectType = 'CarePreauth';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<CarePreauth> pa=(List<CarePreauth>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	CarePreauth relatedPriAuth = pa[0];
                recordId = relatedPriAuth.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.Appeal__c.SObjectType) {
                Appeal__c relatedAppeal = [SELECT id, Authorization__r.Care_Program_Enrollee__c FROM Appeal__c WHERE id = :recordId WITH SECURITY_ENFORCED LIMIT 1];
                recordId = relatedAppeal.Authorization__r.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.J_Copay__c.SObjectType) {
                String sObjectType = 'J_Copay__c';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<J_Copay__c> copay=(List<J_Copay__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	J_Copay__c relatedCopay = copay[0];
                recordId = relatedCopay.Care_Program_Enrollee__c;
            }
        else if (objectType == Schema.J_Charitable__c.SObjectType) {
            	String sObjectType = 'J_Charitable__c';
      		    String fields = 'id, Care_Program_Enrollee__c';
        	    String conditions = 'id = \'' + recordId + '\'';
        
            	List<J_Charitable__c> pap=(List<J_Charitable__c>)COM_QueryUtility.executeQuery(sObjectType, fields, conditions, true);
            	J_Charitable__c relatedPAP = pap[0];
                recordId = relatedPAP.Care_Program_Enrollee__c;
            }
    PatientMedicationDosage dosage = [select id,Enrollee_HCP__r.HCP__r.Fax, Enrollee_HCP__r.HCP__c, Specialty_Pharmacy__r.Fax from PatientMedicationDosage where Care_Program_Enrollee_Name__c =:recordId
                                     AND Current_Dose_Record__c = true
                                     WITH SECURITY_ENFORCED
                                     ORDER BY LastModifiedDate DESC
                                  		LIMIT 1];
        pharFax = dosage.Specialty_Pharmacy__r.Fax;
        return pharFax;
        
    }    
}