import 'dart:async';
import 'dart:math';

import 'package:credpal/app/AppEngine.dart';
import 'package:credpal/app/assets.dart';
import 'package:credpal/auth/AuthLogin.dart';
import 'package:credpal/auth/AuthSignUp.dart';
import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';

import 'app/baseApp.dart';

class Landing extends StatefulWidget {
  @override
  _LandingState createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  List<int> activeProduct = [];
  Timer timer;
  int maxSize = 24;

  final vp = PageController();
  int currentPage = 0;
  int vpSize = 4;

  bool reversing = false;

  List<LandHolder> data = [
    LandHolder(
        image: "assets/images/family.jpg",
        title: "Banking Simplified",
        value: "Xendam gives you a whole new world of internet banking."),
    LandHolder(
        image: "assets/images/farm.jpg",
        title: "Investment Simplified",
        value: "Secured investment opportunities with farmers"),
    LandHolder(
        image: "assets/images/money.jpg",
        title: "Saving Simplified",
        value: "Gives you flexible saving options to suit suit your goals"),
    LandHolder(
        image: "assets/images/banking.jpg",
        title: "Sending Simplified",
        value: "Stressfree funds transfer local and abroad easy and faster"),
  ];

  @override
  initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    super.initState();
    opacityUpdater();
  }

  @override
  dispose() {
    super.dispose();
    timer?.cancel();
  }

  opacityUpdater() {
    timer = Timer.periodic(Duration(seconds: 5), (_) {
      if (mounted)
        setState(() {
          activeProduct.clear();
        });
      List<int> contains = activeProduct;
      var rand = Random();
      int p = rand.nextInt(maxSize);
      int p2 = rand.nextInt(maxSize);
      bool has = contains.contains(p);
      activeProduct.add(p);
      activeProduct.add(p2);
      if (mounted) setState(() {});
    });
  }

  double isActive(int p) {
    bool show = activeProduct.contains(p);
    return show ? 1 : .05;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () {
          position = decoBoxPosition.dx;
          print("ok $position");

          setState(() {});
        },
        child: Stack(
          children: <Widget>[
            LiquidSwipe(
                initialPage: currentPage,
                enableLoop: true,
                onPageChangeCallback: (p) {
                  setState(() {
                    currentPage = p;
                  });
                },
                pages: List<Container>.generate(data.length, (p) {
                  LandHolder holder = data[p];

                  return Container(
                    child: Stack(
                      children: <Widget>[
                        Container(
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage(holder.image),
                                  fit: BoxFit.cover,
                                  alignment: Alignment.centerLeft)),
                        ),
                        Container(
                          color: black.withOpacity(p == 3 ? 0 : .5),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Container(
                            //alignment: Alignment.center,
                            margin: EdgeInsets.only(bottom: 150, left: 10),
                            width: 300,
                            child: Container(
                              padding: EdgeInsets.all(10),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Text(
                                    holder.title,
                                    textAlign: TextAlign.start,
                                    style: textStyle(true, 25, white),
                                  ),
                                  addSpace(5),
                                  Text(
                                    holder.value,
                                    textAlign: TextAlign.start,
                                    style: textStyle(false, 14, white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                })),
            authButtons()
          ],
        ),
      ),
    );
  }

  GlobalKey decoKey = GlobalKey();
  double position = Offset.zero.dy;

  Offset get decoBoxPosition {
    final RenderBox decBox = decoKey.currentContext.findRenderObject();
    return decBox.localToGlobal(Offset.zero);
  }

  authButtons() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              key: decoKey,
              padding: EdgeInsets.all(1),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: black.withOpacity(.7)),
              child: new DotsIndicator(
                dotsCount: data.length,
                position: currentPage,
                decorator: DotsDecorator(
                  size: const Size.square(5.0),
                  color: white,
                  activeColor: blue3,
                  activeSize: const Size(10.0, 7.0),
                  activeShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0)),
                ),
              ),
            ),
            addSpace(10),
            FlatButton(
              onPressed: () {
                pushAndResult(context, AuthLogin());
              },
              color: buttonColor,
              padding: EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
              child: Center(
                child: Text(
                  "Login",
                  style: textStyle(true, 16, white),
                ),
              ),
            ),
            FlatButton(
              onPressed: () {
                pushAndResult(
                    context,
                    AuthSignUp(
                      authPage: 0,
                    ));
              },
              color: transparent,
              //padding: EdgeInsets.all(25),
              child: Center(
                child: Text(
                  "Get Started",
                  style: textStyle(false, 16, white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LandHolder {
  final String image;
  final String title;
  final String value;

  LandHolder(
      {@required this.image, @required this.title, @required this.value});
}
