import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'models/trackCoord.dart';

class TrackCoordTable {
  TrackCoordTable();

  createTrackCoordTable(Database db, String trackName) async {
     String trackCoordTableName = "TourTrack_" + trackName;
    try {
      db.transaction((txn) async {
        await txn.execute("CREATE TABLE " +
            trackCoordTableName +
            " (id INTEGER PRIMARY KEY,"
                "latitude REAL,"
                "longitude REAL,"
                "altitude REAL,"
                "timestamp TEXT,"
                "accuracy REAL,"
                "heading REAL,"
                "speed REAL,"
                "speedAccuracy REAL,"
                "item INTEGER"
                ")");
      });
      return trackCoordTableName;
    } on DatabaseException catch (e) {
      debugPrint("DatabaseException $e");
      return false;
    }
  }

  cloneTrackCoordTable(Database db, String tableToClone, String newTableName) async {
    String tableToCloneName = "Track_" + tableToClone;
    String newTrackCoordTableName = "Track_" + newTableName;
    try {
      db.transaction((txn) async {
        await txn.execute("CREATE TABLE " + newTrackCoordTableName + " AS SELECT * FROM " + tableToCloneName);
      });
      return newTrackCoordTableName;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
      return false;
    }
  }

deleteTrackCoordTable(Database db, String tableName) async {
    String tableToDelete = "TourTrack_" + tableName;
    try {
      var res = db.transaction((txn) async {
        await txn.execute(("DROP TABLE " + tableToDelete));
      }); 
      return res;  
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
      return false;
    }
  }

}