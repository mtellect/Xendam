import 'package:credpal/EnterAccount.dart';
import 'package:credpal/app/AppEngine.dart';
import 'package:credpal/app/assets.dart';
import 'package:flutter/material.dart';
import 'package:virtual_keyboard/virtual_keyboard.dart';

import 'EnterCard.dart';
import 'main_screens/Home.dart';

class EnterAmount extends StatefulWidget {
  final String title;
  final PayType type;

  const EnterAmount({Key key, this.title, this.type}) : super(key: key);
  @override
  _EnterAmountState createState() => _EnterAmountState();
}

class _EnterAmountState extends State<EnterAmount> {
  String amountToPull = '0.00';
  bool shiftEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        iconTheme: IconThemeData(color: black),
        title: Text(
          "Enter Amount",
          style: textStyle(true, 20, black),
        ),
        centerTitle: false,
        elevation: 0,
        actions: <Widget>[
          if (!isZeroValue)
            Container(
              padding: EdgeInsets.all(10),
              child: FlatButton(
                onPressed: () {
                  final PayType type = widget.type;
                  if (type == PayType.CARD) {
                    pushAndResult(
                        context,
                        EnterCard(
                          amountToPull: int.parse(amountToPull),
                        ));
                    return;
                  }
                  pushAndResult(
                      context,
                      EnterAccount(
                        type: type,
                        amountToPull: int.parse(amountToPull),
                      ));
                },
                color: orang0,
                padding: EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: Center(
                  child: Text(
                    "PROCEED",
                    style: textStyle(true, 12, white),
                  ),
                ),
              ),
            )
        ],
      ),
      body: payBody(),
    );
  }

  bool get isZeroValue => amountToPull == "0.00";

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
                  amountToPull,
                  style: textStyle(
                      true, 40, black.withOpacity(isZeroValue ? 0.6 : 1)),
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
      if (isZeroValue) {
        amountToPull = (shiftEnabled ? key.capsText : key.text);
      } else {
        amountToPull = amountToPull + (shiftEnabled ? key.capsText : key.text);
      }
    } else if (key.keyType == VirtualKeyboardKeyType.Action) {
      switch (key.action) {
        case VirtualKeyboardKeyAction.Backspace:
          //print(text.length);
          if (amountToPull.length == 1 || isZeroValue || amountToPull.isEmpty) {
            amountToPull = "0.00";
          } else {
            amountToPull = amountToPull.substring(0, amountToPull.length - 1);
          }

          break;
        case VirtualKeyboardKeyAction.Return:
          amountToPull = amountToPull + '\n';
          break;
        case VirtualKeyboardKeyAction.Space:
          amountToPull = amountToPull + key.text;
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
}
