import 'package:flutter/material.dart';
import 'package:fluttershare/pages/home.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colance',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        accentColor: Colors.indigoAccent
      ),
      home: Home(),
    );
  }
}
