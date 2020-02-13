import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:credpal/main_screens/Account.dart';
import 'package:credpal/main_screens/Ponds.dart';
import 'package:credpal/rave/RaveApi.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:ravepay/ravepay.dart';

import 'Landing.dart';
import 'app/baseApp.dart';
import 'main.dart';
import 'main_screens/Home.dart';
import 'main_screens/Savings.dart';

const double HEADER_HEIGHT = 30;
const double HEADER_HEIGHT_MEDIUM = 18;
const double HEADER_HEIGHT_SMALL = 15;
const String NAIRA_SYMBOL = "₦";

List<RaveBanks> raveBanks;
List<Bank> banks;
List<AccountBalance> acctBalances = List();
List<BaseModel> mainTransactions = List();
List<Transactions> recentTransactions = List();
bool hasSetup = false;
bool transactionsLoaded = false;

class MainHomePg extends StatefulWidget {
  @override
  _MainHomePgState createState() => _MainHomePgState();
}

class _MainHomePgState extends State<MainHomePg> {
  int currentPage = 0;
  final vp = PageController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadAvailableBanks();
    createBasicListeners(redirectBack: () {
      popUpWidgetScreenUntil(context, Landing());
    }, setUpMethods: () {
      if (!hasSetup) {
        if (mounted)
          setState(() {
            hasSetup = !hasSetup;
          });
      }
      loadAccountBalances();
      loadRecentTransactions(false);
      if (!hasSetup) {}
    });
  }

  loadRecentTransactions(bool isNew) async {
    QuerySnapshot shots = await Firestore.instance
        .collection(TRANSACTION_BASE)
        .where(USER_ID, isEqualTo: userModel.getObjectId())
        .orderBy(TIME, descending: !isNew)
        .limit(15)
        .startAt([
      !isNew
          ? (mainTransactions.isEmpty
              ? DateTime.now().millisecondsSinceEpoch
              : mainTransactions[mainTransactions.length - 1].getTime())
          : (mainTransactions.isEmpty ? 0 : mainTransactions[0].getTime())
    ]).getDocuments();

    for (DocumentChange changes in shots.documentChanges) {
      if (changes.type == DocumentChangeType.removed) {
        changes.document.reference.delete();
        mainTransactions.removeWhere((bm) =>
            bm.getObjectId() == BaseModel(doc: changes.document).getObjectId());
        return;
      }

      BaseModel model = BaseModel(doc: changes.document);

      bool groupPost = model.getBoolean(IS_GROUP);
      if (groupPost) continue;
      int p = mainTransactions
          .indexWhere((bm) => bm.getObjectId() == model.getObjectId());
      bool exists = p != -1;

      if (!exists) {
        if (isNew) {
          mainTransactions.insert(0, model);
        } else {
          mainTransactions.add(model);
        }
      } else {
        mainTransactions[p] = model;
      }

      if (mounted)
        setState(() {
          transactionsLoaded = true;
          recentTransactions = mainTransactions
              .map((e) => Transactions(
                  toAccount: e.getString(TO_ACCOUNT),
                  transactionRef: e.getString(TRANSACTION_REF),
                  narration: e.getString(TRANSACTION_NARRATION),
                  amount: e.getDouble(AMOUNT),
                  isDebit: e.getBoolean(IS_DEBIT),
                  date: DateTime.fromMillisecondsSinceEpoch(e.get(TIME))))
              .toList();
        });
    }
  }

  loadAccountBalances() {
    acctBalances = userModel.getList(ACCOUNT_BALANCES).map((e) {
      BaseModel bm = BaseModel(items: e);
      return AccountBalance(
          title: bm.getString(TITLE),
          amount: bm.getDouble(AMOUNT),
          icon: IconData(bm.get(ICON),
              fontFamily: bm.get(ICON_FONT),
              fontPackage: bm.get(ICON_FONT_PACKAGE),
              matchTextDirection: bm.get(ICON_DIRECTION)),
          color: Color(bm.get(COLOR)));
    }).toList();
    if (mounted) setState(() {});
  }

  loadAvailableBanks() async {
    Banks().fetch().then((b) {
      banks = b.data;
      banks.sort((a, b) => a.name.compareTo(b.name));
    });

    raveApi.miscellaneous.getSupportedBanks("NG").then((banks) {
      raveBanks = banks;
      raveBanks.sort((a, b) => a.bankName.compareTo(b.bankName));
      print("pulled!!!");
      if (mounted) setState(() {});
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Column(
        children: <Widget>[pageViews(), btmTabs()],
      ),
    );
  }

  pageViews() {
    return Flexible(
      child: PageView(
        controller: vp,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (p) {
          setState(() {
            currentPage = p;
          });
        },
        children: <Widget>[
          Home(),
          Savings(
            pgColor: homeTabs[currentPage].color,
          ),
          Ponds(
            pgColor: homeTabs[currentPage].color,
          ),
          Account()
        ],
      ),
    );
  }

  btmTabs() {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
          ),
          border: Border.all(color: black.withOpacity(.02), width: 4)),
      child: Row(
        children: List.generate(4, (p) {
          return tabItems(p, homeTabs[p]);
        }),
      ),
    );
  }

  List<HomeTab> homeTabs = [
    HomeTab(title: "Home", icon: AntDesign.home),
    HomeTab(title: "Savings", icon: Feather.target),
    HomeTab(title: "Ponds", icon: AntDesign.rocket1, color: plinkdColor),
    HomeTab(
      title: "Account",
      icon: FontAwesome.user_o,
    )
  ];

  tabItems(int p, HomeTab tab) {
    bool active = currentPage == p;
    return Flexible(
      child: GestureDetector(
        onTap: () {
          currentPage = p;
          vp.jumpToPage(p);
          FocusScope.of(context).requestFocus(FocusNode());
          setState(() {});
        },
        child: Container(
          height: 60,
          width: screenW(context) / 3,
          color: transparent,
          //padding: EdgeInsets.all(active ? 0 : 8),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                tab.icon,
                size: active ? 25 : 22,
                color: active ? tab.color : black.withOpacity(.5),
              ),
              addSpace(4),
              Text(
                tab.title,
                style: textStyle(true, 13, black.withOpacity(active ? 1 : .6)),
              ),
              if (active)
                Container(
                  height: 8,
                  width: 8,
                  decoration:
                      BoxDecoration(color: tab.color, shape: BoxShape.circle),
                )
            ],
          ),
        ),
      ),
    );
  }
}

class HomeTab {
  final IconData icon;
  final String title;
  final Color color;

  HomeTab({@required this.icon, @required this.title, this.color = APP_COLOR});
}

class AccountBalance {
  String title;
  double amount;
  IconData icon;
  Color color;

  AccountBalance(
      {@required this.title,
      @required this.amount,
      @required this.icon,
      this.color = APP_COLOR});

  Map<String, Object> toModel() {
    BaseModel bm = BaseModel();
    bm
      ..put(TITLE, title)
      ..put(AMOUNT, amount)
      ..put(ICON, icon.codePoint)
      ..put(ICON_FONT, icon.fontFamily)
      ..put(ICON_FONT_PACKAGE, icon.fontPackage)
      ..put(ICON_DIRECTION, icon.matchTextDirection)
      ..put(COLOR, color.value);
    return bm.items;
  }
}

class Transactions {
  final String transactionRef;
  final String toAccount;
  final String narration;
  final double amount;
  final DateTime date;
  final isDebit;

  Transactions({
    @required this.toAccount,
    @required this.transactionRef,
    @required this.narration,
    @required this.amount,
    @required this.isDebit,
    @required this.date,
  });

  Map<String, Object> toModel() {
    BaseModel bm = BaseModel();
    bm
      ..put(TRANSACTION_REF, transactionRef)
      ..put(TO_ACCOUNT, toAccount)
      ..put(AMOUNT, amount)
      ..put(TRANSACTION_NARRATION, narration)
      ..put(IS_DEBIT, isDebit)
      ..put(AMOUNT, amount)
      ..put(TIME, date.millisecondsSinceEpoch);
    return bm.items;
  }
}

formatTransactionTime(DateTime date) {
  return formatDate(DateTime.now(), ['M', ' ', 'dd', ',', 'yyyy']);
}
