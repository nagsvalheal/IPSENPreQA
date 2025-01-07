/**
 * @description Utility class to fetch configuration values from the
 *              custom metadata type `J_ConsentConfiguration__mdt`.
 *              Provides a single method to retrieve all configuration values.
 * @date 26-12-2024
 */
public with sharing class J_ConsentMetadataUtility {
	/**
	 * @description Retrieves all configuration values from the custom metadata type.
	 * @return Map<String, Integer> - A map containing configuration field names as keys and their values as integers.
	 *                                Defaults to 0 if metadata is missing or field values are null.
	 */
	public static Map<String, Integer> getAllConfigurationValues() {
		// Initialize map with default values
		Map<String, Integer> configValues = new Map<String, Integer>{
			'TaskCreationOffsetDays' => 0,
			'ExpirationStartOffsetDays' => 0,
			'ExpirationEndOffsetDays' => 0,
			'ConsentAgeLimitYears' => 0
		};

		try {
			// Fetch metadata instance
			J_ConsentConfiguration__mdt config = J_ConsentConfiguration__mdt.getInstance(
				'DefaultConsentConfig'
			);
			if (config != null) {
				// Populate map with values from metadata
				configValues.put(
					'TaskCreationOffsetDays',
					config.TaskCreationOffsetDays__c != null
						? Integer.valueOf(config.TaskCreationOffsetDays__c)
						: 0
				);
				configValues.put(
					'ExpirationStartOffsetDays',
					config.ExpirationStartOffsetDays__c != null
						? Integer.valueOf(config.ExpirationStartOffsetDays__c)
						: 0
				);
				configValues.put(
					'ExpirationEndOffsetDays',
					config.ExpirationEndOffsetDays__c != null
						? Integer.valueOf(config.ExpirationEndOffsetDays__c)
						: 0
				);
				configValues.put(
					'ConsentAgeLimitYears',
					config.ConsentAgeLimitYears__c != null
						? Integer.valueOf(config.ConsentAgeLimitYears__c)
						: 0
				);
			}
		} catch (Exception ex) {
			GenericLogger.logErrorAndHandle('J_ConsentMetadataUtility','getAllConfigurationValues','Error fetching configuration metadata: ' + ex.getMessage(),false);
		}

		return configValues;
	}
}