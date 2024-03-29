import 'package:cached_network_image/cached_network_image.dart';
import 'package:credpal/AddMoney.dart';
import 'package:credpal/EnterAmount.dart';
import 'package:credpal/MainHomePg.dart';
import 'package:credpal/SendMoney.dart';
import 'package:credpal/app/AppEngine.dart';
import 'package:credpal/app/assets.dart';
import 'package:credpal/app/baseApp.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:time_machine/time_machine.dart';

enum PayType { ADD, SEND, WITHDRAW, BILLS, CARD }
enum BalanceType { SAVINGS, PONDS, TRANSFERS, WITHDRAWS }
enum TransactionType { CREDIT, DEBIT }

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final vp = PageController(viewportFraction: .85);
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: hasSetup ? pageBody() : loadingLayout(),
    );
  }

  String get timeOfDayText {
    var now = Instant.now();
    TimeOfDay time = TimeOfDay.fromDateTime(now.toDateTimeLocal());
    if (time.period == DayPeriod.am && (time.hour >= 0 && time.hour <= 4)) {
      return "You should be in bed!🙄";
    }

    if (time.period == DayPeriod.am && (time.hour > 4)) {
      return "Good Morning! Rise and Shine!🌞";
    }

    if (time.period == DayPeriod.pm && (time.hour >= 12 && time.hour <= 15)) {
      return "It's Launch time!🍔😊";
    }

    if (time.period == DayPeriod.pm && (time.hour >= 15 && time.hour <= 19)) {
      return "Good Evening!🌅";
    }
    return "Good Night!";
  }

  pageHeader() {
    return Container(
      margin: EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(15),
      color: white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "Maugost,",
                  style: textStyle(true, HEADER_HEIGHT, black),
                ),
                Text(
                  timeOfDayText,
                  style: textStyle(
                      false, HEADER_HEIGHT_SMALL, black.withOpacity(.6)),
                ),
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
    );
  }

  accountBalances() {
    return Column(
      children: <Widget>[
        Container(
          height: 130,
          child: PageView.builder(
              itemCount: acctBalances.length,
              onPageChanged: (p) {
                setState(() {
                  currentPage = p;
                });
              },
              controller: vp,
              itemBuilder: (ctx, p) {
                return balanceItem(p);
              }),
        ),
        Container(
          padding: EdgeInsets.all(15),
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(1),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: black.withOpacity(.7)),
                child: new DotsIndicator(
                  dotsCount: acctBalances.length,
                  position: currentPage,
                  decorator: DotsDecorator(
                    size: const Size.square(5.0),
                    color: white,
                    activeColor: acctBalances[currentPage].color,
                    activeSize: const Size(10.0, 7.0),
                    activeShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  balanceItem(int p) {
    AccountBalance bal = acctBalances[p];
    bool showBal = userModel.getBoolean(SHOW_ACCT_BAL);
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
        bottomRight: Radius.circular(18),
      ),
      child: Container(
        margin: EdgeInsets.all(8),
        child: Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  color: bal.color,
                  image: DecorationImage(
                    image: AssetImage("assets/images/pattern.jpg"),
                    fit: BoxFit.cover,
                  )),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                color: bal.color.withOpacity(.85),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  Icon(
                    bal.icon,
                    size: 25,
                    color: white,
                  ),
                  addSpaceWidth(10),
                  Flexible(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        bal.title,
                        style: textStyle(true, 14, white),
                      ),
                      addSpace(5),
                      Text(
                        showBal ? "$NAIRA_SYMBOL${bal.amount}" : "****",
                        style: textStyle(true, 20, white),
                      ),
                    ],
                  ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BaseModel> payData = [
    BaseModel()
      ..put(TYPE, EnumToString.parse(PayType.ADD))
      ..put(COLOR, Colors.purple.value)
      ..put(IMAGE, "assets/images/fund.png")
      ..put(TITLE, "Add Money")
      ..put(VALUE, "Into your xendam account"),
    BaseModel()
      ..put(TYPE, EnumToString.parse(PayType.SEND))
      ..put(IMAGE, "assets/images/send.png")
      ..put(TITLE, "Send Money")
      ..put(VALUE, "To your friends family and customers"),
    BaseModel()
      ..put(TYPE, EnumToString.parse(PayType.WITHDRAW))
      ..put(IMAGE, "assets/images/request.png")
      ..put(TITLE, "Withdraw")
      ..put(VALUE, "Directly into a local bank account"),
    BaseModel()
      ..put(TYPE, EnumToString.parse(PayType.BILLS))
      ..put(COLOR, Colors.green.value)
      ..put(IMAGE, "assets/images/bills.png")
      ..put(TITLE, "Pay Bills")
      ..put(VALUE, "Airtime & Cable TV")
  ];

  payItem(int p, {bool active = false, onSelected}) {
    BaseModel bm = payData[p];
    Color color = Color(bm.getInt(COLOR));
    String title = bm.getString(TITLE);
    String value = bm.getString(VALUE);
    String icon = bm.getImage();

    return GestureDetector(
      onTap: onSelected,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        margin: EdgeInsets.only(left: 5, right: 5),
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: blue3.withOpacity(.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: black.withOpacity(.05))),
        child: Row(
          children: <Widget>[
            Container(
              height: 40,
              width: 40,
              padding: EdgeInsets.all(8),
              child: Image.asset(
                icon,
                color: blue3.withOpacity(active ? 1 : .6),
              ),
              decoration: BoxDecoration(
                  color: white.withOpacity(active ? 1 : .5),
                  shape: BoxShape.circle),
            ),
            addSpaceWidth(10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: textStyle(
                        false, 16, black.withOpacity(active ? 1 : .7)),
                  ),
                  addSpace(2),
                  Flexible(
                    child: Text(
                      value,
                      style: textStyle(false, 12, black.withOpacity(.5)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  mainFeatures() {
    return Container(
      margin: EdgeInsets.only(
        left: 10,
        right: 10,
      ),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: blue3.withOpacity(.0), borderRadius: BorderRadius.circular(8)),
      child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 8, childAspectRatio: 2),
          itemCount: payData.length,
          shrinkWrap: true,
          padding: EdgeInsets.all(0),
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (ctx, p) {
            return payItem(p,
                //active: currentPage == p,
                active: true, onSelected: () {
              PayType type = EnumToString.fromString(
                  PayType.values, payData[p].getString(TYPE));

              if (p == 0) {
                pushAndResult(
                    context,
                    AddMoney(
                      type: type,
                    ));
                return;
              }
              if (p == 1) {
                pushAndResult(
                    context,
                    SendMoney(
                      type: type,
                    ));
                return;
              }

              pushAndResult(
                  context,
                  EnterAmount(
                    type: type,
                  ));
            });
          }),
    );
  }

  transactionItem(Transactions trans) {
    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(15),
      decoration:
          BoxDecoration(color: white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Row(
              children: <Widget>[
                Container(
                  height: 50,
                  width: 50,
                  padding: EdgeInsets.all(12),
                  child: Image.asset(
                    "assets/images/${trans.isDebit ? "send" : "request"}.png",
                    color: (trans.isDebit ? red : green_dark),
                  ),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          (trans.isDebit ? red : green_dark).withOpacity(.2)),
                ),
                addSpaceWidth(10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        trans.toAccount,
                        style: textStyle(true, 16, black),
                      ),
                      addSpace(10),
                      Text(
                        trans.narration,
                        style: textStyle(false, 13, black.withOpacity(.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          addSpaceWidth(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                "$NAIRA_SYMBOL ${trans.amount}",
                style: textStyle(true, 14, (trans.isDebit ? red : green_dark)),
              ),
              addSpace(10),
              Text(
                formatTransactionTime(trans.date), //trans.date,
                style: textStyle(false, 12, black.withOpacity(.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pageBody() {
    return Column(
      children: <Widget>[
        Container(
          color: white,
          child: Column(
            children: <Widget>[
              pageHeader(),
              accountBalances(),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            padding: EdgeInsets.only(top: 10),
            children: <Widget>[
              Container(
                padding: EdgeInsets.all(15),
                child: Text(
                  "Choose Service",
                  style: textStyle(true, 16, black.withOpacity(.6)),
                ),
              ),
              mainFeatures(),
              Container(
                padding: EdgeInsets.all(15),
                child: Text(
                  "Recent Activities",
                  style: textStyle(true, 16, black.withOpacity(.6)),
                ),
              ),
              Column(
                children: List.generate(recentTransactions.length,
                    (index) => transactionItem(recentTransactions[index])),
              )
            ],
          ),
        )
      ],
    );
  }
}
