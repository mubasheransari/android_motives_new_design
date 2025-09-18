import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

toastWidget(String text, Color color,) {
  Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 2,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 14.0);
}
