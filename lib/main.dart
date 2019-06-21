import 'package:flutter/material.dart';

import 'page/home_page.dart' show HomePage;

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'reader',
      theme: ThemeData.light().copyWith(
        primaryColor: Color(0xff303030),
      ),
      home: HomePage(),
    ),
  );
}
