import 'package:latlong/latlong.dart';
import 'package:record_track/track/trackService.dart';
import 'package:record_track/db/models/track.dart';

/// Tracking position changes
/// Here we have a normal track but
/// trackpoints created during tracking are here.
/// 
/// - hold list with positions here
///
class TrackingService extends TrackService {
  Track track;

  List<LatLng> trackPoints = [];

  TrackingService(Track track) :super(track);


  addTrackingPoint(LatLng trackPoint) {
    trackPoints.add(trackPoint);
  }

}