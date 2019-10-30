

/// Settings for different parts of programm
/// 
class Settings {
  String defaultTrackDirectory = "Tracks";
  String pathTracksInternal;
  String pathTracksExternal;
  String pathMapTiles;

  String pathToTracks = "/Tracks";
  int distanceToTrackAlert = 100;
  String pathToMapTiles = "OfflineMapTiles";
  String externalSDCard;

  Settings._();
  static final Settings settings = Settings._();

  set(Map readSettings) {
    if (readSettings.containsKey("pathToTracks")) {
      pathToTracks = readSettings["pathToTracks"];
    }

    if (readSettings.containsKey("distanceToTrackAlert")) {
      distanceToTrackAlert = readSettings["distanceToTrackAlert"];
    }
  }

//  get(Map getSettings) {
//    if (getSettings.containsKey("externalSDCard")) {
//      return externalSDCard;
//    }
//  }
}