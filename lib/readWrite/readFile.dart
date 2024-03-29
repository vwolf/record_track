import 'dart:async';
import 'dart:io';
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Read file from local storage
///
class ReadFile {
  String contents;
  String filePath;
  String _fileName;

  Future<String> get _localPath async {
    print("local_file _localPath");
    final directory = await getApplicationDocumentsDirectory();
    print("local_file directory: $directory");
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/$_fileName');
  }

  Future<String> getPath() {
    return _getPath();
  }

  /// Private 
  Future<String> _getPath() async {
    try {
      String fPath = await FilePicker.getFilePath(type: FileType.ANY);
      if ( filePath == '' ) {
        return null;
      }
      debugPrint("ReadFile selected file path: $fPath");
      return fPath;
    } on Platform catch (e) {
      debugPrint("Platform FilePicker error: $e");
    }

    return null;
  }


  Future<String> readFile(String path) async {
    try {
      String fileContents = await File(path).readAsString();
      return fileContents;
    } catch (e) {
      debugPrint("Read File Error: $e ");
    }

    return null;
  }


  /// Public methode to get file path and contents 
  /// 
  Future<List> getFilePath() async {
    String selectedPath;
    try {
      selectedPath = await FilePicker.getFilePath(type: FileType.ANY);
      if (selectedPath == '') {
        return null;
      }
      // file type check
      String fileType = p.extension(selectedPath);
      if (fileType != '.gpx') {
        debugPrint("Wrong file type!");
        return null;
      }

      loadFile(selectedPath);
      return [selectedPath, contents];

    } on Platform catch (e) {
      debugPrint("Platform Filepicker error: $e");
    }
    return null;
  }


  Future<bool> loadFile(String path) async {
    try {
      contents = await File(path).readAsString();
      return true;
    } catch (e) {
      return null;
    }
  }

  /// Write a Map<String, String> as JSON string to file
  ///
  writeMapToJson(String fileName, Map<String, String> content) async{
    _fileName = fileName;
    try {
      final file = await _localFile;
      //bool fileExist = file.existsSync();
      file.writeAsStringSync(jsonEncode(content));
    } on FileSystemException  {
      return "Write Error";
    }
  }

  /// Add a key:value to file
  /// Create file if it not exists
  ///
  addToJson(String fileName, String key, String value) async {
    _fileName = fileName;
    Map<String, String> content = {key: value};
    try {
      final file = await _localFile;
      if (file.existsSync()) {
        Map<String, dynamic> fileContent = json.decode(file.readAsStringSync());
        fileContent.addAll(content);
        file.writeAsStringSync(jsonEncode(fileContent));
      } else {
        print("Can't add to file! No file ${file.path}");
        print("Create file ${file.path}");
        writeMapToJson(fileName, content);
      }
    } on FileSystemException {
      return null;
    }
  }

  /// Read JSON strin from local file and return as map
  ///
  Future<Map<String, dynamic>> readJson(String fileName) async {
    print("Local_file.readJson $fileName");
    _fileName = fileName;
    try {
      final file =  await _localFile;
      print("local file to read: $fileName");
      if (file.existsSync()) {
        var fileContent = file.readAsStringSync();
        Map<String, dynamic> contentAsMap = jsonDecode(fileContent);

        return contentAsMap;
      } else {
        return {};
      }

    } catch (e) {
      return null;
    }
  }
}