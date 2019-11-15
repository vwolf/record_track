import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'models/track.dart';
import 'models/trackCoord.dart';
import 'models/trackItem.dart';

import 'trackTable.dart';
import 'trackCoord.dart';
import 'trackItem.dart';

/// Database sqlite
/// 
class DBProvider {
  final databaseName = "TracksDB.db";

  TrackTable _trackTable;
  TrackCoordTable _trackCoordTable;
  TrackItemTable _trackItemTable;

  DBProvider._();
  static final DBProvider db = DBProvider._();
  static Database _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database;
    }

    _trackTable = TrackTable();
    _trackCoordTable = TrackCoordTable();
    _trackItemTable = TrackItemTable();

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

  updateTrack(Track track) async {
    final db = await database;
    return _trackTable.updateTrack(db, track);
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

  cloneTrack(Track track) async {
    final db = await database;
    return _trackTable.cloneTrack(db, track);
  }

  /// TrackCoord Table queries
  Future<int> addTrackCoord(TrackCoord trackCoord, String trackCoordTable) async {
    final db = await database;
    return _trackCoordTable.addTrackCoord(db, trackCoord, trackCoordTable);
  }

  /// Return list with [TrackCoord]
  Future<List<TrackCoord>> getTrackCoords(String trackCoordTable) async {
    final db = await database;
    return _trackCoordTable.getTrackCoords(db, trackCoordTable);
  }

  Future<int> updateTrackCoord(int id, String trackCoordTable, String prop, dynamic val) async {
    final db = await database;
    return _trackCoordTable.updateTrackCoord(db, trackCoordTable, id, prop, val);
  }

  Future<int> replaceTrackCoord(String tableName, TrackCoord trackCoord) async {
    final db = await database;
    return _trackCoordTable.replaceTrackCoord(db, tableName, trackCoord);
  }

  insertTrackCoord(TrackCoord trackCoord, String trackCoordTable, int index) async {
    final db = await database;
    return _trackCoordTable.insertTrackCoord(db, trackCoord, trackCoordTable, index);
  }

  deleteTrackCoord(int id, String trackCoordTable) async {
    final db = await database;
    return _trackCoordTable.deleteTrackCoord(db, trackCoordTable, id);
  }

  /// TrackItem table queries
  Future<int> addTrackItem(TrackItem trackItem, String trackItemTable) async {
    final db = await database;
    return _trackItemTable.addTrackItem(db, trackItem, trackItemTable);
  }

  deleteTrackItem(TrackItem trackItem,  String trackItemTable) async {
    final db = await database;
    return _trackItemTable.deleteTrackItem(db, trackItem, trackItemTable);
  }

  Future<int> updateTrackItem(int id, String trackItemTable, String prop, dynamic val) async {
    final db = await database;
    return 0;
  }

  Future<int> replaceTrackItem(String trackItemTable, TrackItem trackItem) async {
    final db = await database;
    return _trackItemTable.replaceTrackItem(db, trackItem, trackItemTable);
  }


  Future<List<TrackItem>> getTrackItems(String trackItemTable) async {
    final db = await database;
    return _trackItemTable.getTrackItems(db, trackItemTable);
  }

  Future<TrackItem> getTrackItem(String trackItemTable, String prop, dynamic value) async  {
    final db = await database;
  }
}