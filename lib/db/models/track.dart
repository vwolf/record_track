import 'dart:convert';

Track trackFromJson(String str) {
  final jsonData = json.decode(str);
  return Track.fromMap(jsonData);
}

String trackToJson(Track data) {
  final jsonString = data.toMap();
  return json.encode(jsonString);
}


class Track {
  int id;
  String name;
  String description;
  DateTime timestamp;
  bool open;
  String location;
  String tourImage;
  String options;
  /// Start coordinates of track as lat/lng
  String coords; // start coords
  /// Table name with track coords
  String track;
  String items;
  String createdAt;
  // not saved to db
  String offlineMapPath;
  String gpxFilePath; // path to *.gpx file

  Track({
    this.id,
    this.name,
    this.description,
    this.timestamp,
    this.open,
    this.location,
    this.tourImage,
    this.options,
    this.coords,
    this.track,
    this.items,
    this.createdAt,
  });

  factory Track.fromMap(Map<String, dynamic> json) => new Track(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    timestamp: DateTime.parse(json['timestamp']),
    location: json["location"],
    tourImage: json["tourImage"],
    open: json["open"] == 1,
    options: json['options'],
    coords: json['coords'],
    track: json['track'],
    items: json['items'],
    createdAt: json['createdAt'],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "description": description,
    "timestamp": timestamp.toIso8601String(),
    "open": open,
    "location": location,
    "tourImage": tourImage,
    "options": options,
    "coords": coords,
    "track": track,
    "items": items,
    "createdAt": createdAt,
  };

  //
  dynamic getOption( String optionsIdentifier ) {
    if (options == null) {
      return null;
    }
    var trackOptions = json.decode(options);

    return (trackOptions[optionsIdentifier]);
  }


  addOption( String optionName, optionValue) {
    
    if (options != null) {
      var currentOptions = jsonDecode(options);
      currentOptions[optionName] =  optionValue;
      options = jsonEncode(currentOptions);
    } else {
      options = jsonEncode({optionName : optionValue});
    }
  }
}