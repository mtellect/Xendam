import 'package:credpal/MainHomePg.dart';
import 'package:credpal/app/AppEngine.dart';
import 'package:credpal/app/assets.dart';
import 'package:credpal/app/baseApp.dart';
import 'package:flutter/material.dart';
import 'package:virtual_keyboard/virtual_keyboard.dart';

import 'main.dart';
import 'main_screens/Home.dart';

enum AccessType { OTP, PASSWORD }

class EnterAccess extends StatefulWidget {
  final String title;
  final String narration;
  final String flwRef;
  final AccessType accessType;
  final PayType payType;

  const EnterAccess(
      {Key key,
      this.title,
      this.accessType = AccessType.OTP,
      this.payType,
      this.narration,
      this.flwRef})
      : super(key: key);
  @override
  _EnterAccessState createState() => _EnterAccessState();
}

class _EnterAccessState extends State<EnterAccess> {
  String accessCode = '******';
  bool shiftEnabled = false;

  String get titleText =>
      widget.accessType == AccessType.OTP ? "Enter OTP" : "Enter Password";

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, "");
        return false;
      },
      child: Scaffold(
        backgroundColor: white,
        appBar: AppBar(
          backgroundColor: white,
          iconTheme: IconThemeData(color: black),
          title: Text(
            titleText,
            style: textStyle(true, 20, black),
          ),
          centerTitle: false,
          elevation: 0,
          actions: <Widget>[
            if (!isEmptyAccess && accessCode.length == 5)
              Container(
                padding: EdgeInsets.all(10),
                child: FlatButton(
                  onPressed: () {
                    //Navigator.pop(context, accessCode);
                    if (widget.payType == PayType.ADD) {
                      fundAccount(accessCode, widget.flwRef);
                    }
                  },
                  color: orang0,
                  padding: EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: Center(
                    child: Text(
                      "CHARGE",
                      style: textStyle(true, 12, white),
                    ),
                  ),
                ),
              )
          ],
        ),
        body: payBody(),
      ),
    );
  }

  bool get isEmptyAccess => accessCode == "******";

  payBody() {
    return Column(
      children: <Widget>[
        Flexible(
          child: Container(
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  accessCode,
                  style: textStyle(
                      true, 40, black.withOpacity(isEmptyAccess ? 0.6 : 1)),
                ),
                //if (isZeroValue)
                Container(
                  margin: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: red, borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.all(8),
                  child: Text(
                    "Please enter an amount to proceed",
                    style: textStyle(false, 14, white),
                  ),
                )
              ],
            ),
          ),
        ),
        Container(
          color: Colors.deepPurple,
          child: VirtualKeyboard(
              height: 300,
              textColor: Colors.white,
              type: VirtualKeyboardType.Numeric,
              onKeyPress: _onKeyPress),
        )
      ],
    );
  }

  _onKeyPress(VirtualKeyboardKey key) {
    if (key.keyType == VirtualKeyboardKeyType.String) {
      if (accessCode.length == 5 && !isEmptyAccess) return;
      if (isEmptyAccess) {
        accessCode = (shiftEnabled ? key.capsText : key.text);
      } else {
        accessCode = accessCode + (shiftEnabled ? key.capsText : key.text);
      }
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          //print(text.length);
          if (accessCode.length == 1 || isEmptyAccess || accessCode.isEmpty) {
            accessCode = "******";
          } else {
            accessCode = accessCode.substring(0, accessCode.length - 1);
          }

          break;
        case VirtualKeyboardKeyAction.Return:
          accessCode = accessCode + '\n';
          break;
        case VirtualKeyboardKeyAction.Space:
          accessCode = accessCode + key.text;
          break;
        case VirtualKeyboardKeyAction.Shift:
          shiftEnabled = !shiftEnabled;
          break;
        default:
      }
    }
    setState(() {
      print("setting state");
    });
  }

  final progressId = getRandomId();

  fundAccount(String otp, String flwRef) {
    showProgress(true, progressId, context, msg: "Funding Account...");
    raveApi.charge.validatePayment(
        isAccount: true,
        transactionRef: flwRef,
        otp: otp,
        onComplete: (msg, resp) {
          final transMap = Transactions(
                  transactionRef: resp.txRef,
                  toAccount: "Xendam Wallet Credited",
                  narration: widget.narration,
                  amount: resp.amount.toDouble(),
                  isDebit: false,
                  date: DateTime.now())
              .toModel();

          BaseModel transModel = BaseModel(items: transMap);
          transModel.saveItem(TRANSACTION_BASE, true, document: resp.txRef,
              onComplete: () {
            showProgress(false, progressId, context);

            print("msg $msg tok ${resp.model.items}");
            int p = acctBalances
                .indexWhere((element) => element.title == "Total Savings");
            acctBalances[p].amount =
                acctBalances[p].amount + resp.amount.toDouble();
            userModel
              ..put(ACCOUNT_BALANCES,
                  acctBalances.map((e) => e.toModel()).toList())
              ..updateItems();

            showMessage(
                context,
                Icons.check,
                green_dark,
                "Transaction Successful",
                "Your xendam account has successfully been funded",
                delayInMilli: 900,
                cancellable: false, onClicked: (_) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            });
          });
          return;
          Future.delayed(Duration(milliseconds: 900), () {});
        },
        onError: (e) {
          showProgress(false, progressId, context);
          showMessage(context, Icons.error, red, "Charge Error", e,
              delayInMilli: 900, cancellable: false, onClicked: (_) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          });
        });
  }
}
