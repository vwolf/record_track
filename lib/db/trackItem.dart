import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'models/trackItem.dart';

class TrackItemTable {
  TrackItemTable();

  createTrackItemTable(Database db, String trackName) {
    debugPrint("createTrackItemTable $trackName");

    String trackItemTableName = "TrackItem_" + trackName;
    try {
      db.transaction((txn) async {
        await txn.execute("CREATE TABLE " +
            trackItemTableName +
            "(id INTEGER PRIMARY KEY,"
                "name TEXT,"
                "info TEXT,"
                "timestamp TEXT,"
                "latlng TEXT,"
                "images TEXT,"
                "createdAt TEXT,"
                "markerId INTEGER"
                ")"
        );
      });
      return trackItemTableName;
    } on DatabaseException catch (e) {
      print("DatabaseException: $e");
      return false;
    }
  }

  cloneTrackItemTable(Database db, String tableToClone, String tableName) async {
    String tableToCloneName = "TrackItem_" + tableToClone;
    String newTableName = "TrackItem_" + tableName;
    try {
      db.transaction((txn) async {
        await txn.execute("CREATE TABLE " + newTableName + " AS SELECT * FROM " + tableToCloneName);
      });
      return newTableName;
    } on DatabaseException catch (e) {
      print("DatabaseException: $e");
      return false;
    }
  }


  deleteTrackItemTable(Database db, String tableName) async {
    String tableToDelete = "TrackItem_" + tableName;
    try {
      var res = db.transaction((txn) async {
        await txn.execute(("DROP TABLE " + tableToDelete));
      });
      return res;
    } on DatabaseException catch (e) {
      print("DatabaseException: $e");
      return false;
    }
  }

}