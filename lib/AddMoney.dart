import 'package:flutter/material.dart';

import 'EnterAmount.dart';
import 'app/baseApp.dart';
import 'main_screens/Home.dart';

class AddMoney extends StatefulWidget {
  final PayType type;

  const AddMoney({Key key, this.type}) : super(key: key);
  @override
  _AddMoneyState createState() => _AddMoneyState();
}

class _AddMoneyState extends State<AddMoney> {
  List<BaseModel> data = [
    BaseModel()
      ..put(COLORS, [
        Color(0xFFFB72AD).value,
        Color(0xFFB643D5).value,
      ])
      ..put(TITLE, "From Bank")
      ..put(DESCRIPTION,
          "Add funds into your Xendam wallet directly from your Bank Account")
      ..put(IMAGE, "assets/images/bank.png"),
    BaseModel()
      ..put(COLORS, [
        blue3.value,
        blue03.value,
      ])
      ..put(TITLE, "From Card")
      ..put(DESCRIPTION,
          "Add funds into your Xendam wallet directly from your ATM Card")
      ..put(IMAGE, "assets/images/fund.png"),
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        iconTheme: IconThemeData(color: black),
        title: Text(
          "Add money",
          style: textStyle(true, 20, black),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: page(),
    );
  }

  page() {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (ctx, p) {
          BaseModel sendTo = data[p];
          String image = sendTo.getImage();
          String title = sendTo.getString(TITLE);
          String desc = sendTo.getString(DESCRIPTION);
          List<Color> colors =
              sendTo.getList(COLORS).map((c) => Color(c)).toList();
          return GestureDetector(
            onTap: () {
              pushAndResult(
                  context,
                  EnterAmount(
                    title: "Enter Amount",
                    type: p == 1 ? PayType.CARD : PayType.ADD,
                  ));
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: <Widget>[
                Container(
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: textStyle(true, 25, white),
                        ),
                        addSpace(5),
                        Text(
                          desc,
                          style: textStyle(true, 14, white),
                        ),
                      ],
                    ),
                  ),
                  height: 200,
                  width: double.infinity,
                  margin: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      gradient:
                          LinearGradient(colors: colors, stops: [0.0, 1.0]),
                      borderRadius: BorderRadius.circular(15)),
                ),
                Container(
                    height: 100,
                    width: 100,
                    margin: const EdgeInsets.all(25.0),
                    child: Image.asset(
                      image,
                      color: white.withOpacity(.5),
                    ))
              ],
            ),
          );
        });
  }
}
