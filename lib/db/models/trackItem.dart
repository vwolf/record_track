/// Name: String
/// Tour: Int (Tour Id)

import 'dart:convert';

TrackItem trackItemFromJson(String str) {
  final jsonData = json.decode(str);
  return TrackItem.fromMap(jsonData);
}

String trackItemToJson(TrackItem data) {
  final dyn = data.toMap();
  return json.encode(dyn);
}

class TrackItem {
  int id;
  String name;
  String info;
  String type;
  DateTime timestamp;
  String latlng;
  List images;
  List recordings;
  List videos;
  String createdAt;
  int markerId;

  TrackItem({
    this.id,
    this.name,
    this.info,
    this.type,
    this.timestamp,
    this.latlng,
    this.images,
    this.recordings,
    this.videos,
    this.createdAt,
    this.markerId,
  });

  factory TrackItem.fromMap(Map<String, dynamic> json) => new TrackItem(
    id: json["id"],
    name: json["name"],
    info: json["info"],
    type: json["type"],
    timestamp: DateTime.parse(json['timestamp']),
    latlng: json['latlng'],
    images: jsonDecode(json['images']),
    recordings: jsonDecode(json['recordings']),
    videos: jsonDecode(json['videos']),
    createdAt: json['createdAt'],
    markerId: json['markerId'],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "name": name,
    "info": info,
    "type": type,
    "timestamp": timestamp.toIso8601String(),
    "latlng": latlng,
    "images": jsonEncode(images),
    "recordings": jsonEncode(recordings),
    "videos": jsonEncode(videos),
    "createdAt": createdAt,
    "markerId" : markerId,
  };

}