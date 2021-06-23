import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/edit_profile.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/post_tile.dart';
import 'package:fluttershare/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;

  Profile({this.profileId});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  final currentUserId = currentUser?.id;
  String postOrientation = 'list';
  var isLoading = false;
  var postCount = 0;
  var followerCount = 0;
  var followingCount = 0;
  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    getProfilePosts();
    getFollowers();
    getFollowing();
    checkIfFollowing();
  }

  checkIfFollowing() async {
    DocumentSnapshot doc = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get();
    setState(() {
      isFollowing = doc.exists;
    });
  }

  getFollowers()  async {
    QuerySnapshot snapshot = await followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .getDocuments();
    setState(() {
      followerCount = snapshot.documents.length;
    });
  }

  getFollowing() async {
    QuerySnapshot snapshot = await followingRef
        .document(widget.profileId)
        .collection('userFollowing')
        .getDocuments();
    setState(() {
      followingCount = snapshot.documents.length;
    });
  }

  getProfilePosts() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .document(widget.profileId)
        .collection('userPosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();
    setState(() {
      isLoading = false;
      postCount = snapshot.documents.length;
      posts = snapshot.documents.map((doc) => Post.fromDocument(doc))
        .toList();
    });
  }

  buildCountColumn(label, count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold
          ),
        ),
        Container(
          margin: EdgeInsets.only(top: 4),
          child: Text(
            label,
            style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w400
            ),
          ),
        )
      ],
    );
  }

  editProfile() {
    Navigator.push(context, MaterialPageRoute(builder: (context) =>
      EditProfile(currentUserId: currentUserId)
    ));
  }

  buildButton({ text, function}) {
    return Container(
      padding: EdgeInsets.only(top: 2),
      child: TextButton(
        onPressed: function,
        child: Container(
          width: 250,
          height: 27,
          child: Text(
            text,
            style: TextStyle(
              color: isFollowing ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold
            ),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.indigo,
            border: Border.all(
              color: isFollowing ? Colors.grey : Colors.indigo
            ),
            borderRadius: BorderRadius.circular(5)
          ),
        ),
      ),
    );
  }

  buildProfileButton() {
    bool isProfileOwner = currentUserId == widget.profileId;
    if(isProfileOwner) {
      return buildButton(
        text: 'Edit Profile',
        function: editProfile
      );
    } else if(isFollowing){
      return buildButton(
        text: 'Unfollow',
        function: handleUnfollow
      );
    } else if(!isFollowing) {
      return buildButton(
        text: 'Follow',
        function: handleFollow
      );
    }
  }

  handleFollow() {
    setState(() {
      isFollowing = true;
    });
    followersRef
      .document(widget.profileId)
      .collection('userFollowers')
      .document(currentUserId)
      .setData({});
    followingRef
      .document(currentUserId)
      .collection('userFollowing')
      .document(widget.profileId)
      .setData({});
    activityFeedRef
      .document(widget.profileId)
      .collection('feedItems')
      .document(currentUserId)
      .setData({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': currentUserId,
      'userProfileImg': currentUser.photoUrl,
      'timestamp': timestamp
    });
  }

  handleUnfollow() {
    setState(() {
      isFollowing = false;
    });
    followersRef
        .document(widget.profileId)
        .collection('userFollowers')
        .document(currentUserId)
        .get().then((doc) {
          if(doc.exists) {
            doc.reference.delete();
          }
    });
    followingRef
        .document(currentUserId)
        .collection('userFollowing')
        .document(widget.profileId)
        .get().then((doc) {
          if(doc.exists) {
            doc.reference.delete();
          }
        });
    activityFeedRef
        .document(widget.profileId)
        .collection('feedItems')
        .document(currentUserId)
        .get().then((doc) {
      if(doc.exists) {
        doc.reference.delete();
      }
    });
  }

  buildProfileHeader() {
    return FutureBuilder(
      future: usersRef.document(widget.profileId).get(),
      builder: (context, snapshot) {
        if(!snapshot.hasData) {
          return circularProgress();
        }
        var user = User.fromDocument(snapshot.data);
        return Padding(
          padding:EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildCountColumn('posts', postCount),
                            buildCountColumn('followers', followerCount),
                            buildCountColumn('following', followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            buildProfileButton()
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  user.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                  ),
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  user.displayName,
                ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  user.bio
                ),
              )
            ],
          ),
        );
      },
    );
  }

  buildProfilePosts() {
    if(isLoading) return circularProgress();
    else if(posts.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.teal.withOpacity(0.9),
                  Colors.purple.withOpacity(0.9),
                  Colors.indigo.withOpacity(0.9),
                ]
            )
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No Posts',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  fontSize: 30
              ),
            ),
          ],
        ),
      );
    }
    else if(postOrientation == 'grid') {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(child: PostTile(post)));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == 'list') {
      return Column(
        children: posts,
      );
    }
  }

  setPostsOrientation(orientation) {
    setState(() {
      this.postOrientation = orientation;
    });
  }

  buildTogglePost() {
    if(posts.isEmpty) return Text('');
    else
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          onPressed: () => setPostsOrientation('grid'),
          icon: Icon(Icons.grid_on),
          color: postOrientation == 'grid' ? Theme.of(context).primaryColor :
          Colors.grey,
        ),
        IconButton(
          onPressed: () => setPostsOrientation('list'),
          icon: Icon(Icons.list_alt),
          color: postOrientation == 'list' ? Theme.of(context).primaryColor :
          Colors.grey,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigoAccent,
        centerTitle: true,
        title: Text('Profile'),
        actions: [
          IconButton(
            onPressed: () => googleSignIn.signOut(),
            icon: Icon(Icons.exit_to_app_outlined)
          )
        ],
      ),
      body: ListView(
        children: [
          buildProfileHeader(),
          Divider(),
          buildTogglePost(),
          Divider(
            height: 0.0,
          ),
          buildProfilePosts()
        ],
      ),
    );
  }
}
