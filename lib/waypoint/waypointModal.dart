import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:audio_recorder/audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_track/services/permissionService.dart';
import 'waypoint.dart';
import 'camera.dart';

/// Dialog to create or update a [Waypoint]
///
class WayPointModal extends StatefulWidget {
  final String type;
  final WayPoint wayPoint;

  WayPointModal(this.type, this.wayPoint);

  @override
  WayPointModalState createState() => WayPointModalState();
}


class WayPointModalState extends State<WayPointModal> {

  LocalFileSystem _localFileSystem = LocalFileSystem();

  bool update = false;
  bool editable = true;

  final _formkey = GlobalKey<FormState>();
  TextEditingController _textCtrlName = TextEditingController();
  TextEditingController _textCtrlDescription = TextEditingController();

  List<AssetImage> images = [];
  List<String> imagesPath = [];

  OverlayEntry _imageOverlay;

  // Audio recording
  Recording _recording = new Recording();
  bool _isRecording = false;
  String audioPath;
  List<String> recordings = [];

  @override
  void initState() {
    super.initState();
    //_textCtrlName.addListener(onChange);
    if (widget.wayPoint.item.name != null ) {

      _textCtrlName.text = widget.wayPoint.item.name;
      _textCtrlDescription.text = widget.wayPoint.item.info;
      if (widget.wayPoint.item.images.isNotEmpty) {
        // cast to string - item.images is <dynamic>
        imagesPath = widget.wayPoint.item.images.cast<String>();
      }
      if (widget.type != "show") {
        update = true;
      }
    }

    if (widget.type == "show" ) {
      editable = false;
    }
  }

  @override
  void dispose() {
    _textCtrlName.dispose();
    _textCtrlDescription.dispose();

    super.dispose();
  }


  void onChange() {
    print("onChange");
  }

  _getContent() {
    return SimpleDialog(
      title: widget.type == "mapPoint" ? Text("Point on map") : Text("Point on track"),
      children: <Widget>[
        Form(
          key: _formkey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Divider(height: 10.0, color: Colors.white70,),
              Padding(
                padding: EdgeInsets.only(left: 12.0, right: 12.0),
                child: TextFormField(
                  enabled: editable,
                  controller: _textCtrlName,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: "Name",
                  ),
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 12.0, right: 12.0, bottom: 4.0),
                child: TextField(
                  enabled: editable,
                  controller: _textCtrlDescription,
                  keyboardType: TextInputType.text,
                  maxLines: null,
                  decoration: InputDecoration(
                    labelText: "Description",
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 12.0, right: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.camera),
                      onPressed: () {
                        //takePicture();
                        cameraPicker();
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.photo_library),
                      onPressed: () {
                        selectPicture();
                      },
                    ),
                    IconButton(
                      icon: Icon( _isRecording ? Icons.mic_off : Icons.mic),
                      onPressed: () {
                        !_isRecording ? stopRecordingAudio() : startRecordingAudio();
                      },
                    )
                  ],
                ),
              ),
              _imageRow,
              Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: _dialogOptions,
              ),

            ],
          )
        ),
      ]
    );
  }

  Widget get _dialogOptions {
    if (editable == true) {
      return Row(

        mainAxisAlignment: MainAxisAlignment.start,
        //mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: SimpleDialogOption(

              child: !update ? Text("Add") : Text("Update"),
              onPressed: () {
                if (_formkey.currentState.validate()) {
                  widget.wayPoint.item.name = _textCtrlName.text;
                  widget.wayPoint.item.info = _textCtrlDescription.text;
                  widget.wayPoint.item.images = imagesPath.isNotEmpty ? imagesPath : [];

                  Navigator.pop(context, "ADD");
                }

              },
            ),
          ),

          Expanded(
            child: SimpleDialogOption(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.pop(context, "CANCEL");
              },
            ),
          ),

          Expanded(
            child: SimpleDialogOption(
              child: update ? Text("Delete") : Text(""),
              onPressed: () {
                Navigator.pop(context, "DELETE");
              },
            ),
          ),

        ],
      );
    } else {
      return Container();
    }
  }


  Widget get _imageRow {
    if (imagesPath.isNotEmpty) {
      return Container(
        width: double.maxFinite,
        height: 64.0,
        color: Colors.orangeAccent,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: imagesPath.map((path) => InkWell(
            onTap: () {
              //_imageOverlay = imageOverlay(FileImage(File(path)));
              //Overlay.of(context).insert(_imageOverlay);
              _navigatePictureScreen(context, path);
            },
            child: Container(
              width: 64.0,
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  color: Colors.white70,
                  image: DecorationImage(
                    image: FileImage(io.File(path)),
                    fit: BoxFit.cover
                  )
              ),
            ),

          )).toList(),
        ),
      );
    } else {
      return Container(
        width: double.maxFinite,
        height: 4.0,
        color: Colors.amber,
      );
    }
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

  /// Image overlay for tap picture
  /// ToDo: Close button
  OverlayEntry imageOverlay(FileImage image) {
    final RenderBox renderBox  = context.findRenderObject();
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
        builder: (context) => Positioned(
          left: 0.0,
          top: offset.dy,
          //right: 0.0,
          width: size.width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Container(
                height: size.height - 60,
                width: size.width,
                decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.amber,
                    image: DecorationImage(
                      image: image,
                      fit: BoxFit.contain,
                    )
                ),
//                child: FloatingActionButton(
//
//                  heroTag: "insidecontainer",
//                  child: Icon(Icons.save),
//                  onPressed: () {
//                    _imageOverlay.remove();
//                  },
//                ),
              ),
              FloatingActionButton(
                heroTag: "returnpath",
                child: Icon(Icons.save),
                onPressed: () {
                  _imageOverlay.remove();
                },
              )
            ],

          ),
        )
    );

  }


//  /// Image overlay for tap picture
//  /// ToDo: Close button
//  OverlayEntry imageOverlay(FileImage image) {
//    final RenderBox renderBox  = context.findRenderObject();
//    Size size = renderBox.size;
//    Offset offset = renderBox.localToGlobal(Offset.zero);
//
//    return OverlayEntry(
//      builder: (context) => Positioned(
//        left: 0.0,
//        top: offset.dy,
//        //right: 0.0,
//        width: size.width,
//        child: Container(
//          height: size.height,
//          decoration: BoxDecoration(
//            shape: BoxShape.rectangle,
//            color: Colors.amber,
//            image: DecorationImage(
//              image: image,
//              fit: BoxFit.contain,
//            )
//          ),
//        ),
//      )
//    );
//  }


  @override
  Widget build(BuildContext context) {
    return _getContent();
  }



  takePicture() async {
    await availableCameras().then((cameras) {
      final firstCamera = cameras.first;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TakePicture(camera: firstCamera,)),
      ).then((result) {
        print("Result in modal: $result");
        if (result != "return") {
          imagesPath.add(result);
          addImageFromPath(result);
          setState(() {

          });
        }
      });

    });

  }

  cameraPicker() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);

    String _imagePath = image.path;
    print("imagePath: $_imagePath");
    imagesPath.add(_imagePath);
    setState(() {

    });
  }

  ///
  selectPicture() async {
    await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
      if (image != null) {
        print("_imagePath: ${image.path}");
        setState(() {
          imagesPath.add(image.path);
        });

      }
    });
  }

  startRecordingAudio() async {
    try {
      var permission = await RequestPermissions().requestAudioPermission(PermissionGroup.storage);
      if (permission) {
        io.Directory appDocDirectory  = await getExternalStorageDirectory();
        audioPath = "${appDocDirectory.path}/test01";

        print("Start Recording to $audioPath");
        await AudioRecorder.start(path: audioPath);

        bool isRecording = await AudioRecorder.isRecording;
        setState(() {
          _recording = Recording(duration: Duration(), path: "");
          _isRecording = isRecording;
        });
      }
    } catch (e) {
      print(e);
    }

  }

  stopRecordingAudio() async {
    var recording = await AudioRecorder.stop();
    print("Stop recording: ${recording.path}");
    bool isRecording = await AudioRecorder.isRecording;

    setState(() {
      _recording = recording;
      _isRecording = isRecording;
    });
  }

  addImageFromPath(String path) async {
    AssetImage assetImage = await AssetImage(path);
    images.add(assetImage);
  }


}


/// Images taken with camera using camera button in item modal are saved here:
/// sdcard/Android/data/com.devwolf.record_track/files/items/item.id/
/// Each items get a own directory? Name + item.id?
/// File path for images taken by camere are set by CameraPicker "files/Pictures/" + file name from camera
///
///
/// Audio recordings goes into same directory.
/// Name: item.name + DateTime.now().toIso8601String().
/// AudioFormat: .aac?
///
/// Video recordings goes into same directory.