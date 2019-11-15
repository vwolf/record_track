import 'package:flutter/material.dart';
import 'package:record_track/db/models/trackItem.dart';
import 'waypointModal.dart';

/// [WayPoint] is a [TrackItem] in db
/// WayPoints can belong to
/// - track (position on track)
/// - track point (track segments start and end point)
/// - an any point of map.
///
/// Waypoint on track segment are independent from track
class WayPoint {

  TrackItem item = TrackItem();

  WayPoint();

  WayPoint.withItem( TrackItem item) {
    this.item = item;
  }

  /// Show [WaypointModal] dialog to create or edit an [TrackItem].
  ///
  /// - @param itemType: trackItem. markerItem or mapItem
  triggerDialog(context, String itemType) async {

    if (itemType == "show") {
      showDialog(context: context, builder: (BuildContext context) => WayPointModal(itemType, this));
    } else {
      switch (
      await showDialog(
          context: context,
          builder: (BuildContext context) => WayPointModal(itemType, this))
      ) {
        case "ADD" :
          print("Waypoint ADD: ${item.name}");
          item.timestamp = DateTime.now();
          return item;
          break;

        case "DELETE" :
          print("Waypoint DELETE: ${item.name}");
          return "DELETE";
          break;
      }
    }
  }
}