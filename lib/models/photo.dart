import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Photo {
  @HiveField(0)
  String imagePath;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  int albumId;

  Photo({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.albumId,
  });
}

class PhotoAdapter extends TypeAdapter<Photo> {
  @override
  final int typeId = 0;

  @override
  Photo read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    final int albumId =
    (fields.containsKey(4) && fields[4] != null) ? fields[4] as int : 0;

    return Photo(
      imagePath: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      createdAt: fields[3] as DateTime,
      albumId: albumId,
    );
  }

  @override
  void write(BinaryWriter writer, Photo obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.albumId);
  }
}
