import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/activity_feed.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search>  with AutomaticKeepAliveClientMixin<Search>{
  var searchController = TextEditingController();
  Future<QuerySnapshot> searchResultsFuture;

  handleSearch(query) {
    var users = usersRef.where('username', isGreaterThanOrEqualTo: query)
        .getDocuments();
    setState(() {
      searchResultsFuture = users;
    });
  }

  clearSearch() {
    searchController.clear();
  }

  buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search Users',
          filled: true,
          prefixIcon: Icon(Icons.account_circle_outlined, size: 28,),
          suffixIcon: IconButton(
            icon: Icon(Icons.clear_rounded),
            onPressed: clearSearch,
          )
        ),
        onChanged: handleSearch,
      ),
    );
  }

  buildNoContent() {
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Find Users',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 30
              ),
            )
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
      future: searchResultsFuture,
      builder: (context, snapshot) {
        if(!snapshot.hasData) {
          return circularProgress();
        }
        List<UserResult> searchResults = [];
        snapshot.data.documents.forEach((doc) {
          var user = User.fromDocument(doc);
          var searchResult = UserResult(user);
          searchResults.add(searchResult);
        });
        return ListView(
          children: searchResults,
        );
      },
    );
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: buildSearchField(),
        body: searchResultsFuture == null ? buildNoContent() : buildSearchResults(),
      ),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;

  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Container(
          color: Colors.black54,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => showProfile(context, profileId: user.id),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                    backgroundColor: Colors.grey,
                  ),
                  title: Text(
                    user.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  subtitle: Text(
                    user.username,
                    style: TextStyle(
                      color: Colors.white
                    ),
                  ),
                ),
              ),
              Divider(
                height: 2.0,
                color: Colors.white54,
              )
            ],
          ),
        ),
      ),
    );
  }
}
