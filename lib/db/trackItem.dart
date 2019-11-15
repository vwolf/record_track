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
                "type TEXT,"
                "latlng TEXT,"
                "images TEXT,"
                "recordings TEXT,"
                "videos TEXT,"
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
    String tableToCloneName = tableToClone;
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
    String tableToDelete = tableName;
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

  Future<int> addTrackItem(Database db, TrackItem trackItem, String trackItemTable)  async {
    var table = await db.rawQuery("SELECT MAX(id)+1 as id FROM " + trackItemTable);
    trackItem.id = table.first["id"];
    trackItem.timestamp = DateTime.now();
    trackItem.createdAt = DateTime.now().toIso8601String();

    var result = await db.insert(trackItemTable, trackItem.toMap());
    return result;
  }

  /// Delete [TrackItem] with index trackItem.id.
  /// Update id of remaining [TrackItem]'s in table [trackItemTable].
  Future<int> deleteTrackItem(Database db, TrackItem trackItem, String trackItemTable) async {
    try {
      var result = await db.delete(trackItemTable, where: "id = ?", whereArgs: [trackItem.id]);
      String query = "UPDATE $trackItemTable SET id = id - 1 where id > ${trackItem.id}";
      await db.rawUpdate(query);
      return result;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
    }
    return 0;
  }

  /// Replace [TrackItem]
  Future<int> replaceTrackItem(Database db, TrackItem trackItem, String trackItemTable) async {

    try {
      await db.update("$trackItemTable", trackItem.toMap(), where: "id = ?", whereArgs: [trackItem.id]);
      return 1;
    } on DatabaseException catch (e) {
      print ("DatabaseException $e");
    }

    return 0;
  }


  Future<List<TrackItem>> getTrackItems( Database db, String trackItemTable) async {
    print("getTrackItems");
    try {
      var res = await db.query(trackItemTable);
      List<TrackItem> list = res.isNotEmpty ? res.map((c) => TrackItem.fromMap(c)).toList() : [];
      print(list);
      return list;
    } on DatabaseException catch (e) {
      print("sqlite error: $e");
    }

    return [];
  }

}