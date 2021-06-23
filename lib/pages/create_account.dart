import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluttershare/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  String username;

  submit() {
    final form = _formKey.currentState;
    FocusScope.of(context).unfocus();
    if(form.validate()) {
      form.save();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:Text('Welcome $username'),
          duration: Duration(seconds: 2),
        ),
      );
      Timer(Duration(seconds: 2),  () {
        Navigator.pop(context, username);
      });
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: header(context, titleText: 'New Profile'),
      body: ListView(
        children: [
          Container(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 25),
                  child: Text('Create a username', style: TextStyle(
                    fontSize: 25
                  ),),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    child: Form(
                      autovalidateMode: AutovalidateMode.always, key: _formKey,
                      child: TextFormField(
                        validator: (val) {
                          if(val.trim().length < 3 || val.isEmpty) {
                            return 'Username too short';
                          } else if(val.trim().length > 12) {
                            return 'Username too long';
                          } else {
                            return null;
                          }
                        },
                        onSaved: (val) => username = val,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Username',
                          labelStyle: TextStyle(fontSize: 15),
                          hintText: 'Must be more than 3 characters long',
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 50,
                    width: 350,
                    child: Center(
                      child: Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.indigoAccent,
                      borderRadius: BorderRadius.circular(7)
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
