import 'package:credpal/MainHomePg.dart';
import 'package:credpal/app/assets.dart';
import 'package:credpal/auth/AuthLogin.dart';
import 'package:credpal/dialogs/baseDialogs.dart';
import 'package:credpal/main.dart';
import 'package:credpal/rave/RaveApi.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/baseApp.dart';

class AuthSignUp extends StatefulWidget {
  final int authPage;

  const AuthSignUp({Key key, this.authPage}) : super(key: key);
  @override
  _AuthSignUpState createState() => _AuthSignUpState();
}

class _AuthSignUpState extends State<AuthSignUp> {
  bool showPassword = false;
  var nameController = TextEditingController();
  var bvnController = TextEditingController();
  var countryController = TextEditingController();
  var phoneController = TextEditingController();
  var emailController = TextEditingController();
  var passController = TextEditingController();

  int currentPage;

  int get authPage => widget.authPage;
  var vpController = PageController();
  var scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
      currentPage = authPage;
      vpController = PageController(initialPage: currentPage);
    });
  }

  List<RaveCountries> countries = raveApi.miscellaneous.getSupportedCountries();
  RaveCountries selectedCountry;
  String selectedCountryStr;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: white,
      body: Stack(
        children: <Widget>[
          Container(
            color: blue4.withOpacity(.02),
          ),
          page0()
        ],
      ),
    );
  }

  page0() {
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
            margin: EdgeInsets.only(right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  titleValue,
                  textAlign: TextAlign.start,
                  style: textStyle(true, 25, headerColor),
                ),
                addSpace(4),
                Text(
                  "Choose a free account and start an amazing financial journey with Xendam",
                  style: textStyle(false, 14, subHeaderColor),
                )
              ],
            ),
          ),
          addSpace(15),
          Flexible(
            child: ListView(
              padding: EdgeInsets.all(10),
              children: <Widget>[
                authInputField(
                    controller: countryController,
                    title: "Country",
                    hint: "Select  your country",
                    isBtn: true,
                    onBtnPressed: () {
                      pushAndResult(
                          context,
                          listDialog(
                            countries.map((bm) => bm.country).toList(),
                            //usePosition: false,
                          ), result: (_) async {
                        if (null == _) return;
                        setState(() {
                          countryController.text = countries[_].country;
                          selectedCountry = countries[_];
                        });
                      });
                    }),
                authInputField(
                    controller: nameController,
                    title: "Full Name",
                    hint: "Enter your first and last name"),
                authInputField(
                    controller: phoneController,
                    isNum: true,
                    title: "Phone",
                    hint: "Enter your phone number"),
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
                  padding: EdgeInsets.all(14),
                  child: FlatButton(
                    onPressed: createMyAccount,
                    color: buttonColor,
                    padding: EdgeInsets.all(20),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Center(
                      child: Text(
                        "CREATE MY ACCOUNT",
                        style: textStyle(true, 16, white),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    popUpWidgetAndDisposeCurrent(context, AuthLogin());
                  },
                  child: Container(
                    padding: EdgeInsets.all(18),
                    alignment: Alignment.center,
                    child: Text(
                      "Already have an account? Log In",
                      style: textStyle(false, 14, headerColor),
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

  createMyAccount() async {
    String fullName = nameController.text;
    String country = countryController.text;
    String phone = phoneController.text;
    String email = emailController.text;
    String pass = passController.text;

    if (country.isEmpty) {
      toast(scaffoldKey, "Choose your country");
      return;
    }
    if (fullName.isEmpty) {
      toast(scaffoldKey, "Enter your full name");
      return;
    }

    if (phone.isEmpty) {
      toast(scaffoldKey, "Enter your phone number");
      return;
    }

    if (email.isEmpty) {
      toast(scaffoldKey, "Enter your email address");
      return;
    }

    if (pass.isEmpty) {
      toast(scaffoldKey, "Enter your password");
      return;
    }
    showProgress(true, progressId, context, msg: "Create Account...");
    FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: pass)
        .then((value) {
      BaseModel bm = BaseModel();
      bm
        ..put(COUNTRY, country)
        ..put(FULL_NAME, fullName)
        ..put(PHONE_NO, phone)
        ..put(EMAIL, email)
        ..put(PASSWORD, pass);
      bm.saveItem(USER_BASE, false, document: value.user.uid, onComplete: () {
        popUpWidgetScreenUntil(context, MainHomePg());
        print("logged in");
      }, onError: (e) {
        print(e);
        onError(e, onReg: true);
      });
    }).catchError(onError);
  }

  final progressId = getRandomId();

  onError(e, {bool onReg = false}) {
    if (onReg) {
      FirebaseAuth.instance.currentUser().then((value) => value.delete());
    }
    showProgress(false, progressId, context);
    showMessage(
        context, Icons.error, red, "SignUp Error", "${e.message} ${e.details}",
        delayInMilli: 1000, cancellable: true);
  }

  String get titleValue {
    if (currentPage == 0) return "Create your account.";
    if (currentPage == 1) return "Register your business.";
    return "Contact our Sales Team";
  }

  authInputField(
      {@required TextEditingController controller,
      String title,
      String hint,
      bool isPassword = false,
      bool showPassword = false,
      bool isBtn = false,
      bool isNum = false,
      int maxLines = 1,
      onPassChanged,
      onBtnPressed}) {
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
              maxLines: maxLines,
              onTap: isBtn ? onBtnPressed : null,
              placeholder: hint,
              readOnly: isBtn,
              keyboardType: isNum ? TextInputType.number : null,
              obscureText: showPassword,
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
                  : isBtn
                      ? Container(
                          padding: EdgeInsets.all(3),
                          child: Column(
                            children: <Widget>[
                              Icon(
                                Icons.arrow_drop_up,
                                color: black.withOpacity(.6),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: black.withOpacity(.6),
                              ),
                            ],
                          ),
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
}
