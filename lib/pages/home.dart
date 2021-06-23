import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/create_account.dart';
import 'package:fluttershare/pages/profile.dart';
import 'package:fluttershare/pages/search.dart';
import 'package:fluttershare/pages/timeline.dart';
import 'package:fluttershare/pages/upload.dart';
import 'package:google_sign_in/google_sign_in.dart';

final googleSignIn = GoogleSignIn();
final StorageReference storageRef = FirebaseStorage.instance.ref();
final usersRef = Firestore.instance.collection('users');
final postsRef = Firestore.instance.collection('posts');
final commentsRef = Firestore.instance.collection('comments');
final activityFeedRef = Firestore.instance.collection('feed');
final followersRef = Firestore.instance.collection('followers');
final followingRef = Firestore.instance.collection('following');
final timelineRef = Firestore.instance.collection('timeline');
final timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool isAuth = false;
  PageController pageController;
  var pageIndex = 0;

  @override
  void initState() {
    super.initState();
    pageController = PageController();
    googleSignIn.onCurrentUserChanged.listen((event) {
      handleSignIn(event);
    }, onError: (error) {
      // print(error);
    });
    googleSignIn.signInSilently(suppressErrors: false)
      .then((value) {
        handleSignIn(value);
      }).catchError((err) {
        // print(err);
      });
  }

  handleSignIn(event) async {
    if (event != null) {
      await createUserInFirestore();
      setState(() {
        isAuth = true;
      });
      configurePushNotification();
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  configurePushNotification() {
    final user = googleSignIn.currentUser;

    _firebaseMessaging.getToken().then((token) {
      usersRef
      .document(user.id)
          .updateData({
        'androidNotificationToken': token
      });
    });

    _firebaseMessaging.configure(
      onLaunch: (message) async {},
      onResume: (message) async {},
      onMessage: (message) async {
        final String recipientId = message['data']['recipient'];
        final String body = message['notification']['body'];
        if(recipientId == user.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              key: _scaffoldKey,
              content: Text(body, overflow: TextOverflow.ellipsis,),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    );

  }

  createUserInFirestore() async {
    final user = googleSignIn.currentUser;
    var doc = await usersRef.document(user.id).get();

    if(!doc.exists) {
      final username = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CreateAccount())
      );
      usersRef.document(user.id).setData({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp
      });
      await followersRef
        .document(user.id)
        .collection('userFollowers')
        .document(user.id)
        .setData({});

      doc = await usersRef.document(user.id).get();
    }
    currentUser = User.fromDocument(doc);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googleSignIn.signIn();
  }

  logout() {
    googleSignIn.signOut();
  }

  onPageChanged(pageIndex) {
    setState(() {
      this.pageIndex = pageIndex;
    });
  }

  onTap(pageIndex) {
    pageController.animateToPage(
      pageIndex,
      duration: Duration(milliseconds: 150),
      curve: Curves.easeIn
    );
  }

  buildAuthScreen() {
    // return ElevatedButton(
    //     onPressed: logout,
    //     child: Text('Logout')
    // );
    return Scaffold(
      key: _scaffoldKey,
      body: PageView(
        children: [
          Timeline(currentUser: currentUser),
          Search(),
          Upload(currentUser: currentUser),
          ActivityFeed(),
          Profile(profileId: currentUser?.id)
        ],
        controller: pageController,
        onPageChanged: onPageChanged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageIndex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined)),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded)),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline, size: 35,)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active_outlined)),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle_outlined))
        ],
      ),
    );
  }

  buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
              Colors.teal,
              Colors.purple,
              Colors.indigo,
            ])),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Colance',
              style: TextStyle(
                  fontFamily: "Signatra", fontSize: 90, color: Colors.white),
            ),
            GestureDetector(
              onTap: () => login(),
              child: Container(
                width: 260,
                height: 60,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(
                            'assets/images/google_signin_button.png'),
                        fit: BoxFit.cover)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthScreen() : buildUnAuthScreen();
  }
}
