import 'package:common_utils/common_utils.dart';
import 'package:credpal/EnterAccess.dart';
import 'package:credpal/dialogs/baseDialogs.dart';
import 'package:credpal/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_money_formatter/flutter_money_formatter.dart';
import 'package:ravepay/ravepay.dart' as rave;

import 'MainHomePg.dart';
import 'app/baseApp.dart';
import 'main_screens/Home.dart';
import 'rave/RaveApi.dart';

class EnterAccount extends StatefulWidget {
  final int amountToPull;
  final PayType type;

  const EnterAccount({Key key, this.amountToPull, this.type}) : super(key: key);

  @override
  _EnterAccountState createState() => _EnterAccountState();
}

class _EnterAccountState extends State<EnterAccount> {
  inputField(
      {@required TextEditingController controller,
      String title,
      String hint,
      bool isPassword = false,
      bool showPassword = false,
      bool isBtn = false,
      bool isNumber = false,
      int maxLines = 1,
      onPassChanged,
      onBtnPressed,
      onChanged}) {
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
              keyboardType: isNumber ? TextInputType.number : null,
              placeholder: hint,
              readOnly: isBtn,
              obscureText: showPassword,
              onChanged: onChanged,
              suffix: isPassword
                  ? Container(
                      decoration: BoxDecoration(
                          color: blue,
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

  bool accountRetrieved = false;
  bool otpRetrieved = false;
  String transactionRef;
  RaveBanks bankSelected;
  rave.Bank bankChosen;

  var bank = TextEditingController();
  var acctNum = TextEditingController();
  var narration = TextEditingController();
  RaveAccountVerification accountInfo;

  double get amountToCharge => widget.amountToPull.roundToDouble();

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

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool saveBank = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  final progressId = getRandomId();

  verifyAccountNumber() async {
    raveApi.transfers.accountVerification(
        recipientAccount: acctNum.text,
        destBankCode: bankSelected.bankCode,
        currency: "NGN",
        country: "NG",
        onComplete: (account) {
          accountRetrieved = true;
          accountInfo = account;
          setState(() {});
          print(account.raveModel.items);
          showProgress(false, progressId, context);
        },
        onError: (e) {
          accountRetrieved = false;
          accountInfo = null;
          setState(() {});
          showProgress(false, progressId, context);
          showMessage(context, Icons.error, red, "Account Error", e,
              delayInMilli: 900, cancellable: false);
        });
  }

  loadAvailableBanks() async {
    raveApi.miscellaneous.getSupportedBanks("NG").then((banks) {
      raveBanks = banks;
      raveBanks.sort((a, b) => a.bankName.compareTo(b.bankName));
      if (mounted) setState(() {});
    }).catchError(onError);
  }

  onError(e) {
    showProgress(false, progressId, context);
    showMessage(context, Icons.error, red, "Transaction Error", e.message,
        delayInMilli: 900, cancellable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: white,
        iconTheme: IconThemeData(color: black),
        title: Text(
          "Account Information",
          style: textStyle(true, 20, black),
        ),
        centerTitle: false,
        elevation: 0,
        actions: <Widget>[
          //if (!isZeroValue)
          Container(
            padding: EdgeInsets.all(10),
            child: FlatButton(
              onPressed: createCharge,
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
      body: pageBody(),
    );
  }

  pageBody() {
    return ListView(
      padding: EdgeInsets.all(12),
      children: <Widget>[
        inputField(
            controller: bank,
            title: "Bank Name",
            hint: "Select your bank",
            isBtn: true,
            onBtnPressed: () {
              if (null == raveBanks) {
                showProgress(true, progressId, context,
                    msg: "Reteriving supported banks", cancellable: true);
                loadAvailableBanks();
                return;
              }
              pushAndResult(
                  context,
                  listDialog(
                    raveBanks.map((bm) => bm.bankName).toList(),
                    //usePosition: false,
                  ), result: (_) async {
                if (null == _) return;
                setState(() {
                  bankSelected = raveBanks[_];
                  bank.text = raveBanks[_].bankName;
                });
              });
            }),
        inputField(
            controller: acctNum,
            isNumber: true,
            title: "Account Number",
            hint: "Enter account number",
            onChanged: (String s) {
              if (s.length < 10) {
                setState(() {
                  accountRetrieved = false;
                  narration.clear();
                  accountInfo = null;
                });
                return;
              }

              if (s.length == 10) {
                showProgress(true, progressId, context,
                    msg: "Verifying Account");
                verifyAccountNumber();
              }
            }),
        if (accountRetrieved) retrievedAccountView(),
      ],
    );
  }

  retrievedAccountView() {
    var formatted = FlutterMoneyFormatter(
        amount: widget.amountToPull.toDouble() + 50,
        settings: MoneyFormatterSettings(symbol: "NGN"));
    return Column(
      children: <Widget>[
        Container(
            decoration: BoxDecoration(
                color: blue6, borderRadius: BorderRadius.circular(10)),
            padding: EdgeInsets.all(15),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 100,
                      child: Text(
                        "Account Name",
                        style: textStyle(false, 12, white),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        accountInfo.accountName,
                        style: textStyle(true, 14, white),
                      ),
                    ),
                  ],
                ),
                addSpace(10),
                Row(
                  children: <Widget>[
                    Container(
                      width: 100,
                      child: Text(
                        "Account Number",
                        style: textStyle(false, 12, white),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        accountInfo.accountNumber,
                        style: textStyle(true, 14, white),
                      ),
                    ),
                  ],
                ),
              ],
            )),
        if (widget.type != PayType.ADD) ...[
          addSpace(10),
          inputField(
              controller: narration,
              maxLines: 4,
              title: "Message ",
              hint: "Enter a message for this transaction"),
        ],
        if (widget.type == PayType.ADD)
          checkViewItem(
              "Would you want to save this card to be used in the future?",
              active: saveBank, onClicked: (_) {
            setState(() {
              saveBank = _;
            });
          })
      ],
    );
  }

  checkViewItem(String title, {bool active = false, onClicked}) {
    return InkWell(
      onTap: () {
        onClicked(!active);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Text(
                title,
                style: textStyle(false, 16, black.withOpacity(active ? 1 : .7)),
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

  createCharge() async {
    if (null == bankSelected) {
      toast(scaffoldKey, "Please select your bank");
      return;
    }

    if (acctNum.text.isEmpty) {
      toast(scaffoldKey, "Please enter your account number");
      return;
    }

    if (narration.text.isEmpty && widget.type != PayType.ADD) {
      toast(scaffoldKey, "Please enter a narration for transaction");
      return;
    }

    if (widget.type == PayType.ADD) {
      chargeBankAccount();
      return;
    }

    checkAdminBalance(canTransfer: () {
      transferFundsTo();
    });
  }

  checkAdminBalance({canTransfer}) async {
    showProgress(true, progressId, context, msg: "Initiating Transfer...");

    raveApi.transfers.walletTransferBalance(
        currency: countryCurrency,
        onComplete: (balance) {
          final adminBalance = balance.availableBalance;
          bool needsTopUp = NumUtil.greaterThan(amountToCharge, adminBalance);

          if (needsTopUp) {
            showProgress(false, progressId, context);
            showMessage(context, Icons.error, red, "Cannot Transact",
                "Transaction cannot be processed at this time please contact admin...",
                delayInMilli: 900, cancellable: false);
            return;
          }
          if (null == canTransfer) return;
          canTransfer();
        },
        onError: onError);
  }

  transferFundsTo() async {
    raveApi.transfers.transferToAfrica(
        bankName: bankSelected.bankName,
        accountNumber: accountInfo.accountNumber,
        recipient: null,
        amount: amountToCharge.toString(),
        narration: narration.text,
        currency: countryCurrency,
        reference: progressId,
        beneficiaryName: accountInfo.accountName,
        destinationBranchCode: bankSelected.bankCode,
        debitCurrency: countryCurrency,
        onComplete: (transfer) {
          //showProgress(false, progressId, context);
          //print(transfer.raveModel.items);
          //return;
          saveTransaction(null, transfer);
        },
        onError: onError);
  }

  chargeBankAccount() async {
    showProgress(true, progressId, context, msg: "Requesting OTP...");
    raveApi.charge.initiateBankPayment(
        bankCode: bankSelected.bankCode,
        accountNumber: acctNum.text,
        currency: countryCurrency,
        country: countryCode,
        amount: amountToCharge.toString(),
        email: userModel.getEmail(),
        phoneNumber: userModel.getEmail(),
        firstName: userModel.getFullName(),
        lastName: userModel.getFullName(),
        txReference: progressId,
        onComplete: (msg) {
          showProgress(false, progressId, context);
          showMessage(context, Icons.check, green, "Payment Successful",
              "You have successfully funded your wallet account: MSG $msg",
              delayInMilli: 900, cancellable: true);
        },
        onError: (e) {
          showProgress(false, progressId, context);
          showMessage(context, Icons.error, red, "Charge Error", e,
              delayInMilli: 900, cancellable: false);
        },
        validatorBuilder: (bool otp, String respMsg, String flwRef) {
          print("Validate $otp repsonse $respMsg tx $flwRef");
          showProgress(false, progressId, context);
          if (otp) enterTransactionOTP(flwRef);
        });
  }

  enterTransactionOTP(String flwRef) async {
    Future.delayed(Duration(milliseconds: 500), () {
      pushAndResult(
          context,
          EnterAccess(
            title: "Enter OTP",
            narration: narration.text,
            payType: widget.type,
            flwRef: flwRef,
          ), result: (String otp) {
        if (otp.isEmpty) {
          showMessage(context, Icons.error, red, "Terminated!",
              "This Transaction was canceled by you.",
              delayInMilli: 900, cancellable: false);
          return;
        }
      });
    });
  }

  void saveTransaction(RavePaymentVerification resp, RaveTransfer transfer) {
    String txRef = null == resp ? (transfer.reference) : resp.txRef;
    double amount = amountToCharge;

    final transMap = Transactions(
            transactionRef: txRef,
            toAccount: "Xendam wallet debited",
            narration:
                "You have made a transfer to ${accountInfo.accountName} from your wallet",
            amount: amount,
            isDebit: true,
            date: DateTime.now())
        .toModel();

    BaseModel transModel = BaseModel(items: transMap);
    transModel.saveItem(TRANSACTION_BASE, true, document: txRef,
        onComplete: () {
      showProgress(false, progressId, context);

      int savingsPos = acctBalances
          .indexWhere((element) => element.title == "Total Savings");

      int transferPos = acctBalances
          .indexWhere((element) => element.title == "Total Transfers");

      acctBalances[savingsPos].amount =
          acctBalances[savingsPos].amount - amount.toDouble();

      acctBalances[transferPos].amount =
          acctBalances[transferPos].amount + amount.toDouble();

      userModel
        ..put(ACCOUNT_BALANCES, acctBalances.map((e) => e.toModel()).toList())
        ..updateItems();

      showMessage(context, Icons.check, green_dark, "Transaction Successful",
          "Your transfer to ${accountInfo.accountName} was successful.",
          delayInMilli: 900, cancellable: false, onClicked: (_) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    });
  }
}
