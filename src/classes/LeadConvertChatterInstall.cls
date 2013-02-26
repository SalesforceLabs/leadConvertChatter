global class LeadConvertChatterInstall implements InstallHandler {

	global void onInstall(InstallContext context) {
    	if(context.previousVersion() == null) {
        	Map<String, LeadConvertChatter__c> settings=LeadConvertChatter__c.getAll();
        	if (settings.size()==0){
            	LeadConvertChatter__c setting=new LeadConvertChatter__c(Name=LeadConvertChatterController.settingName, Contact__c=TRUE, Account__c=FALSE, Opportunity__c=FALSE, MergeLeadContact__c=TRUE);
            	insert setting;
        	}//if 1
    	}//if 2

	    if(context.isUpgrade()) {
	    }
	    
	    if(context.isPush()) {
	    }
	    
    }//LeadConvertChatterInstall 
}//LeadConvertChatterInstall