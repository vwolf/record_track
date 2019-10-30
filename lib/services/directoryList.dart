import 'dart:io';

import 'package:flutter/material.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

typedef MapPathCallback = void Function(String mapPath);

/// Kind of directory browser for internal and external (SDCard) storage
///
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

  Directory externalStorageDir;

  //var currentDirPath = startPath;

  //var currentDir = Directory(widget.startPath);

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


  Future<List<String>> _directoryList() async {
    var filesList = List<String>();

    if (externalStorageDir == null) {
     // externalStorageDir = await getExternalStorageDirectory();
      externalStorageDir = Directory(startPath);
      List<FileSystemEntity>directoryList = externalStorageDir.listSync(recursive: false, followLinks: false);

      for (var file in directoryList) {
        filesList.add(file.path.split('/').last);

      }
    } else {
      externalStorageDir.list(recursive: false, followLinks: false)
          .listen((FileSystemEntity entity) {
            filesList.add(entity.path.split('/').last);
      });
    }

    return filesList;
  }


  /// ListView with directorys at path
  /// Trailing icon (arrow) selects directory
  /// Tap on directory name returns the directory path
  ///
  Widget buildDirectoryList(BuildContext context, List<String> snapshot) {
    return Container(
      child: Expanded(
        child: ListView.builder(
          itemCount: snapshot.length,
            itemBuilder: (context, index) {
              return ListTile(
                onTap: () {
                  widget.callback("${snapshot[index]}");
                },
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                title: Text(snapshot[index]),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    _listDirectory(snapshot[index]);
                  },
                ),
              );
            }),
      ),
    );
  }

  _listDirectory(String directory) async {
    var directoryContent = List<String>();

    externalStorageDir = Directory('${externalStorageDir.path}/$directory');
    Directory(externalStorageDir.path).list(recursive: false, followLinks: false)
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