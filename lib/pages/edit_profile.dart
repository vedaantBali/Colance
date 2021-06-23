import 'package:cached_network_image/cached_network_image.dart';
import "package:flutter/material.dart";
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({this.currentUserId});

  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  var displayNameController = TextEditingController();
  var bioController = TextEditingController();
  bool isLoading = false;
  User user;
  var _bioValid = true;
  var _displayNameValid = true;

  @override
  void initState() {
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    var doc = await usersRef.document(widget.currentUserId).get();
    user = User.fromDocument(doc);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Display Name', style: TextStyle(
            color: Colors.grey
          ),),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
            hintText: 'Update Display Name',
            errorText: _displayNameValid ? null : 'Display Name too short'
          ),
        )
      ],
    );
  }

  buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Bio', style: TextStyle(
              color: Colors.grey
          ),),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
            hintText: 'Update Bio',
            errorText: _bioValid ? null : 'Bio too long'
          ),
        )
      ],
    );
  }

  updateProfileData(context) {
    setState(() {
      displayNameController.text.trim().length < 3 ||
      displayNameController.text.isEmpty ? _displayNameValid = false :
          _displayNameValid = true;
      bioController.text.trim().length > 100 ? _bioValid = false :
          _bioValid = true;
    });
    FocusScope.of(context).unfocus();
    if(_displayNameValid && _bioValid) {
      usersRef.document(widget.currentUserId).updateData({
        'displayName': displayNameController.text,
        'bio': bioController.text
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        title: Text('Edit Profile', style: TextStyle(
          color: Colors.black
        ),),
        actions: [
          IconButton(
            icon: Icon(Icons.done, color: Colors.green,),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: isLoading ? circularProgress() : 
      ListView(
        children: [
          Container(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 16, bottom: 8),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildDisplayNameField(),
                      buildBioField()
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    updateProfileData(context);
                  },
                  child: Text(
                    'Update Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                    ),
                  )
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
