trigger leadConvertChatter on Lead (after update) {
//    system.debug('The number of converted leads is:'+trigger.new.size());

    List<Lead> convertedLeads=new List<Lead>();
//    List<Lead> mergedLeadLosers=new List<Lead>();
    Lead[] leads;
/*    if(system.trigger.isDelete){
    	system.debug('trigger.old '+trigger.old);
    	system.debug('trigger.new '+trigger.new);
    	
//    	leads=[SELECT Id, firstname, Name, isConverted, masterRecordId FROM Lead WHERE Id IN: trigger.old AND isDeleted=TRUE];
    	for (Lead l:trigger.old){
	    	system.debug('The lead first name is: '+l.firstName);
    		system.debug('The lead Id is: '+l.Id);
    		system.debug('The lead name is: '+l.name);
    		system.debug('The master record id is: '+l.masterRecordId);
	        if(l.masterRecordId!=null)
				mergedLeadLosers.add(l);
    	}//for 1
    }else{*/
    
	leads=[SELECT Id, firstname, Name, isConverted, masterRecordId FROM Lead WHERE Id IN: trigger.new];
	for (Lead l:leads){
    	system.debug('The lead first name is: '+l.firstName);
    	system.debug('The lead Id is: '+l.Id);
    	system.debug('The lead name is: '+l.name);
    	system.debug('The master record id is: '+l.masterRecordId);
        if(l.isConverted==TRUE)
            convertedLeads.add(l);
	}//for 1	
//    }//if 1

    Set<String> supportedTypes=new Set<String>();
    supportedTypes.add('TextPost');//post any person makes on the lead feed
    supportedTypes.add('LinkPost');//link post
    supportedTypes.add('ContentPost');//File post - sharing with the new record will make the file public to people that can see the new record
    supportedTypes.add('TextComment');//text comment
    supportedTypes.add('ContentComment');//File comment
//  excludedTypes.add('PollPost');//Not yet API accessible as in pilot as of time of coding.  Would need special code to transfer the results
//  excludedTypes.add('userStatus');//post on someone's profile - doesn't apply to lead
//  excludedTypes.add('TrackedChange');//we don't want to bring over the noise of feed tracked changes
//  excludedTypes.add('DashboardComponentSnapshot');//excluding to keep things a bit simpler
//  excludedTypes.add('ApprovalPost');//including would be confusing given approvals are tied to one object
//  excludedTypes.add('CollaborationGroupCreated');//Shouldn't apply, but including just in case

    
    if(convertedLeads.size()>0){
//    	system.debug('converted leads is: '+convertedLeads);
        List<LeadFeed> posts=[SELECT Id, CommentCount, LikeCount, Body, ContentDescription, ContentFileName, createdById, CreatedDate, InsertedById, LinkURL, ParentId, RelatedRecordId, Title, Type, (SELECT createdById from FeedLikes),(SELECT CreatedById,CreatedDate,CommentBody, CommentType, FeedItemId, InsertedById, RelatedRecordId FROM FeedComments WHERE CommentType IN: supportedTypes) FROM LeadFeed WHERE ParentId IN: convertedLeads AND Type IN : supportedTypes];
//        system.debug('The number of posts on the converted leads is:'+posts.size());
        
//        Map<String,LeadConvertChatter__c> newParentSetting=LeadConvertChatter__c.getAll();
  		if(LeadConvertChatter__c.getInstance(LeadConvertChatterController.settingName)!=null){
	  		LeadConvertChatter__c setting=LeadConvertChatter__c.getInstance(LeadConvertChatterController.settingName);
	        
	        Boolean moveToAccount=FALSE;
	        Boolean moveToContact=FALSE;
	        Boolean moveToOppty=FALSE;
	
	        //should only be one - will have other validation to prevent inserting more than 1 row
	//        for (String settingName:newParentSetting.keySet()){
	            moveToAccount=setting.Account__c;
	            moveToContact=setting.Contact__c;
	            moveToOppty=setting.Opportunity__c;
	  //      }//for 1
	
	        Map<Id,Id> leadtoNewAccountMap=new Map<Id,Id>();
	        Map<Id,Id> leadtoNewContactMap=new Map<Id,Id>();
	        Map<Id,Id> leadtoNewOpptyMap=new Map<Id,Id>();
	        for(Lead l:trigger.new){
	            if(moveToAccount==TRUE)
	                leadtoNewAccountMap.put(l.Id,l.convertedAccountId);
	            if(moveToContact==TRUE)
	                leadtoNewContactMap.put(l.Id,l.convertedContactId);
	            if(moveToOppty==TRUE && l.convertedOpportunityId!=null)
	                leadtoNewOpptyMap.put(l.Id,l.convertedOpportunityId);
	        }//for 1
//			system.debug('moveToAccount: '+moveToAccount);
//			system.debug('moveToContact: '+moveToContact);
//			system.debug('moveToOppty: '+moveToOppty);
	        if(moveToAccount==TRUE)
	        	Boolean success=leadConvertChatter.movePostsCommentsLikes(leadtoNewAccountMap, posts);
	        
	        if(moveToContact==TRUE)
	        	Boolean success=leadConvertChatter.movePostsCommentsLikes(leadtoNewContactMap, posts);
	
	        if(moveToOppty==TRUE)
	        	Boolean success=leadConvertChatter.movePostsCommentsLikes(leadtoNewOpptyMap, posts);
  		}//if 2
    }//if 1  
/*    
    //Now handle the merged leads
    if(mergedLeadLosers.size()>0){
  		LeadConvertChatter__c setting=LeadConvertChatter__c.getInstance(LeadConvertChatterController.settingName);
    	if(setting.MergeLeadContact__c==TRUE){
	        List<LeadFeed> posts=[SELECT Id, CommentCount, LikeCount, Body, ContentDescription, ContentFileName, createdById, CreatedDate, InsertedById, LinkURL, ParentId, RelatedRecordId, Title, Type, (SELECT createdById from FeedLikes),(SELECT CreatedById,CreatedDate,CommentBody, CommentType, FeedItemId, InsertedById, RelatedRecordId FROM FeedComments WHERE CommentType IN: supportedTypes) FROM LeadFeed WHERE ParentId IN: mergedLeadLosers AND Type IN : supportedTypes];
	
	        Map<String,LeadConvertChatter__c> newParentSetting=LeadConvertChatter__c.getAll();
	        Boolean moveToContact=FALSE;
	        Boolean moveToOppty=FALSE;
	
	        Map<Id,Id> leadtoNewLeadMap=new Map<Id,Id>();
	        for(Lead l:trigger.old)
	            if(l.masterRecordId!=null)
	                leadtoNewLeadMap.put(l.Id,l.masterRecordId);
			
        	Boolean success=leadConvertChatter.movePostsCommentsLikes(leadtoNewLeadMap, posts);
        }//if 2            
    }//if 1
  */        
}//trigger