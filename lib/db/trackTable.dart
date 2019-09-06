import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import 'models/track.dart';

class TrackTable {
  TrackTable();

  createTrackTable(Database db) async {
    debugPrint("CreateTourTable()");

    try {
      var result = db.transaction((txn) async {
        await txn.execute("CREATE TABLE TRACK ("
          "id INTEGER PRIMARY KEY,"
          "name TEXT,"
            "description TEXT,"
            "timestamp TEXT,"
            "open BIT,"
            "location TEXT,"
            "tourImage TEXT,"
            "options TEXT,"
            "coords TEXT,"
            "track TEXT,"
            "items TEXT,"
            "createdAt TEXT )");
      });
      debugPrint("Collection Track create ok: $result");
      return result;
    } on DatabaseException catch (e) {
      debugPrint("DatabaseException $e");
      return false;
    }
  }

  Future newTrack(Database db, Track newTrack) async {

  }

  Future<List<Track>> getAllTracks(Database db) async {
    debugPrint("getAllTracks()");
    try {
      var result = await db.query("TRACK");
      List<Track> list = result.isNotEmpty ? result.map((c) => Track.fromMap(c)).toList() : [];

      return list;
    } on DatabaseException catch (e) {
      debugPrint("DatabaseExecption in getAllTracks: $e");
    }

    return [];
  }
}