public with sharing class LeadConvertChatterController{
    public final LeadConvertChatter__c lcc;
	public static String settingName='default';

	public LeadConvertChatterController(){
        Map<String, LeadConvertChatter__c> settings=LeadConvertChatter__c.getAll();
        LeadConvertChatter__c setting=settings.get(settingName);
        this.lcc=setting;
	}//LeadConvertChatterController
	
    public PageReference editSetting(){
        PageReference pageRef=page.LeadConvertChatterSetupEdit;
        return pageRef;
    }//editSetting

	public void defaultSetting(){
        Map<String, LeadConvertChatter__c> settings=LeadConvertChatter__c.getAll();
        if (settings.containsKey(settingName)==FALSE){
            LeadConvertChatter__c setting=new LeadConvertChatter__c(Name=settingName, Contact__c=TRUE, Account__c=FALSE, Opportunity__c=FALSE, MergeLeadContact__c=TRUE);
            insert setting;
        }//if 1		
	}//defaultSetting
	
    public LeadConvertChatter__c getSetting(){
        return lcc;
    }//getSettings

    public PageReference save(){
        update lcc;
        PageReference pageRef=page.LeadConvertChatterSetupDetail;
		return pageRef;
    }//save

}//LeadConvertChatterController