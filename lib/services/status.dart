
import 'dart:io';

//import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:connectivity/connectivity.dart';

import 'settings.dart';
import 'permissionService.dart';

/// Internet status
/// Geolocation status
/// Datastorage access status
class AppStatus {

  AppStatus._();
  static final AppStatus appStatus = AppStatus._();

  ConnectivityResult connectivityResult = ConnectivityResult.none;

  /// paths
  String gpxFileDirectoryString;

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

  /// Use [Path_Provider] to get path to external storage directory.
  /// Default directory is Tracks. This can be changed using settings.
  /// Here we only search in internal storage
  ///
  void setDirectorys() async {
    var permission = await RequestPermissions().requestPermission(PermissionGroup.storage);
    if (permission) {
      await setStoragePath().then((result) {
        // no directory at internal storage path then create empty directory
        gpxFileDirectoryString = Settings.settings.pathTracksInternal;
        if (Directory(gpxFileDirectoryString).existsSync() == false) {
          Directory(gpxFileDirectoryString).create(recursive: true);
        }
      });
    }
  } 
  
  /// Storage
  /// 
  /// Set path to internal Storage and to external SDCard.
  /// Add to [Settings]
  /// Uses  path_provider_ex,
  ///
  Future<bool> setStoragePath() async {
    List<StorageInfo> storageInfo;

    // storage Android
    if (Platform.isAndroid) {
      
        // storage internal
        var dir = await getExternalStorageDirectory();
        Settings.settings.pathTracksInternal = "${dir.path}/${Settings.settings.defaultTrackDirectory}";

        // storage sd card (external)
        try {
          storageInfo = await PathProviderEx.getStorageInfo();
        } on PlatformException {}

        //if (mounted) {
          if (storageInfo.length >= 1) {
            Settings.settings.externalSDCard = storageInfo[1].rootDir;
          }
        //}

        return true;      
    }


    return false;
  }
  
}