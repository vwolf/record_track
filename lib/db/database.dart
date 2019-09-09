import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'models/track.dart';
import 'trackTable.dart';

/// Database sqlite
/// 
class DBProvider {
  final databaseName = "TracksDB.db";

  TrackTable _trackTable;

  DBProvider._();
  static final DBProvider db = DBProvider._();
  static Database _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database;
    }

    _trackTable = TrackTable();
    
    _database = await _initDB(databaseName);
    return _database;
  }

  /// Create new database with name [dbName].
  /// 
  _initDB(dbName) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, dbName);
    return await openDatabase(path, version: 1, onOpen: (db) {},
      onCreate: (Database db, int version) async {
        var tourTableState = _trackTable.createTrackTable(db);
        debugPrint("_initDB.createTrackTable: $tourTableState");
      }
    );
  }

  /// Delete a database table with name [tableName].
  /// 
  deleteTable(String tableName) async {
    final db = await database;
    var result = await db.rawQuery("DROP TABLE IF EXISTS " + tableName);
    debugPrint("deleteTable $tableName with result: $result");
  }

  /// TrackTable queries
  /// 
  newTrack(Track newTrack) async {
    final db = await database;
    return _trackTable.newTrack(db, newTrack);
  }

  updateTrack(Track tour) async {
    final db = await database;
    return _trackTable.updateTrack(db, tour);
  }

  deleteTrack(int id) async {
    final db = await database;
    return _trackTable.deleteTrack(db, id);
  }

 Future<List<Track>> getAllTracks() async {
    final db = await database;
    return _trackTable.getAllTracks(db);
  }

  Future<int> tableExists(String tableName) async {
    final db = await database;
    return _trackTable.tableExists(db, tableName);
  }

  Future<int> tourExists(String tourname) async {
    final db = await database;
    return _trackTable.trackExists(db, tourname);
  }

  cloneTrack(Track newTrack, String oldTrackName) async {
    final db = await database;
    return _trackTable.cloneTrack(db, newTrack, oldTrackName);
  }

 
}