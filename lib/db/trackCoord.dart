import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'models/trackCoord.dart';

//
class TrackCoordTable {
  TrackCoordTable();

  /// First get
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

//  createTrackCoordTable(Database db, String trackName) async {
//    String trackCoordTableName = "TourTrack_" + trackName;
//    try {
//      db.transaction((txn) async {
//        await txn.execute("CREATE TABLE " +
//            trackCoordTableName +
//            " (id INTEGER PRIMARY KEY,"
//                "latitude REAL,"
//                "longitude REAL,"
//                "altitude REAL,"
//                "timestamp TEXT,"
//                "accuracy REAL,"
//                "heading REAL,"
//                "speed REAL,"
//                "speedAccuracy REAL,"
//                "item INTEGER"
//                ")");
//      });
//      return trackCoordTableName;
//    } on DatabaseException catch (e) {
//      debugPrint("DatabaseException $e");
//      return false;
//    }
//  }


  /// Use id to identify table to clone
  cloneTrackCoordTable(Database db, String tableToClone, String newTableName) async {
    String tableToCloneName = tableToClone;
    String newTrackCoordTableName = "TourTrack_" + newTableName;
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
    String tableToDelete = tableName;
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

  /// TourCoords functions
  ///

  Future<int> addTrackCoord(Database db, TrackCoord trackCoord, String trackCoordTable) async {
    print("db addTrackCoords");
    String query = "SELECT MAX(id)+1 as id FROM " + trackCoordTable;
    var table = await db.rawQuery(query);
    int id = table.first["id"];

    // insert
    trackCoord.id = id;
    trackCoord.timestamp = DateTime.now();
    var res = await db.insert(trackCoordTable, trackCoord.toMap());
    return res;
  }

  /// Insert new TrackCoord at index index
  /// First increase id all TrackCoords with higher index
  /// Now insert TrackCoord mit id = index + 1
  insertTrackCoord(Database db, TrackCoord trackCoord, String trackCoordTable, int index) async {
    print(" insertTrackCoords");

    /// get highest id
    String query = "SELECT MAX(id) as id FROM " + trackCoordTable;

    var table = await db.rawQuery(query);
    int maxId = table.first["id"];

    for (int id = maxId; id >= index; id--) {
      await db
          .rawUpdate("UPDATE $trackCoordTable SET id = $id + 1 WHERE id = $id");
    }

    /// now insert new tourCoord
    try {
      trackCoord.id = index;
      trackCoord.timestamp = DateTime.now();
      var res = await db.insert(trackCoordTable, trackCoord.toMap());
      print("insertTrackCoord insert result: $res");
    } on DatabaseException catch (e) {
      print("sqlite error $e");
    }
  }

  Future<List<TrackCoord>> getTrackCoords(Database db, String trackCoordTable) async {
    print("getTrackCoords");
    try {
      var res = await db.query(trackCoordTable);
      List<TrackCoord> list = res.isNotEmpty ? res.map((c) => TrackCoord.fromMap(c)).toList() : [];
      //print(list);
      return list;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
    }

    return [];
  }

  /// Delete trackCoord at index id.
  /// Update following id's of following trackCoord's (decrease by 1)
  /// TrackCoord has item then update item with coords
  deleteTrackCoord(Database db, String trackCoordTable, int id) async {
    try {
      var res =
      await db.delete(trackCoordTable, where: "id = ?", whereArgs: [id]);
      print("deleteTrackCoord res: $res");
      String query = "UPDATE $trackCoordTable SET id = id - 1 WHERE id > $id";
      await db.rawUpdate(query);
      return res;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
    }
  }

  /// Update one value in trackCoords table
  /// #Set or remove id of item
  Future<int> updateTrackCoord(Database db, String tableName, int id, String prop, dynamic val) async {
    String query = "UPDATE $tableName SET $prop = $val WHERE id = $id";
    try {
      var res = await db.rawUpdate(query);
      print ("updateTrackCoord $res");
      return res;
    } on DatabaseException catch (e) {
      print ("DatabaseException $e");
    }
    return 0;
  }

  /// Replace [TrackCoord] with id in db
  /// Get table with tableId
  Future<int> replaceTrackCoord(Database db, String tableName, TrackCoord trackCoord) async {

    try {
      await db.update("$tableName", trackCoord.toMap(), where: "id = ?", whereArgs: [trackCoord.id]);
      return 1;
    } on DatabaseException catch (e) {
      print ("DatabaseException $e");
    }
    return 0;
  }
}