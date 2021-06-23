import 'package:flutter/material.dart';

header(context, { isAppTitle = false , titleText, removeBackButton = false}) {
  return AppBar(
    automaticallyImplyLeading: removeBackButton ? false : true,
    title: Text(
      isAppTitle ? 'Colance' : titleText,
      style: TextStyle(
        color: Colors.white,
        fontFamily: isAppTitle ?  "Signatra" : "",
        fontSize: isAppTitle? 35 : 20
      ),
      overflow: TextOverflow.ellipsis,
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
  );
}
