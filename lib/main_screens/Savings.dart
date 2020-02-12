import 'package:credpal/MainHomePg.dart';
import 'package:credpal/app/baseApp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';

class Savings extends StatefulWidget {
  final Color pgColor;

  const Savings({Key key, this.pgColor}) : super(key: key);

  @override
  _SavingsState createState() => _SavingsState();
}

class _SavingsState extends State<Savings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: pageBody(),
    );
  }

  pageHeader() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "Savings",
            style: textStyle(true, HEADER_HEIGHT, black),
          ),
          Text(
            "${NAIRA_SYMBOL}0.00 ",
            style: textStyle(true, HEADER_HEIGHT_MEDIUM, widget.pgColor),
          ),
        ],
      ),
    );
  }

  pageBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        pageHeader(),
        Flexible(
          child: LayoutBuilder(
            builder: (ctx, box) {
              return emptyLayout(
                Feather.target,
                "No Savings!",
                "We'd keep you posted as soon as we enable this feature",
                isIcon: true,
              );
            },
          ),
        )
      ],
    );
  }
}
