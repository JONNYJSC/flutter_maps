import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_maps/pages/home/index.dart';
import 'package:flutter_maps/pages/splash.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SplashPage(),
      routes: {
        'home': (_) => HomePage(),
      },
    );
  }
}
