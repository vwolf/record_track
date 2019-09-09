import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

/// Read file from local storage
///
class ReadFile {
  String contents;
  String filePath;

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
}