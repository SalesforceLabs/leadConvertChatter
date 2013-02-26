@isTest (SeeAllData=TRUE)//Note that all tests fail if "SeeAllData=FALSE" as LeadFeed isn't visible from tests without this notation
private class leadConvertChatterTests {
    
    //Used to save the resulting lead convert objects for simple cases
    Public static Opportunity o;
    Public static Account a;
    Public static Contact c;

    public static testmethod void testInstallScript() {
        Map<String, LeadConvertChatter__c> settings=LeadConvertChatter__c.getAll();
        if(settings.containsKey(LeadConvertChatterController.settingName)==TRUE){
            LeadConvertChatter__c setting=settings.get(LeadConvertChatterController.settingName);
            delete setting;
        }//if
        
        LeadConvertChatterInstall postInstall = new LeadConvertChatterInstall();
        Test.testInstall(postInstall , null);
//      Test.testInstall(LeadConvertChatterInstall, new Version(1,0), true);
        settings=LeadConvertChatter__c.getAll();
        System.assertEquals(TRUE, settings.containsKey(LeadConvertChatterController.settingName));
        LeadConvertChatter__c setting=settings.get(LeadConvertChatterController.settingName);
        system.assertEquals(TRUE, setting.contact__c);
        system.assertEquals(FALSE, setting.account__c);
        system.assertEquals(FALSE, setting.opportunity__c);
        system.assertEquals(TRUE, setting.MergeLeadContact__c);
    }//testInstallScript

    public static testmethod void testController() {
        Map<String, LeadConvertChatter__c> settings=LeadConvertChatter__c.getAll();
        if(settings.containsKey(LeadConvertChatterController.settingName)==TRUE){
            LeadConvertChatter__c setting=settings.get(LeadConvertChatterController.settingName);
            delete setting;
        }//if

		LeadConvertChatterController cont=new LeadConvertChatterController();
		cont.defaultSetting();
		
        settings=LeadConvertChatter__c.getAll();
        System.assertEquals(TRUE, settings.containsKey(LeadConvertChatterController.settingName));
    }//testController

    public static testmethod void testController2() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);

        Map<String, LeadConvertChatter__c> settings=LeadConvertChatter__c.getAll();
		LeadConvertChatterController cont=new LeadConvertChatterController();

		LeadConvertChatter__c setting=settings.get(LeadConvertChatterController.settingName);
		setting.account__c=TRUE;
		setting.opportunity__c=TRUE;
		setting.contact__c=FALSE;
		setting.MergeLeadContact__c=FALSE;
		
		PageReference savePage=cont.save();
		setting=LeadConvertChatter__c.getInstance(LeadConvertChatterController.settingName);
		system.assertEquals(TRUE, setting.account__c);
		system.assertEquals(TRUE, setting.opportunity__c);
		system.assertEquals(FALSE, setting.contact__c);
		system.assertEquals(FALSE, setting.MergeLeadContact__c);
    }//testController2

    public static testmethod void verifyNoTextPostIfOff() {
        Map<String, LeadConvertChatter__c> settings=LeadConvertChatter__c.getAll();
        if(settings.containsKey(LeadConvertChatterController.settingName)==TRUE){
            LeadConvertChatter__c setting=settings.get(LeadConvertChatterController.settingName);
            delete setting;
        }//if
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        
        Boolean testFailed=FALSE;
        test.startTest();
            try{
            	convertLead(l);
            }catch (exception e){
            	testFailed=TRUE;
            }
        test.stopTest();
        system.assertEquals(FALSE, testFailed);
        
        ContactFeed[] postsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :postsMigrated];
        
        system.assertEquals(0, postsMigrated.size());
        system.assertEquals(0,commentsMigrated.size());    
    }//verifyNoTextPostIfOff


    public static testmethod void verifyTextPost() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] postsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :postsMigrated];
        
        system.assertEquals(1, postsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,postsMigrated[0].getSObjects('feedLikes').size());
    }//verifyTextPost

    public static testmethod void verifyLinkPost() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createLinkPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] postsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :postsMigrated];
        
        system.assertEquals(1, postsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,postsMigrated[0].getSObjects('feedLikes').size());
    }//verifyLinkPost

    public static testmethod void verifyLinkPostNullBody() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body=null;
        FeedItem f=createLinkPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] postsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :postsMigrated];
        
        system.assertEquals(1, postsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,postsMigrated[0].getSObjects('feedLikes').size());
    }//verifyLinkPostNullBody

    public static testmethod void verifyFilePost() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with a file.';
        FeedItem f=createFilePost(body, l);
        
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] postsMigrated=[SELECT Id, body, RelatedRecordId, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :postsMigrated];
        
        system.assertEquals(1, postsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,postsMigrated[0].getSObjects('feedLikes').size());
		system.assertNotEquals(null,postsMigrated[0].relatedRecordId);
    }//verifyFilePost

    public static testmethod void verifyFilePostNullBody() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body=null;
        FeedItem f=createFilePost(body, l);
        
        body='Im a great post with a file.';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] postsMigrated=[SELECT Id, body, RelatedRecordId, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :postsMigrated];
        
        system.assertEquals(1, postsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,postsMigrated[0].getSObjects('feedLikes').size());
		system.assertNotEquals(null,postsMigrated[0].relatedRecordId);
    }//verifyFilePostNullBody

    public static testmethod void verifyContactOnly() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :contactPostsMigrated];
        OpportunityFeed[] opptyPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM OpportunityFeed WHERE parentId=:o.id];
        AccountFeed[] acctPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM AccountFeed WHERE parentId=:a.id];
        
        system.assertEquals(1, contactPostsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,contactPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(0, opptyPostsMigrated.size());
        system.assertEquals(0,acctPostsMigrated.size());    
    }//verifyContactOnly

    public static testmethod void verifyAcctOnly() {
        Boolean moveToAcct=TRUE;
        Boolean moveToContact=FALSE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        OpportunityFeed[] opptyPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM OpportunityFeed WHERE parentId=:o.id];
        AccountFeed[] acctPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM AccountFeed WHERE parentId=:a.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :acctPostsMigrated];
        
        system.assertEquals(0, contactPostsMigrated.size());
        system.assertEquals(0, opptyPostsMigrated.size());
        system.assertEquals(1,acctPostsMigrated.size());    
        system.assertEquals(1,acctPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(2,commentsMigrated.size());    
    }//verifyAcctOnly

    public static testmethod void verifyOpptyOnly() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=FALSE;
        Boolean moveToOppty=TRUE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        OpportunityFeed[] opptyPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM OpportunityFeed WHERE parentId=:o.id];
        AccountFeed[] acctPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM AccountFeed WHERE parentId=:a.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :opptyPostsMigrated];
        
        system.assertEquals(0, contactPostsMigrated.size());
        system.assertEquals(1, opptyPostsMigrated.size());
        system.assertEquals(0,acctPostsMigrated.size());    
        system.assertEquals(1,opptyPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(2,commentsMigrated.size());    
    }//verifyOpptyOnly

    public static testmethod void verifyAcctOppty() {
        Boolean moveToAcct=TRUE;
        Boolean moveToContact=FALSE;
        Boolean moveToOppty=TRUE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        OpportunityFeed[] opptyPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM OpportunityFeed WHERE parentId=:o.id];
        AccountFeed[] acctPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM AccountFeed WHERE parentId=:a.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :acctPostsMigrated];
        FeedComment[] commentsMigrated2=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :opptyPostsMigrated];
        
        system.assertEquals(0, contactPostsMigrated.size());
        system.assertEquals(1, opptyPostsMigrated.size());
        system.assertEquals(1,acctPostsMigrated.size());    
        system.assertEquals(1,opptyPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(1,acctPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(2,commentsMigrated2.size());    
    }//verifyAcctOppty

    public static testmethod void verifyContactOppty() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=TRUE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        OpportunityFeed[] opptyPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM OpportunityFeed WHERE parentId=:o.id];
        AccountFeed[] acctPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM AccountFeed WHERE parentId=:a.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :contactPostsMigrated];
        FeedComment[] commentsMigrated2=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :opptyPostsMigrated];
        
        system.assertEquals(1, contactPostsMigrated.size());
        system.assertEquals(1, opptyPostsMigrated.size());
        system.assertEquals(0,acctPostsMigrated.size());    
        system.assertEquals(1,opptyPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(1,contactPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(2,commentsMigrated2.size());    
    }//verifyContactOppty

    public static testmethod void verifyContactAcct() {
        Boolean moveToAcct=TRUE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        OpportunityFeed[] opptyPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM OpportunityFeed WHERE parentId=:o.id];
        AccountFeed[] acctPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM AccountFeed WHERE parentId=:a.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :contactPostsMigrated];
        FeedComment[] commentsMigrated2=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :acctPostsMigrated];
        
        system.assertEquals(1, contactPostsMigrated.size());
        system.assertEquals(0, opptyPostsMigrated.size());
        system.assertEquals(1,acctPostsMigrated.size());    
        system.assertEquals(1,acctPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(1,contactPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(2,commentsMigrated2.size());    
    }//verifyContactAcct

    public static testmethod void verifyContactAcctOppty() {
        Boolean moveToAcct=TRUE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=TRUE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        OpportunityFeed[] opptyPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM OpportunityFeed WHERE parentId=:o.id];
        AccountFeed[] acctPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM AccountFeed WHERE parentId=:a.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :contactPostsMigrated];
        FeedComment[] commentsMigrated2=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :acctPostsMigrated];
        FeedComment[] commentsMigrated3=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :opptyPostsMigrated];
        
        system.assertEquals(1, contactPostsMigrated.size());
        system.assertEquals(1, opptyPostsMigrated.size());
        system.assertEquals(1,acctPostsMigrated.size());    
        system.assertEquals(1,acctPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(1,contactPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(1,opptyPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(2,commentsMigrated2.size());    
        system.assertEquals(2,commentsMigrated3.size());    
    }//verifyContactAcctOppty

    public static testmethod void verifyExistingContact() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        Account acct=new Account();
        acct.name=company;
        insert acct;
        
        Contact con=new Contact();
        con.lastName=lastName;
        con.accountId=acct.Id;
        
        insert con;
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            Database.LeadConvert lc=new Database.LeadConvert();
            lc.setLeadId(l.id);
            lc.accountId=acct.Id;
            lc.contactId=con.Id;
            LeadStatus convertedStatus=[SELECT Id, MasterLabel FROM LeadStatus WHERE isConverted=TRUE LIMIT 1];
            lc.setConvertedStatus(convertedStatus.MasterLabel);
            
            Database.LeadConvertResult lcr=Database.convertlead(lc);
            o=[SELECT Id FROM Opportunity WHERE Id =:lcr.getOpportunityId()];
            a=[SELECT Id FROM Account WHERE Id =:lcr.getAccountId()];
            c=[SELECT Id FROM Contact WHERE Id =:lcr.getContactId()];

        test.stopTest();
        
        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :contactPostsMigrated];
        OpportunityFeed[] opptyPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM OpportunityFeed WHERE parentId=:o.id];
        AccountFeed[] acctPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM AccountFeed WHERE parentId=:a.id];
        
        system.assertEquals(1, contactPostsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,contactPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(0, opptyPostsMigrated.size());
        system.assertEquals(0,acctPostsMigrated.size());    
    }//verifyExistingContact

   public static testmethod void verifyExistingAccount() {
        Boolean moveToAcct=TRUE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        Account acct=new Account();
        acct.name=company;
        insert acct;
        
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            Database.LeadConvert lc=new Database.LeadConvert();
            lc.setLeadId(l.id);
            lc.accountId=acct.Id;
            LeadStatus convertedStatus=[SELECT Id, MasterLabel FROM LeadStatus WHERE isConverted=TRUE LIMIT 1];
            lc.setConvertedStatus(convertedStatus.MasterLabel);
            
            Database.LeadConvertResult lcr=Database.convertlead(lc);
            o=[SELECT Id FROM Opportunity WHERE Id =:lcr.getOpportunityId()];
            a=[SELECT Id FROM Account WHERE Id =:lcr.getAccountId()];
            c=[SELECT Id FROM Contact WHERE Id =:lcr.getContactId()];

        test.stopTest();
        
        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :contactPostsMigrated];
        OpportunityFeed[] opptyPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM OpportunityFeed WHERE parentId=:o.id];
        AccountFeed[] acctPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM AccountFeed WHERE parentId=:a.id];
        FeedComment[] commentsMigrated2=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :acctPostsMigrated];
        
        system.assertEquals(1, contactPostsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,contactPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(0, opptyPostsMigrated.size());
        system.assertEquals(1,acctPostsMigrated.size());    
        system.assertEquals(2,commentsMigrated2.size());    
        system.assertEquals(1,acctPostsMigrated[0].getSObjects('feedLikes').size());

    }//verifyExistingAccount

   public static testmethod void verifyNoOppty() {
        Boolean moveToAcct=TRUE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=TRUE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        Account acct=new Account();
        acct.name=company;
        insert acct;
        
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        Boolean testFailed=FALSE;
        test.startTest();
            Database.LeadConvert lc=new Database.LeadConvert();
            lc.setLeadId(l.id);
            lc.accountId=acct.Id;
            LeadStatus convertedStatus=[SELECT Id, MasterLabel FROM LeadStatus WHERE isConverted=TRUE LIMIT 1];
            lc.setConvertedStatus(convertedStatus.MasterLabel);
            lc.doNotCreateOpportunity=TRUE;
            try{
                Database.LeadConvertResult lcr=Database.convertlead(lc);
                a=[SELECT Id FROM Account WHERE Id =:lcr.getAccountId()];
                c=[SELECT Id FROM Contact WHERE Id =:lcr.getContactId()];
            }catch(exception e){
                testFailed=TRUE;
            }
        test.stopTest();
        system.assertEquals(FALSE, testFailed);
        
        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :contactPostsMigrated];
        AccountFeed[] acctPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM AccountFeed WHERE parentId=:a.id];
        FeedComment[] commentsMigrated2=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :acctPostsMigrated];
        
        system.assertEquals(1, contactPostsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,contactPostsMigrated[0].getSObjects('feedLikes').size());
        system.assertEquals(1,acctPostsMigrated.size());    
        system.assertEquals(2,commentsMigrated2.size());    
        system.assertEquals(1,acctPostsMigrated[0].getSObjects('feedLikes').size());
    }//verifyNoOppty

    public static testmethod void verify1kBodyTextPost() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some inter';
        FeedItem f=createPost(body, l);
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] postsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :postsMigrated];
        
        system.assertEquals(1, postsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,postsMigrated[0].getSObjects('feedLikes').size());
    }//verify1kBodyTextPost

    public static testmethod void verify1kBodyLinkPost() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some inter';
        FeedItem f=createLinkPost(body, l);
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] postsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :postsMigrated];
        
        system.assertEquals(1, postsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,postsMigrated[0].getSObjects('feedLikes').size());
    }//verify1kBodyLinkPost

    public static testmethod void verify1kBodyFilePost() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        insert l;
        String body='Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some interesting information in me. Im a great post with some inter';
        FeedItem f=createFilePost(body, l);
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
            convertLead(l);
        test.stopTest();
        
        ContactFeed[] postsMigrated=[SELECT Id, body, RelatedRecordId, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :postsMigrated];
        
        system.assertEquals(1, postsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,postsMigrated[0].getSObjects('feedLikes').size());
		system.assertNotEquals(null,postsMigrated[0].relatedRecordId);
    }//verify1kBodyFilePost
/*
    public static testmethod void verifyLeadToContactMerge() {
        Boolean moveToAcct=FALSE;
        Boolean moveToContact=TRUE;
        Boolean moveToOppty=FALSE;
        setSettings(moveToAcct, moveToContact,moveToOppty);
        
        String lastName='Smith';
        String company='Acme';
        Lead l=createLead(lastName,company);
        Lead l2=createLead(lastName,company);
        insert l;
        insert l2;
/*        Account acct=new Account();
        acct.name=company;
        insert acct;
        
        Contact con=new Contact();
        con.lastName=lastName;
        con.accountId=acct.Id;
        
        insert con;
////
        String body='Im a great post with some interesting information in me.';
        FeedItem f=createPost(body, l);
        body='Im a comment.  Im sick of being shackled to this lead though.  I want to get out and explore the world!';
        FeedComment fc=createComment(body, f);
        FeedComment fc2=createComment(body, f);
        FeedLike fl=createLike(f.Id,f.Id);
        FeedLike fcl=createLike(fc.Id,f.Id);
        FeedLike fcl2=createLike(fc2.Id,f.Id);
        
        test.startTest();
/*        	Id conId=con.Id;
        	Id leadId=l.Id;
			MergeRequest m=new MergeRequest();
			m.setMasterRecord(conId);
			m.setRecordToMergeIds(leadId);
			MergeResult mres=merge(m);
/////			
			merge l2 l;
        test.stopTest();
        
        LeadFeed[] leadPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM LeadFeed WHERE parentId=:l2.id];
        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :leadPostsMigrated];

//        ContactFeed[] contactPostsMigrated=[SELECT Id, body, (SELECT Id FROM FeedLikes) FROM ContactFeed WHERE parentId=:c.id];
//        FeedComment[] commentsMigrated=[SELECT Id, commentBody FROM FeedComment WHERE feedItemId IN :contactPostsMigrated];
        
        system.assertEquals(1, leadPostsMigrated.size());
        system.assertEquals(2,commentsMigrated.size());    
        system.assertEquals(1,leadPostsMigrated[0].getSObjects('feedLikes').size());
    }//verifyLeadToContactMerge
*/
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
        o=[SELECT Id FROM Opportunity WHERE Id =:lcr.getOpportunityId()];
        a=[SELECT Id FROM Account WHERE Id =:lcr.getAccountId()];
        c=[SELECT Id FROM Contact WHERE Id =:lcr.getContactId()];
//      system.assertEquals(TRUE, lcr.isSuccess());
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
        
    public static void setSettings(Boolean acct, Boolean con, Boolean oppty){
        Map<String,LeadConvertChatter__c> newParentSetting=LeadConvertChatter__c.getAll();
        delete newParentSetting.values();
        LeadConvertChatter__c newSettings=new LeadConvertChatter__c();
        newSettings.name='default';
        newSettings.Account__c=acct;
        newSettings.Contact__c=con;
        newSettings.Opportunity__c=oppty;
        insert newSettings;
    }//setSettings

}//leadConvertChatterTests