/**
 * @description       : A Common class for performing Dml operations.
 * History:
 * Version  Author      Date            Detail          Description
 * 1.0      Harish     25-Nov-2024     Created         Initial development.

 */
public inherited sharing class COM_DatabaseOperationsUtility {
	private static Database.SaveResult[] insertResults;
	private static Database.SaveResult[] updateResults;
    private static List<Database.DeleteResult> deleteResults;

/**
 * @description Inserts a list of SObject records into the database and handles errors.
 * The method supports user mode level access if specified. It returns the results of the insertion operation.
 * If any errors occur during the insertion, a DMLException is thrown with detailed error messages.
 * 
 * @param records List<SObject> A list of SObject records to be inserted.
 * @param className String The name of the class where the insertion is occurring, used for error logging.
 * @param userModeLevel Boolean Indicates whether to use user mode access level during the insertion.
 * 
 * @return Database.SaveResult[] An array of SaveResult objects representing the results of the insertion operation.
 * 
 * @throws DMLException If there are errors during the insertion operation.
 */
 public static Database.SaveResult[] insertOperation(List<SObject> records, String className, Boolean userModeLevel) {
	 try{
		if (userModeLevel) {
			insertResults = Database.insert(records, true, AccessLevel.USER_MODE);
		} else {
			insertResults = Database.insert(records, true);
		}
	   
	 }
	 catch(DMLException ex)
	 {
		 throw new DMLException(ex.getMessage());
	 }
		return insertResults;
	}
   /**
 * @description Updates a list of SObject records in the database and handles errors.
 * The method supports user mode level access if specified. It returns the results of the update operation.
 * If any errors occur during the update, a DMLException is thrown with detailed error messages.
 * 
 * @param records List<SObject> A list of SObject records to be updated.
 * @param className String The name of the class where the update is occurring, used for error logging.
 * @param userModeLevel Boolean Indicates whether to use user mode access level during the update.
 * 
 * @return Database.SaveResult[] An array of SaveResult objects representing the results of the update operation.
 * 
 * @throws DMLException If there are errors during the update operation.
 */ 
  public static Database.SaveResult[] updateOperation(List<SObject> records, String className, Boolean userModeLevel) {
	   
	 try{
		if (userModeLevel) {
			updateResults = Database.Update(records, true, AccessLevel.USER_MODE);
		} else {
			updateResults = Database.Update(records, true);
		}
		}
	catch(DMLException ex)
	{
		 throw new DMLException(ex.getMessage());
	 }
		return updateResults;
	}
	/**
 * @description Upserts a list of SObjects in either user mode or system mode.
 *
 * @param records The list of SObject records to upsert.
 * @param className The name of the class invoking this method, typically used for logging or debugging purposes.
 * @param userModeLevel A boolean indicating whether to use user mode (`true`) or system mode (`false`) for the upsert operation.
 * @return A list of Database.UpsertResult objects, representing the results of the upsert operation.
 * @throws DMLException If the upsert operation fails, an exception is thrown with an appropriate error message.
 */
  public static List<Database.UpsertResult> upsertOperation(List<SObject> records, String className, Boolean userModeLevel) {
	List<Database.UpsertResult> upsertResults;
	
	try {
		if (userModeLevel) {
			upsertResults = Database.upsert(records, true, AccessLevel.USER_MODE);
		} else {
			upsertResults = Database.upsert(records, true);
		}
	} catch(DMLException ex) {
		throw new DMLException(ex.getMessage());
	}
	
	return upsertResults;
}
/**
 * @description Deletes a list of SObjects in either user mode or system mode.
 *
 * @param records The list of SObject records to delete.
 * @param className The name of the class invoking this method, typically used for logging or debugging purposes.
 * @param userModeLevel A boolean indicating whether to use user mode (`true`) or system mode (`false`) for the delete operation.
 * @return A list of Database.DeleteResult objects, representing the results of the delete operation.
 * @throws DMLException If the delete operation fails, an exception is thrown with an appropriate error message.
 */
public static List<Database.DeleteResult> deleteOperation(List<SObject> records, String className, Boolean userModeLevel) {
	try {
		if (userModeLevel) {
			deleteResults = Database.delete(records, true, AccessLevel.USER_MODE);
		} else {
			deleteResults = Database.delete(records, true);
		}
	} catch(DMLException ex) {
		throw new DMLException(ex.getMessage());
	}
	
	return deleteResults;
}


/**
 * @description Deletes a list of SObjects in either user mode or system mode.
 *
 * @param records The list of SObject records to delete.
 * @param className The name of the class invoking this method, typically used for logging or debugging purposes.
 * @param userModeLevel A boolean indicating whether to use user mode (`true`) or system mode (`false`) for the delete operation.
 * @return A list of Database.DeleteResult objects, representing the results of the delete operation.
 * @throws DMLException If the delete operation fails, an exception is thrown with an appropriate error message.
 */
public static List<Database.DeleteResult> deleteOperationForBatch(List<SObject> records, Boolean orAllNull, Boolean userModeLevel) {
	try {
		if (userModeLevel) {
			deleteResults = Database.delete(records, orAllNull, AccessLevel.USER_MODE);
		} else {
			deleteResults = Database.delete(records, orAllNull);
		}
	} catch(DMLException ex) {
		throw new DMLException(ex.getMessage());
	}
	
	return deleteResults;
}

/**
 * @description Inserts a list of SObjects in either user mode or system mode.
 *
 * @param records The list of SObject records to insert.
 * @param orAllNull The boolean value to rollback or not.
 * @param userModeLevel A boolean indicating whether to use user mode (`true`) or system mode (`false`) for the delete operation.
 * @return A list of Database.insertResults objects, representing the results of the insert operation.
 * @throws DMLException If the insert operation fails, an exception is thrown with an appropriate error message.
 */
 public static Database.SaveResult[] insertOperationForBatch(List<SObject> records, Boolean orAllNull, Boolean userModeLevel) {
	 try{
		if (userModeLevel) {
			insertResults = Database.insert(records, orAllNull, AccessLevel.USER_MODE);
		} else {
			insertResults = Database.insert(records, orAllNull);
		}
	   
	 }
	 catch(DMLException ex)
	 {
		 throw new DMLException(ex.getMessage());
	 }
		return insertResults;
	}

	
}