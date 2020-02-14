import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:credpal/app/baseApp.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'assets.dart';

class BaseModel {
  Map<String, Object> items = new Map();
  Map<String, Object> itemUpdate = new Map();
  Map<String, Map> itemUpdateList = new Map();

  BaseModel({Map items, DocumentSnapshot doc}) {
    if (items != null) {
      Map<String, Object> theItems = Map.from(items);
      this.items = theItems;
    }
    if (doc != null && doc.exists) {
      this.items = doc.data;
      this.items[DOCUMENT_ID] = doc.documentID;
    }
  }

  void put(String key, Object value) {
    items[key] = value;
    itemUpdate[key] = value;
  }

  void putInList(String key, Object value, bool add) {
    List itemsInList = items[key] == null ? List() : List.from(items[key]);
    if (add) {
      if (!itemsInList.contains(value)) itemsInList.add(value);
    } else {
      itemsInList.removeWhere((E) => E == value);
    }
    items[key] = itemsInList;

    Map update = Map();
    update[ADD] = add;
    update[VALUE] = value;

    itemUpdateList[key] = update;
  }

  void remove(String key) {
    items.remove(key);
    itemUpdate[key] = null;
  }

  String getObjectId() {
    Object value = items[DOCUMENT_ID];
    return value == null || !(value is String) ? "" : value.toString();
  }

  List getList(String key) {
    Object value = items[key];
    return value == null || !(value is List) ? new List() : List.from(value);
  }

  List<Object> addToList(String key, Object value, bool add) {
    List<Object> list = items[key];
    list = list == null ? new List<Object>() : list;
    if (add) {
      if (!list.contains(value)) list.add(value);
    } else {
      list.remove(value);
    }
    put(key, list);
    return list;
  }

  Map getMap(String key) {
    Object value = items[key];
    return value == null || !(value is Map)
        ? new Map<String, String>()
        : Map.from(value);
  }

  BaseModel getModel(String key) {
    return BaseModel(items: getMap(key));
  }

  Object get(String key) {
    return items[key];
  }

  String getUserId() {
    Object value = items[USER_ID];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getImage() {
    Object value = items[IMAGE];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getString(String key) {
    Object value = items[key];

    return value == null || !(value is String) ? "" : value.toString();
  }

  String getEmail() {
    Object value = items[EMAIL];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getPassword() {
    Object value = items[PASSWORD];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getNotificationTitle() {
    Object value = items[NOTIFICATION_TITLE];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getNotificationSender() {
    Object value = items[NOTIFICATION_SENDER_NAME];
    return value == null || !(value is String) ? "" : value.toString();
  }

  bool isEmpty() {
    return items.isEmpty;
  }

  bool myItem() {
    return getUserId() == (userModel.getUserId());
  }

  int getInt(String key) {
    Object value = items[key];
    return value == null || !(value is int) ? 0 : (value);
  }

  int getType() {
    Object value = items[TYPE];
    return value == null || !(value is int) ? 0 : value;
  }

  double getDouble(String key) {
    Object value = items[key];
    return value == null || !(value is num)
        ? 0.0
        : num.parse("$value").toDouble();
  }

  int getTime() {
    Object value = items[TIME];
    return value == null || !(value is int) ? 0 : value;
  }

  bool getBoolean(String key) {
    Object value = items[key];
    return value == null || !(value is bool) ? false : value;
  }

  bool isAdminItem() {
    return getBoolean(IS_ADMIN);
  }

  bool isMaugost() {
    return getEmail() == ("ammaugost@gmail.com");
  }

  String getUId() {
    Object value = items[USER_ID];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getFullName() {
    Object value = items[FULL_NAME];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getCity() {
    Object value = items[CITY];
    return value == null || !(value is String) ? "" : value.toString();
  }

  String getToken() {
    Object value = items[TOKEN_ID];
    return value == null || !(value is String) ? "" : value.toString();
  }

  int getIsOnline() {
    Object value = items[IS_ONLINE];
    return value == null || !(value is int) ? 0 : (value);
  }

  bool getCanShowDate() {
    Object value = items[SHOW_DATE];
    return value == null || !(value is bool) ? false : value;
  }

  bool getIsVerified() {
    Object value = items[IS_VERIFIED];
    return value == null || !(value is bool) ? false : value;
  }

  bool getIsNetwork() {
    Object value = items[IS_NETWORK_IMAGE];
    return value == null || !(value is bool) ? false : value;
  }

  String getMessage() {
    Object value = items[MESSAGE];
    return value == null || !(value is String) ? "" : value.toString();
  }

  int getStatus() {
    Object value = items[NOTIFICATION_STATUS];
    return value == null || !(value is int) ? 0 : (value);
  }

  int getNotificationType() {
    Object value = items[NOTIFICATION_TYPE];
    return value == null || !(value is int) ? 0 : (value);
  }

  void updateItemsLocally(
      {bool updateTime = true, int delaySeconds = 0}) async {
    String dName = items[DATABASE_NAME];
    SharedPreferences pref = await SharedPreferences.getInstance();
    Map data = jsonDecode(pref.getString(dName) ?? "{}");

    for (String k in itemUpdate.keys) {
      data[k] = itemUpdate[k];
    }

    for (String k in itemUpdateList.keys) {
      Map update = itemUpdateList[k];
      bool add = update[ADD];
      var value = update[VALUE];

      List dataList = data[k] == null ? List() : List.from(data[k]);
      if (add) {
        if (!dataList.contains(value)) dataList.add(value);
      } else {
        dataList.removeWhere((E) => E == value);
      }
      data[k] = dataList;
    }
    pref.setString(dName, jsonEncode(data));
  }

  void deleteItemLocally() async {
    String dName = items[DATABASE_NAME];
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.remove(dName);
  }

  void saveItemLocally(String name, bool addMyInfo,
      {document, onComplete, onError}) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString(name, jsonEncode(items)).whenComplete(() {
      onComplete();
    }).catchError(onError);
  }

  void saveItem(String name, bool addMyInfo, {document, onComplete, onError}) {
    processSave(name, addMyInfo);
    if (document == null) {
      Firestore.instance.collection(name).add(items);
    } else {
      items[OBJECT_ID] = document;
      Firestore.instance
          .collection(name)
          .document(document)
          .setData(items)
          .then((_) {
        if (null != onComplete) onComplete();
      }, onError: (e) {
        if (null != onError) onError(e);
      }).catchError((e) {
        if (null != onError) onError(e);
      });
    }
  }

  processSave(String name, bool addMyInfo) {
    items[VISIBILITY] = PUBLIC;
    items[DATABASE_NAME] = name;
    items[UPDATED_AT] = FieldValue.serverTimestamp();
    items[CREATED_AT] = FieldValue.serverTimestamp();
    items[TIME] = DateTime.now().millisecondsSinceEpoch;
    items[TIME_UPDATED] = DateTime.now().millisecondsSinceEpoch;
    if (name != (USER_BASE) &&
        name != (APP_SETTINGS_BASE) &&
        name != (NOTIFY_BASE)) {
      if (addMyInfo) addMyDetails();
    }
//    if (name == VOICE_BASE || name == POSTS_BASE) {
//      items[FOLLOWERS] = userModel.getList(FOLLOWERS);
//    }
  }

  void addMyDetails() {
    items[USER_ID] = userModel.getObjectId();
    items[IMAGE] = userModel.getString(IMAGE);
    items[FULL_NAME] = userModel.getString(FULL_NAME);
    items[BY_ADMIN] = userModel.isAdminItem();
    items[GENDER] = userModel.getInt(GENDER);
    items[COUNTRY] = userModel.getString(COUNTRY);
    items[EMAIL] = userModel.getString(EMAIL);
    items[PHONE_NO] = userModel.getString(PHONE_NO);
  }

  void updateItems({bool updateTime = true, int delaySeconds = 0}) async {
    Future.delayed(Duration(seconds: delaySeconds), () async {
//      bool connected = await isConnected();
//      if (!connected) {
//        delaySeconds = delaySeconds + 10;
//        delaySeconds = delaySeconds >= 60 ? 0 : delaySeconds;
//        print("not connected retrying in $delaySeconds seconds");
//        updateItems(updateTime: updateTime, delaySeconds: delaySeconds);
//        return;
//      }

      String dName = items[DATABASE_NAME];
      String id = items[OBJECT_ID];

      DocumentSnapshot doc = await Firestore.instance
          .collection(dName)
          .document(id)
          .get(source: Source.server)
          .catchError((error) {
        delaySeconds = delaySeconds + 10;
        delaySeconds = delaySeconds >= 60 ? 0 : delaySeconds;
        print("$error... retrying in $delaySeconds seconds");
        updateItems(updateTime: updateTime, delaySeconds: delaySeconds);
        return;
      });
      if (doc == null) return;
      if (!doc.exists) return;

      Map data = doc.data;
      for (String k in itemUpdate.keys) {
        data[k] = itemUpdate[k];
      }
      for (String k in itemUpdateList.keys) {
        Map update = itemUpdateList[k];
        bool add = update[ADD];
        var value = update[VALUE];

        List dataList = data[k] == null ? List() : List.from(data[k]);
        if (add) {
          if (!dataList.contains(value)) dataList.add(value);
        } else {
          dataList.removeWhere((E) => E == value);
        }
        data[k] = dataList;
      }

      if (updateTime) {
        data[UPDATED_AT] = FieldValue.serverTimestamp();
        data[TIME_UPDATED] = DateTime.now().millisecondsSinceEpoch;
      }

      doc.reference.setData(data);
    });
  }
}
