import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/widgets/header.dart';
import 'package:fluttershare/widgets/post.dart';
import 'package:fluttershare/widgets/progress.dart';

final usersRef = Firestore.instance.collection('users');

class Timeline extends StatefulWidget {
  final User currentUser;

  Timeline({ this.currentUser });

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  List<String> followingList = [];

  @override
  void initState() {
    super.initState();
    getTimeline();
    getFollowing();
  }

  getFollowing() async {
    var snapshot = await followingRef
        .document(currentUser.id)
        .collection('userFollowing')
        .getDocuments();

    setState(() {
      followingList = snapshot.documents.map((doc) => doc.documentID).toList();
    });
  }

  getTimeline() async {
    QuerySnapshot snapshot = await timelineRef
        .document(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .getDocuments();

    List<Post> posts = snapshot
        .documents.map((doc) => Post.fromDocument(doc)).toList();

    setState(() {
      this.posts = posts;
    });
  }

  buildTimeline() {
    if(posts == null) {
      return circularProgress();
    } else if(posts.isEmpty) {
      return buildUsersToFollow();
    }
    return ListView(
      children: posts,
    );
  }

  buildUsersToFollow() {
    return StreamBuilder(
      stream: usersRef
          .orderBy('timestamp', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if(!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> userResults = [];
        snapshot.data.documents.forEach((doc) {
          User user = User.fromDocument(doc);
          final bool isAuthUser = currentUser.id == user.id;
          final bool isFollowingUser = followingList.contains(user.id);
          if(isAuthUser) {
            return;
          } else if (isFollowingUser) {
            return;
          } else {
            var userResult = UserResult(user);
            userResults.add(userResult);
          }
        });
        return Container(
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
            children: [
              Container(
                padding: EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_outlined,
                      color: Colors.indigo,
                      size: 30,
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Text(
                      'Users to follow',
                      style: TextStyle(
                          color: Colors.indigo,
                          fontSize: 30
                      ),
                    )
                  ],
                ),
              ),
              Column(
                children: userResults,
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isAppTitle: true),
      body: RefreshIndicator(
        onRefresh: () => getTimeline(),
        child: buildTimeline(),
      ),
    );
  }
}
