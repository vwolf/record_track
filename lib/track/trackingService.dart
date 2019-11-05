import 'package:latlong/latlong.dart';
import 'package:record_track/track/trackService.dart';
import 'package:record_track/db/models/track.dart';

/// Tracking position changes
/// Here we have a normal track but
/// trackpoints created during tracking are here.
///
/// - hold list with positions here, use to draw track
/// If tracking is temporearly stopped track should not show
/// part which is not tracked.
/// -
class TrackingService extends TrackService {

  List<LatLng> trackPoints = [];

  TrackingService(): super(Track());


  /// Add each new track point.
  /// [super.addPointToTrack] will update track and save point to db.
  ///
  addTrackingPoint(LatLng trackPoint) {
    trackPoints.add(trackPoint);
    super.addPointToTrack(trackPoint, redo: false);
  }

  /// Stop tracking
  stopTracking() {

  }

  /// Start or restart tracking
  ///
  startTracking() {}

}