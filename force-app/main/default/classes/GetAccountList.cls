public class GetAccountList {
@AuraEnabled
    public Static List<Account> getAccount(){
        return [SELECT Id, Name FROM ACCOUNT ];
    }
}