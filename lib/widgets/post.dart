import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/comments.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/custom_image.dart';
import 'package:fluttershare/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;

  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });

  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }

  int getLikeCount(likes) {
    if(likes == null) return 0;
    var count = 0;
    likes.values.forEach((val) {
      if(val) count++;
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
    postId: this.postId,
    ownerId: this.ownerId,
    username: this.username,
    location: this.location,
    description: this.description,
    mediaUrl: this.mediaUrl,
    likes: this.likes,
    likeCount: getLikeCount(this.likes)
  );
}

class _PostState extends State<Post> {
  final String currentUserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  int likeCount;
  Map likes;
  bool isLiked = false;
  bool showHeart = false;

  _PostState({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
    this.likeCount
  });

  buildPostHeader() {
    return FutureBuilder(
      future: usersRef.document(ownerId).get(),
      builder: (context, snapshot) {
        if(!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromDocument(snapshot.data);
        bool isPostOwner = ownerId == currentUserId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner ? IconButton(
            onPressed: () => handleDeletePost(context),
            icon: Icon(Icons.more_vert),
          ) : Text(''),
        );
      },
    );
  }

  handleDeletePost(context) {
    return showDialog(
      context: context,
      builder: (ctx) {
        return SimpleDialog(
          title: Text('Remove this post?'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                deletePost();
              },
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Colors.red
                ),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel'),
            )
          ],
        );
      }
    );
  }

  deletePost() async {
    postsRef
      .document(ownerId)
      .collection('userPosts')
      .document(postId)
      .get().then((doc) {
        if(doc.exists) {
          doc.reference.delete();
        }
    });
    storageRef.child('post_$postId.jpg').delete();

    QuerySnapshot activityFeedSnapshot = await activityFeedRef
      .document(ownerId)
      .collection('feedItems')
      .where('postId', isEqualTo: postId)
      .getDocuments();

    activityFeedSnapshot.documents.forEach((doc) {
      if(doc.exists) {
        doc.reference.delete();
      }
    });

    QuerySnapshot commentsSnapshot = await commentsRef
      .document(postId)
      .collection('comments')
      .getDocuments();

    commentsSnapshot.documents.forEach((doc) {
      if(doc.exists) {
        doc.reference.delete();
      }
    });
  }

  handleLikePost() {
    bool _isLiked = likes[currentUserId] == true;

    if(_isLiked) {
      postsRef
        .document(ownerId)
        .collection('userPosts')
        .document(postId)
        .updateData({'likes.$currentUserId' : false});
      removeLikeFromActivityFeed();
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentUserId] = false;
      });
    } else if(!_isLiked) {
      postsRef
          .document(ownerId)
          .collection('userPosts')
          .document(postId)
          .updateData({'likes.$currentUserId' : true});
      addLikeToActivityFeed();
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentUserId] = true;
        showHeart = true;
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showHeart = false;
        });
      });
    }
  }

  addLikeToActivityFeed() {
    bool isNotPostOwner = currentUserId != currentUserId;
    if(isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .setData({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImg': currentUser.photoUrl,
        'postId': postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp
      });
    }
  }

  removeLikeFromActivityFeed() {
    bool isNotPostOwner = currentUserId != currentUserId;
    if(isNotPostOwner) {
      activityFeedRef
          .document(ownerId)
          .collection('feedItems')
          .document(postId)
          .get().then((doc) {
        if(doc.exists) {
          doc.reference.delete();
        }
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikePost,
      child: Stack(
        alignment: Alignment.center,
        children: [
          cachedNetworkImage(mediaUrl),
          showHeart ? Icon(
            Icons.favorite,
            size: 80,
            color: Colors.red.withOpacity(0.6),
          ) : Text('')
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 40, left: 10),
            ),
            GestureDetector(
              onTap: handleLikePost,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_outline,
                size: 28,
                color: Colors.pink,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 40, right: 20),
            ),
            GestureDetector(
              onTap: () => showComments(
                context,
                postId: postId,
                ownerId: ownerId,
                mediaUrl: mediaUrl
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 28,
                color: Colors.indigoAccent,
              ),
            )
          ],
        ),
        Row(
          children: [
            Container(
              margin: EdgeInsets.only(left: 10),
              child: Text(
                '$likeCount likes',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold
                ),
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 10),
              child: Text(
                '$username ',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
            Expanded(child: Text(description))
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentUserId] == true);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
        Divider()
      ],
    );
  }
}

showComments(BuildContext context, { postId, ownerId, mediaUrl }) {
  Navigator.push(context, MaterialPageRoute(builder: (context) {
    return Comments(
      postId: postId,
      postOwnerId: ownerId,
      postMediaUrl: mediaUrl
    );
  }));
}
