import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttershare/models/user.dart';
import 'package:fluttershare/pages/home.dart';
import 'package:fluttershare/widgets/progress.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;

  Upload({this.currentUser});

  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> with AutomaticKeepAliveClientMixin<Upload>{
  var locationController = TextEditingController();
  var captionController = TextEditingController();
  File file;
  bool isLoading = false;
  String postId = Uuid().v4();

  handleTakePhoto() async{
    Navigator.pop(context);
    var file = await ImagePicker.pickImage(source: ImageSource.camera,
      maxHeight: 675,
      maxWidth: 960
    );
    setState(() {
      this.file = file;
    });
  }

  handleSelectPhoto() async{
    Navigator.pop(context);
    var file = await ImagePicker.pickImage(source: ImageSource.gallery,
      maxHeight: 675,
      maxWidth: 960
    );
    setState(() {
      this.file = file;
    });
  }

  selectImage(context) {
      return showDialog(context: context, builder: (ctx) {
        return SimpleDialog(
          title: Text('Create Post'),
          children: [
            SimpleDialogOption(
              child: Text('Camera'),
              onPressed: handleTakePhoto,
            ),
            SimpleDialogOption(
              child: Text('Gallery'),
              onPressed: handleSelectPhoto,
            ),
            SimpleDialogOption(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(ctx),
            )
          ],
        );
      });
  }

  buildSplashScreen() {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'New Post',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                fontSize: 30
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.indigo
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              child: Text('Upload Image', style: TextStyle(
                color: Colors.white,
                fontSize: 18
              ),
              ),
              onPressed: () => selectImage(context),
            ),
          )
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      file = null;
    });
  }

  compressImage() async {
    final tempDir = await getTemporaryDirectory();
    final path = tempDir.path;
    Im.Image imageFile = Im.decodeImage(file.readAsBytesSync());
    final compressedImage = File(
        '$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imageFile, quality: 75));
    setState(() {
      file = compressedImage;
    });
  }

  uploadImage(imageFile) async {
    StorageUploadTask uploadTask =
    storageRef.child("post_$postId.jpg").putFile(imageFile);
    StorageTaskSnapshot storageSnap = await uploadTask.onComplete;
    var downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostInFirestore({ mediaUrl, location, description}) {
    postsRef
        .document(widget.currentUser.id)
        .collection("userPosts")
        .document(postId)
        .setData({
          'postId': postId,
          'ownerId': widget.currentUser.id,
          'username': widget.currentUser.username,
          'mediaUrl': mediaUrl,
          'description': description,
          'location': location,
          'timestamp': timestamp,
          'likes': {}
        });
  }

  handleSubmit() async{
    setState(() {
      isLoading = true;
    });
    await compressImage();
    var mediaUrl = await uploadImage(file);
    createPostInFirestore(
      mediaUrl: mediaUrl,
      location: locationController.text,
      description: captionController.text
    );
    captionController.clear();
    locationController.clear();
    setState(() {
      file = null;
      isLoading = false;
      postId = Uuid().v4();
    });
  }

  buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.black,
          onPressed: clearImage,
        ),
        title: Text(
          'Caption',
          style: TextStyle(
            color: Colors.black
          ),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : () => handleSubmit(),
            child: Text(
              'Post',
              style: TextStyle(
                color: Colors.indigoAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18
              ),
            ),
          )
        ],
      ),
      body: ListView(
        children: [
          isLoading ? linearProgress() : Text(''),
          Container(
            height: 220,
            width: MediaQuery.of(context).size.width*0.8,
            child: Center(
              child: AspectRatio(
                aspectRatio: 16/9,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(file)
                    )
                  ),
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 10)),
          ListTile(
            leading: CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                widget.currentUser.photoUrl
              ),
            ),
            title: Container(
              width: 250,
              child: TextField(
                controller: captionController,
                decoration: InputDecoration(
                  hintText: 'Caption',
                  border: InputBorder.none
                ),
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.pin_drop_rounded, color: Colors.orange, size: 30,),
            title: Container(
              width: 250,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                  hintText: 'Location',
                  border: InputBorder.none
                ),
              ),
            ),
          ),
          Container(
            width: 200,
            height: 100,
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                    Colors.blue
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              onPressed: getUserLocation,
              icon: Icon(Icons.my_location_outlined, color: Colors.white,),
              label: Text('Use Current Location', style: TextStyle(color: Colors.white),)
            ),
          )
        ],
      ),
    );
  }

  getUserLocation() async {
    var position =
      await Geolocator()
          .getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    var placemarks = await Geolocator()
        .placemarkFromCoordinates(position.latitude, position.longitude);
    var placemark = placemarks[0];
    var finalAddress =
        '${placemark.locality}, '
        '${placemark.administrativeArea}, '
        '${placemark.country}';
    // print(finalAddress);
    locationController.text = finalAddress;
  }

  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return file == null ? buildSplashScreen() : buildUploadForm();
  }
}
