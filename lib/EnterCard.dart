import 'package:credpal/app/assets.dart';
import 'package:credpal/app/baseApp.dart';
import 'package:credpal/main.dart';
import 'package:credpal/main_screens/Home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'EnterAccess.dart';
import 'MainHomePg.dart';
import 'rave/RaveApi.dart';

class EnterCard extends StatefulWidget {
  final int amountToPull;

  final PayType type;

  const EnterCard({Key key, this.amountToPull, this.type}) : super(key: key);

  @override
  _EnterCardState createState() => _EnterCardState();
}

class _EnterCardState extends State<EnterCard> {
  String cardNumber = '';
  String expiryDate = '';
  String expiryYear = '';
  String expiryMonth = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  bool saveCard = false;

  final formKey = GlobalKey<FormState>();
  final scaffoldKey = GlobalKey<ScaffoldState>();

  final progressId = getRandomId();

  String countryCurrency = raveApi.miscellaneous
      .getSupportedCountries()
      .singleWhere((element) => element.country == userModel.getString(COUNTRY))
      .countryCurrency;
  String countryCode = raveApi.miscellaneous
      .getSupportedCountries()
      .singleWhere((element) => element.country == userModel.getString(COUNTRY))
      .countryCode;
  String country = raveApi.miscellaneous
      .getSupportedCountries()
      .singleWhere((element) => element.country == userModel.getString(COUNTRY))
      .country;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      resizeToAvoidBottomInset: true,
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        iconTheme: IconThemeData(color: black),
        title: Text(
          "Enter Card",
          style: textStyle(true, 20, black),
        ),
        centerTitle: false,
        elevation: 0,
        actions: <Widget>[
          Container(
            padding: EdgeInsets.all(10),
            child: FlatButton(
              onPressed: chargeCard,
              color: APP_COLOR,
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
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            CreditCardWidget(
              cardNumber: cardNumber,
              height: 200,
              expiryDate: expiryDate,
              cardHolderName: cardHolderName,
              cvvCode: cvvCode,
              showBackView: isCvvFocused,
              cardBgColor: blue3,
            ),
            CreditCardForm(
              onCreditCardModelChange: onCreditCardModelChange,
            ),
            if (widget.type == PayType.ADD)
              checkViewItem(
                  "Would you want to save this card to be used in the future?",
                  active: saveCard, onClicked: (_) {
                setState(() {
                  saveCard = _;
                });
              })
          ],
        ),
      ),
    );
  }

  checkViewItem(String title, {bool active = false, onClicked}) {
    return InkWell(
      onTap: () {
        onClicked(!active);
      },
      child: Container(
        padding: EdgeInsets.all(18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                title,
                style: textStyle(false, 16, black.withOpacity(.7)),
              ),
            ),
            CupertinoSwitch(
              onChanged: onClicked,
              value: active,
              activeColor: APP_COLOR,
            )
          ],
        ),
      ),
    );
  }

  void onCreditCardModelChange(CreditCardModel creditCardModel) {
    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;

      if (expiryDate.isNotEmpty && expiryDate.length == 5) {
        expiryMonth = expiryDate.split("/")[0];
        expiryYear = expiryDate.split("/")[1];
      }
    });
  }

  chargeCard() {
    if (cardNumber.isEmpty) {
      toast(
        scaffoldKey,
        "Please enter card number",
      );
      return;
    }

    if (expiryDate.isEmpty || expiryDate.length != 5) {
      toast(
        scaffoldKey,
        "Please enter card expiry date",
      );
      return;
    }

    if (cvvCode.isEmpty) {
      toast(
        scaffoldKey,
        "Please enter the cvv code behind the card",
      );
      return;
    }

    if (cardHolderName.isEmpty) {
      toast(
        scaffoldKey,
        "Please enter name on the card",
      );
      return;
    }

    showProgress(true, progressId, context, msg: "Generating OTP...");
    chargeRave();
  }

  chargeRave(
      {String suggestAuth = "PIN",
      String cardPin = "PIN",
      bool pinRequested = false}) {
    final amountToCharge = widget.amountToPull.roundToDouble();

    raveApi.charge.initiateCardPayment(
        context: context,
        cardNumber: cardNumber.replaceAll(" ", ""),
        cardCVV: cvvCode,
        cardExpMonth: expiryMonth,
        cardExpYear: expiryYear,
        currency: countryCurrency,
        country: countryCode,
        amount: amountToCharge.toString(),
        email: userModel.getEmail(),
        phoneNumber: userModel.getString(PHONE_NUMBER),
        firstName: userModel.getString(FULL_NAME).split(" ")[0],
        lastName: userModel.getString(FULL_NAME).split(" ")[1],
        suggestAuth: suggestAuth,
        cardPin: cardPin,
        pinRequested: pinRequested,
        txReference: progressId,
        validatorBuilder: (bool otp, String respMsg, String flwRef) {
          showProgress(false, progressId, context);
          print("txref $flwRef");
          if (otp) {
            enterTransactionOTP(flwRef);
            return;
          }
          enterTransactionOTP(flwRef,
              title: "Enter Card Pin", accessType: AccessType.PIN);
        },
        onComplete: (msg) {
          showProgress(false, progressId, context);
          showMessage(context, Icons.check, green, "Payment Successful",
              "Payment was successful: MSG $msg",
              delayInMilli: 900, cancellable: true);
        },
        onError: (e) {
          showProgress(false, progressId, context);
          showMessage(context, Icons.error, red, "Error", e,
              delayInMilli: 900, cancellable: true);
        });
  }

  enterTransactionOTP(String flwRef,
      {String title = "Enter OTP",
      AccessType accessType = AccessType.OTP}) async {
    print(accessType);

    Future.delayed(Duration(milliseconds: 800), () {
      pushAndResult(
          context,
          EnterAccess(
              title: title,
              narration: "You funded your account from your credit card",
              payType: PayType.CARD,
              chargeType: ChargeType.CARD,
              accessType: accessType,
              flwRef: flwRef,
              chargeCard: chargeRave), result: (String otp) {
        if (otp.isEmpty) {
          showMessage(context, Icons.error, red, "Terminated!",
              "This Transaction was canceled by you.",
              delayInMilli: 900, cancellable: false);
          return;
        }

        if (accessType == AccessType.PIN) {
          showProgress(true, progressId, context,
              msg: "Processing Transaction...");
          chargeRave(
              cardPin: otp,
              pinRequested: true,
              suggestAuth: SUGGESTED_AUTH_PIN);
          return;
        }

        showProgress(true, progressId, context, msg: "Funding Account...");
        raveApi.charge.validatePayment(
            isAccount: false,
            transactionRef: flwRef,
            otp: otp,
            onComplete: (msg, resp) {
              if (saveCard) {
                saveCardAndToken(null);
              }
              saveTransaction(msg, resp);
            },
            onError: (e) {
              showProgress(false, progressId, context);
              showMessage(context, Icons.error, red, "Error", e,
                  delayInMilli: 1000, cancellable: true);
            });
      });
    });
  }

  void saveCardAndToken(String token) async {
    BaseModel bm = BaseModel();
    bm.put(MY_CARD_NAME, cardHolderName);
    bm.put(MY_CARD_NUMBER, cardNumber);
    bm.put(MY_CARD_EXP_MONTH, expiryMonth);
    bm.put(MY_CARD_EXP_YEAR, expiryYear);
    bm.put(MY_CARD_EXP_DATE, expiryDate);
    bm.put(MY_CARD_CVV, cvvCode);
    bm.put(EMAIL, userModel.getEmail());
    bm.put(RAVE_TOKEN, token);

    List<BaseModel> myCards =
        userModel.getList(MY_CARDS).map((m) => BaseModel(items: m)).toList();

    int p = myCards.indexWhere(
        (b) => b.getString(MY_CARD_NUMBER) == bm.getString(MY_CARD_NUMBER));

    bool exists = p != -1;
    if (!exists) {
      myCards.add(bm);
    } else {
      myCards[p] = bm;
    }

    userModel
      ..put(MY_CARDS, myCards.map((bm) => bm.items).toList())
      ..updateItems();
  }

  void saveTransaction(String msg, RavePaymentVerification resp) {
    final transMap = Transactions(
            transactionRef: resp.txRef,
            toAccount: "Xendam wallet credited",
            narration: "You funded your account from your credit card",
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
      acctBalances[p].amount = acctBalances[p].amount + resp.amount.toDouble();
      userModel
        ..put(ACCOUNT_BALANCES, acctBalances.map((e) => e.toModel()).toList())
        ..updateItems();

      showMessage(context, Icons.check, green_dark, "Transaction Successful",
          "Your xendam account has successfully been funded",
          delayInMilli: 900, cancellable: false, onClicked: (_) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    });
  }
}
