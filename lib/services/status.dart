import 'dart:io';

import 'package:connectivity/connectivity.dart';

/// Internet status
/// Geolocation status
/// Datastorage access status
class AppStatus {

  AppStatus._();
  static final AppStatus appStatus = AppStatus._();

  ConnectivityResult connectivityResult = ConnectivityResult.none;

  checkConnection() async {
    connectivityResult = await (Connectivity().checkConnectivity());
    print("${connectivityResult.toString()}");

    if (connectivityResult == ConnectivityResult.mobile) {
      print("CONNECTION: MOBILE");
    } else if (connectivityResult == ConnectivityResult.wifi) {
      print("CONNECTION: WIFI");
    } 
    

    // try {
    //   final result = await InternetAddress.lookup('google.com');
    //   if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
    //     print("connected");
    //   }
    // } on SocketException catch(_) {
    //     print("not connected");
    // }
  }
  
}