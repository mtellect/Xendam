import 'package:cached_network_image/cached_network_image.dart';
import 'package:credpal/MainHomePg.dart';
import 'package:credpal/app/assets.dart';
import 'package:credpal/auth/AuthSignUp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../app/baseApp.dart';

class AuthLogin extends StatefulWidget {
  @override
  _AuthLoginState createState() => _AuthLoginState();
}

class _AuthLoginState extends State<AuthLogin> {
  bool showPassword = false;

  var emailController = TextEditingController();
  var passController = TextEditingController();
  final localAuthentication = LocalAuthentication();
  var scaffoldKey = GlobalKey<ScaffoldState>();

  Future<bool> isBiometricAvailable() async {
    bool isAvailable = false;
    try {
      isAvailable = await localAuthentication.canCheckBiometrics;
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return isAvailable;

    isAvailable
        ? print('Biometric is available!')
        : print('Biometric is unavailable.');

    return isAvailable;
  }

  Future<void> getListOfBiometricTypes() async {
    List<BiometricType> listOfBiometrics;
    try {
      listOfBiometrics = await localAuthentication.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;

    print(listOfBiometrics);
  }

  Future<void> authenticateFinger() async {
    bool isAuthenticated = false;
    try {
      isAuthenticated = await localAuthentication.authenticateWithBiometrics(
        localizedReason:
            "Please authenticate to view your transaction overview",
        useErrorDialogs: true,
        stickyAuth: true,
      );
    } on PlatformException catch (e) {
      print(e);
    }

    if (!mounted) return;

    isAuthenticated
        ? print('User is authenticated!')
        : print('User is not authenticated.');

    if (isAuthenticated) pushAndResult(context, MainHomePg());
//    if (isAuthenticated) {
//      Navigator.of(context).push(
//        MaterialPageRoute(
//          builder: (context) => TransactionScreen(),
//        ),
//      );
//    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: white,
      body: Stack(
        children: <Widget>[
          Container(
            color: blue4.withOpacity(.015),
          ),
          pageBody()
        ],
      ),
    );
  }

  pageBody() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            alignment: Alignment.centerRight,
            child: FlatButton(
              onPressed: () {
                Navigator.pop(context);
              },
              shape: CircleBorder(),
              padding: EdgeInsets.all(20),
              child: Icon(Icons.close),
            ),
          ),
          addSpace(10),
          Container(
            padding: EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        "Login to your account",
                        textAlign: TextAlign.start,
                        style: textStyle(true, 25, headerColor),
                      ),
                      addSpace(4),
                      Text(
                        "Securely login to your Xendam",
                        style: textStyle(false, 14, subHeaderColor),
                      )
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: CachedNetworkImage(
                    imageUrl: maugostImage,
                    height: 40,
                    width: 40,
                    placeholder: (ctx, s) {
                      return Container(
                        height: 40,
                        width: 40,
                        color: APP_COLOR,
                        child: Image.asset("assets/images/ic_launcher.png"),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
          addSpace(15),
          Flexible(
            child: ListView(
              children: <Widget>[
                authInputField(
                    controller: emailController,
                    title: "Email",
                    hint: "Enter your email address"),
                authInputField(
                    controller: passController,
                    title: "Password",
                    hint: "Enter your password",
                    isPassword: true,
                    showPassword: showPassword,
                    onPassChanged: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    }),
                Container(
                  padding: EdgeInsets.all(18),
                  alignment: Alignment.center,
                  child: Text(
                    "Can't remember your password?",
                    style: textStyle(false, 14, headerColor),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(14),
                  child: FlatButton(
                    onPressed: () {
                      authenticateUser();
                    },
                    color: buttonColor,
                    padding: EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text(
                        "LOG ME IN",
                        style: textStyle(true, 16, white),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    popUpWidgetAndDisposeCurrent(
                        context,
                        AuthSignUp(
                          authPage: 0,
                        ));
                  },
                  child: Container(
                    padding: EdgeInsets.all(18),
                    alignment: Alignment.center,
                    child: Text(
                      "Don't have an account?",
                      style: textStyle(false, 14, headerColor),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(18),
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () async {
                      if (await isBiometricAvailable()) {
                        await getListOfBiometricTypes();
                        await authenticateFinger();
                      }
                    },
                    child: Image.asset(
                      "assets/images/fingerprint.png",
                      color: APP_COLOR,
                      height: 50,
                      width: 50,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  authInputField(
      {@required TextEditingController controller,
      String title,
      String hint,
      bool isPassword = false,
      bool showPassword = false,
      onPassChanged}) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Row(
        children: <Widget>[
          Container(
            width: 60,
            child: Text(
              title,
              style: textStyle(false, 14, headerColor),
            ),
          ),
          addSpaceWidth(10),
          Flexible(
            child: CupertinoTextField(
              controller: controller,
              padding: EdgeInsets.all(18),
              placeholder: hint,
              obscureText: showPassword && isPassword,
              suffix: isPassword
                  ? Container(
                      decoration: BoxDecoration(
                          color: buttonColor,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          )),
                      child: IconButton(
                          icon: Icon(
                            showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: white,
                          ),
                          onPressed: onPassChanged),
                    )
                  : null,
              decoration: BoxDecoration(
                  color: black.withOpacity(.04),
                  borderRadius: BorderRadius.circular(8)),
            ),
          )
        ],
      ),
    );
  }

  void authenticateUser() async {
    String email = emailController.text;
    String pass = passController.text;

    if (email.isEmpty) {
      toast(scaffoldKey, "Enter your email address");
      return;
    }

    if (pass.isEmpty) {
      toast(scaffoldKey, "Enter your password");
      return;
    }
    showProgress(true, progressId, context, msg: "Logging In...");

    FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: pass)
        .then((value) {
      popUpWidgetScreenUntil(context, MainHomePg());
    }).catchError(onError);
  }

  final progressId = getRandomId();

  onError(e) {
    showProgress(false, progressId, context);
    showMessage(
        context, Icons.error, red, "SignUp Error", "${e.message} ${e.details}",
        delayInMilli: 1000, cancellable: true);
  }
}
