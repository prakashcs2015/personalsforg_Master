public class AccountBatchExample implements Database.Batchable<sObject>,Database.Stateful {
	public Integer recordProcessed=0;
    public Database.QueryLocator start (Database.BatchableContext bc){
        return Database.getQueryLocator( 'SELECT ID, BillingStreet, BillingCity, BillingState, ' +
            'BillingPostalCode, (SELECT ID, MailingStreet, MailingCity, ' +
            'MailingState, MailingPostalCode FROM Contacts) FROM Account ' +
            'Where BillingCountry = \'USA\'');
    }
    public void execute(Database.BatchableContext bc, List<Account> scope){
        
    }
    public void finish(Database.BatchableContext bc){
        
    }
}