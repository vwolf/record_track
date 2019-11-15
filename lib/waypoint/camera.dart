import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';


class TakePicture extends StatefulWidget {
  final CameraDescription camera;

  TakePicture({
    Key key,
    @required this.camera,
  }) : super(key: key);


  @override
  TakePictureState createState() => TakePictureState();
}


class TakePictureState extends State<TakePicture> {

  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text("Take a picture"),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return Center(child: CircularProgressIndicator(),);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        onPressed: () async {
          try {
            await _initializeControllerFuture;

            //final path = join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');
            final path = join((await getExternalStorageDirectory()).path, '${DateTime.now()}.png');
            await _controller.takePicture(path);

            _navigatePictureScreen(context, path);
//            Navigator.push(
//              context,
//              MaterialPageRoute(
//                builder: (context) => DisplayPictureScreen(imagePath: path),
//              ),
//            );
          } catch (e) {
            print (e);
          }
        },
      ),
    );
  }

  /// Navigate to screen with taken image
  /// If return is image path ...
  ///
  _navigatePictureScreen(BuildContext context, String path) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DisplayPictureScreen(imagePath: path,))
    );
    print(result);
    if (result != "return") {
      Navigator.pop(context, result);
    }
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    //RenderBox renderBox = context.findRenderObject();
    //Size size = renderBox.size;
    FileImage _image = FileImage(File(imagePath));

    return Scaffold(
      appBar: AppBar(
        title: Text("Display the picture"),
      ),

      body:
      Container(
        //height: _image.height,
        //color: Colors.blueAccent,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          image: DecorationImage(
            image: FileImage(File(imagePath)),
            fit: BoxFit.contain,
          )
        ),
        //child: Image.file(File(imagePath)),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
//          FloatingActionButton(
//            heroTag: "returnpath",
//            child: Icon(Icons.save),
//            onPressed: () async {
//              Navigator.pop(context, imagePath);
//            },
//          ),
          FloatingActionButton(
            heroTag: "cancel",
            child: Icon(Icons.close),
            onPressed: () async {
              Navigator.pop(context, "return");
            },
          ),
        ],
      )
    );
  }
}