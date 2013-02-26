public with sharing class LeadConvertChatter{
    
    public static Boolean movePostsCommentsLikes(Map<Id,Id> newPostParent, LeadFeed[] posts){
        Boolean success=TRUE;
        
        FeedItem[] newPosts = new FeedItem[] {};
        FeedComment[] newComments = new FeedComment[] {};
        FeedLike[] newLikes = new FeedLike[] {};
        
        List<FeedComment[]> commentArray = new List<FeedComment[]> ();
        List<FeedLike[]> likeArray = new List<FeedLike[]> ();

        for(LeadFeed oldPost:posts){
            FeedItem newPost=new FeedItem();
            //Truncate the last 20char of really long posts
            if(oldPost.body!=null){
            	String oldBody=oldPost.body.length()>980?oldPost.body.substring(0,980):oldPost.body;
            	newPost.Body='Converted Lead Post: '+oldBody;
            }else{
            	//links & files can exist without a body
            	newPost.Body='Converted Lead Post';
            }
            newPost.ParentId=newPostParent.get(oldPost.parentId);
            newPost.createdById=oldPost.insertedById;
            newPost.createddate = oldPost.createdDate;
			 newPost.type=oldPost.type;
			 
			//for files
            if(oldPost.RelatedRecordId!=null)
            	newPost.relatedRecordId = oldPost.relatedRecordId;

            if(oldPost.linkUrl!=null){
        	    newPost.linkURL = oldPost.linkURL;
                newPost.title = oldPost.title;
            }//if 1
	//        	        if(urlLink != null && urlLink.contains(' '))
	//                	    urlLink = urlLink.replace(' ','%20');
	
            if( newPost.type == 'ContentPost' && newPost.relatedRecordID == null )
                newPost.type = 'TextPost';

            if( oldPost.body == null ) {
                if( newPost.type == 'LinkPost' )
                    newPost.body = 'posted a link.';
                else
                    newPost.body = 'posted a file.';
            }//if 1
                    
            newPosts.add(newPost);

        	FeedComment[] comments = new FeedComment[] {};
            if( oldPost.CommentCount>0 ) {
                for( FeedComment fc : oldPost.getSObjects('feedcomments') ) {
                    FeedComment newFC = new FeedComment();
                    newFC.createdbyid = fc.createdbyid;
                    newFC.commentbody = fc.commentbody;
                    newFC.createddate = fc.createddate;
                        
                    comments.add( newFC );
                }//for 2
            }//if 1
            commentArray.add( comments );

            FeedLike[] likes = new FeedLike[] {};
            if( oldPost.LikeCount>0) {
                for( FeedLike fl : oldPost.getSObjects('feedlikes')) {
                    FeedLike newFL = new FeedLike();
                    newFL.createdbyid = fl.createdbyid;
                        
                    likes.add( newFL );
                }//for 2
            }//if 1
	                        
            likeArray.add( likes );
        }//for 1
		
        Boolean postsInserted=FALSE;
        if(newPosts.size()>0){
            try{
                insert newPosts;
                postsInserted=TRUE;
            }catch (DMLException e){
                system.debug('The posts werent inserted properly: '+e);
                success=FALSE;
                return success;
            }//try
        }//if 3	            

        Id[] fpIds = new Id[] {};
        // Move comments and likes to their new parents
        for( integer x = 0; x < newPosts.size(); x++ ) {
            for( FeedComment fc : commentArray.get( x ) ) {
                fc.feedItemId = newPosts.get(x).id;
                newComments.add( fc );
            }//for 3
            
            for( FeedLike fl : likeArray.get( x ) ) {
                fl.feedItemId = newPosts.get(x).id;
                newLikes.add( fl );
            }//for 3   
        }//for 2
	                
        try {
            insert newComments;
        } catch( Exception e ) {
            system.debug('The comments werent inserted: '+e);
            success=FALSE;
        }//try
            
        try {
            insert newLikes;
        } catch( Exception e ) {
            system.debug('The likes werent inserted: '+e);
            success=FALSE;
        }//try    

		return success;
    }//moveLeadConvertChatter
    
    
}//LeadConvertChatter