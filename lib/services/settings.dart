

/// Settings for different parts of programm
/// 
class Settings {
  /// Default directory name for user files (tracks, ...)
  String defaultTrackDirectory = "Tracks";
  String pathTracksInternal;
  String pathTracksExternal;
  String pathMapTiles;

  String pathToTracks = "/Tracks";
  int distanceToTrackAlert = 100;
  String pathToMapTiles = "OfflineMapTiles";
  String externalSDCard;

  /// List of path to external storage (default)
  List<String> externalPaths = [];
  
  Settings._();
  static final Settings settings = Settings._();

  /// Set variable values, use to initialize with saved values
  set(Map readSettings) {
    if (readSettings.containsKey("pathToTracks")) {
      pathToTracks = readSettings["pathToTracks"];
    }

    if (readSettings.containsKey("distanceToTrackAlert")) {
      distanceToTrackAlert = readSettings["distanceToTrackAlert"];
    }

  }

  addExternalPath(String path) {
    if (!externalPaths.contains(path)) {
      externalPaths.add(path);
    }
  }
  
//  get(Map getSettings) {
//    if (getSettings.containsKey("externalSDCard")) {
//      return externalSDCard;
//    }
//  }
}