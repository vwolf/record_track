import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_track/services/permissionService.dart';
import 'package:record_track/services/settings.dart';


/// Write file to local or external (SD card)
///
class WriteFile {

  WriteFile();



}

class WriteFileExternal {
  final String filePath;
  String fileContent;

  //WriteFileExternal(); //: externalStoragePermission = requestPermission();

  WriteFileExternal(this.filePath, this.fileContent);


  bool externalStoragePermission = false;

  Future requestPermission() async {
    var permission = await RequestPermissions().requestPermission(PermissionGroup.storage);
    return permission;

//    await RequestPermissions().requestPermission(PermissionGroup.storage).then((result) {
//      print("requestPermission storage: $result");
//      return result;
//    });
  }

  Future newDirectory( String directoryName) {

  }

  /// Write to [File] at [filePath].
  /// Creates [File] if [File] at [filePath] does not exists.
  ///
  Future writeToFile( String filePath, String fileContent) async {
    var request = await requestPermission();
    print("request: $request");
    if (request == true) {
      final dir = await getExternalStorageDirectory();
      final path = dir.path;
      // filePath = "/storage/C4AB-1401/Android/data/com.devwolf.record_track/files/test.gpx";
      File file = File(filePath);
      File result = await file.writeAsString(fileContent);

      print("writeToFile.result.path: ${result.path}");
      return true;
    }


  }

  Future<File> openFile( String filePath) async {

  }


}