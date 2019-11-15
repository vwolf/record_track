import 'dart:io';

import 'package:flutter/material.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
//import 'package:path_provider/path_provider.dart';

typedef MapPathCallback = void Function(String mapPath);

/// Kind of directory browser for internal and external (SDCard) storage
///
/// - @param [callback]
/// - @param [startPath]
class DirectoryList extends StatefulWidget {
  final callback;
  final startPath;

  DirectoryList(this.callback, this.startPath);

  @override
  DirectoryListState createState() => DirectoryListState(startPath);
}


class DirectoryListState extends State<DirectoryList> {
  final startPath;

  DirectoryListState(this.startPath);

  Directory currentDir;
  int selectedDirectory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Directory"),
      ),

      body: Center(
        child: Column(
          children: <Widget>[
            FutureBuilder(
              future: _directoryList(),
              builder: (BuildContext context, AsyncSnapshot<List<String>>snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text("Loading...");
                } else {
                  List<String>directoryContent = snapshot.data;
                  return buildDirectoryList(context, directoryContent);
                }
              },
            )
          ],
        ),
      ),
    );
  }

  /// List of directory's in [currentDir].
  /// For first level set [currentDir] to [startDir]
  ///
  Future<List<String>> _directoryList() async {
    var filesList = List<String>();

    if (currentDir == null) {
      currentDir = Directory(startPath);
    }

    List<FileSystemEntity>directoryList = currentDir.listSync(recursive: false, followLinks: false);

    for (var file in directoryList) {
      FileSystemEntity.isDirectory(file.path).then((isDir) {
        if (isDir) {
          filesList.add(file.path.split('/').last);
        } else {
          filesList.add(file.path.split('/').last);
        }
      });
    }

    return filesList;
  }



  /// ListView with directory's at path
  /// Trailing icon (check mark) selects directory
  /// Tap on directory name returns the directory path
  ///
  Widget buildDirectoryList(BuildContext context, List<String> snapshot) {
    return Container(
      child: Expanded(
        child: ListView.builder(
          itemCount: snapshot.length,
            itemBuilder: (context, index) {
            if(_directoryCheck(snapshot[index])) {
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                title: Text(snapshot[index]),
                trailing: IconButton(
                  icon: Icon(Icons.check,
                  color: selectedDirectory == index ? Colors.white : Colors.blueGrey),
                  onPressed: () {
                    print("Index at onPressed: $index");
                    setState(() {
                      selectedDirectory = index;
                    });

                    widget.callback("${currentDir.path}/${snapshot[index]}");
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  _listDirectory(snapshot[index]);
                },
              );
            } else {
              return ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                title: Text(snapshot[index]),
              );
            }
          }),
      ),
    );
  }

  /// Path is an directory?
  ///
  /// - @param [path]
  bool _directoryCheck(String path) {
    bool isDir = FileSystemEntity.isDirectorySync("${currentDir.path}/$path");

    return isDir;
  }


  /// Get directory's in directory, then rebuild
  _listDirectory(String directory) async {
    var directoryContent = List<String>();

    currentDir = Directory('${currentDir.path}/$directory');
    Directory(currentDir.path).list(recursive: false, followLinks: false)
    .listen((FileSystemEntity entity) {
      FileSystemEntity.isDirectory(entity.path).then((isDir) {
        if (isDir) {
          directoryContent.add(entity.path);
        }
      });
    })
    .onDone(() {
      buildDirectoryList(context, directoryContent);
      setState(() {

      });
    });
  }
}