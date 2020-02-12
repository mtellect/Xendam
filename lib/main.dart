import 'package:credpal/Landing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ravepay/ravepay.dart';

import 'MainHomePg.dart';
import 'app/baseApp.dart';
import 'app/navigationUtils.dart';
import 'rave/RaveApi.dart';

var raveApi = RaveApi(
    liveMode: true,
    liveEncKey: "fd4172f2b7fc4ea54666c712",
    testEncKey: "fd4172f2b7fc4ea54666c712",
    liveSecKey: "FLWSECK-d8cb090bc6edeb52da7a5772cbbe8f29-X",
    testSecKey: "FLWSECK-fd4172f2b7fc2935adbf67e8e60d6dbc-X",
    livePubKey: "FLWPUBK-700ffcdaff4cb60ef07ecfc384be2aff-X",
    testPubKey: "FLWPUBK-9768585b355bc716fd3343688a0df49b-X");

void main() {
  Ravepay.init(
      production: true,
      publicKey: "FLWPUBK-700ffcdaff4cb60ef07ecfc384be2aff-X",
      secretKey: "FLWSECK-d8cb090bc6edeb52da7a5772cbbe8f29-X");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xendam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.purple, fontFamily: "Lato"),
      home: AppSetter(),
    );
  }
}

class AppSetter extends StatefulWidget {
  @override
  _AppSetterState createState() => _AppSetterState();
}

class _AppSetterState extends State<AppSetter>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;
  Animation _animation;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkUser();
    setUpAnimation();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  setUpAnimation() {
    _animationController = new AnimationController(
        vsync: this, duration: Duration(milliseconds: 800));
    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeInCirc));
    _animationController.forward();
  }

  checkUser() async {
    FirebaseUser user = await FirebaseAuth.instance.currentUser();
    if (mounted) {
      await Future.delayed(Duration(milliseconds: 1500), () async {
        if (user == null) {
          popUpWidgetScreenUntil(context, Landing());
        } else {
          popUpWidgetScreenUntil(context, MainHomePg());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: FadeTransition(
        opacity: _animation,
        child: loadingLayout(),
      ),
    );
  }
}
