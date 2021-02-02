public with sharing class LookupController {
	@auraEnabled
	public static List<sObject> getRecords(String objectName, String fields, String whereClause) {
		try{
			Set<String> fieldSet = new Set<String>(fields!=null && fields != ''? fields.split(',') : new List<String>());
			fieldSet.add('Id');
			fieldSet.add('Name');

			List<String> fieldList = new List<String>(fieldSet);

			String query = 'SELECT ' + String.join(fieldList,',') + ' FROM ' + objectName;
			
			if (whereClause != null && whereClause != '') {
				query += ' WHERE Name LIKE \'%' + whereClause + '%\'';
			}

			query += ' ORDER BY LastModifiedDate';
			if (!(whereClause != null && whereClause != '')) {
				query += ' LIMIT 5';
			}

			return Database.query(query);
		} catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
	}
}