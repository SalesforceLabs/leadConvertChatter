public with sharing class deleteme {
	public static void testMerge(){
        String lastName='L1';
        String company='a';
        Lead l=createLead(lastName,company);
        lastName='L2';
        Lead l2=createLead(lastName,company);
        insert l;
        insert l2;
/*        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
  */      
		merge l2 l;
        
        LeadFeed[] leadPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM LeadFeed WHERE parentId=:l2.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :leadPostsMigrated];
	}
	
	    //utility class to create dummy data to test
    public static Lead createLead(String LN, String Cmpy) {
        Lead l = new Lead(LastName=LN, Company=Cmpy);
        return l;
    }//createLeads

    //utility class to create dummy data to test
    public static void convertLead(Lead l) {
        Database.LeadConvert lc=new Database.LeadConvert();
        lc.setLeadId(l.id);
        LeadStatus convertedStatus=[SELECT Id, MasterLabel FROM LeadStatus WHERE isConverted=TRUE LIMIT 1];
        lc.setConvertedStatus(convertedStatus.MasterLabel);
        
        Database.LeadConvertResult lcr=Database.convertlead(lc);
    }//convertLead

    public static FeedItem createPost(String body, Lead l){
        FeedItem f=new FeedItem();
        f.parentId=l.id;
        f.body=body;
        insert f;
        return f;
    }//createPost

    public static FeedComment createComment(String body, FeedItem f){
        FeedComment fc=new FeedComment();
        fc.commentBody=body;
        fc.feedItemId=f.Id;
        insert fc;
        return fc;
    }//createComment

    public static FeedItem createLinkPost(String body, Lead l){
        FeedItem f=new FeedItem();
        f.parentId=l.id;
        f.body=body;
        f.linkURL = 'https://login.salesforce.com/';
        f.title = 'im a link!';
        
        insert f;
        return f;
    }//createLinkPost

    public static FeedItem createFilePost(String body, Lead l){
        FeedItem f=new FeedItem();
        f.parentId=l.id;
        f.body=body;
        f.contentData=blob.valueOf('ABCDEFG');
        f.contentDescription='description';
        f.contentFileName='fileName';
        
        insert f;
        return f;
    }//createFilePost

    public static FeedLike createLike(Id postOrCommentId, Id postId){
        FeedLike l=new FeedLike();
        l.FeedEntityId=postOrCommentId;
        l.FeedItemId=postId;
        insert l;
        return l;
    }//createLike
}