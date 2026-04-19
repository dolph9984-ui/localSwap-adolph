import 'package:hive_flutter/hive_flutter.dart';

//modele pour stocker un brouillon sur le telephone
class DraftModel extends HiveObject {
  final String uid;
  final int draftNumber;
  final String title;
  final String description;
  final double? price;
  final String? category;
  final String? condition;
  final String? city;
  final String? brand;
  final String? modelName;
  final String? size;
  final String? color;
  final List<String> imagePaths;
  final double? latitude;
  final double? longitude;
  final DateTime savedAt;

  DraftModel({
    required this.uid,
    required this.draftNumber,
    required this.title,
    required this.description,
    this.price,
    this.category,
    this.condition,
    this.city,
    this.brand,
    this.modelName,
    this.size,
    this.color,
    this.imagePaths = const [],
    this.latitude,
    this.longitude,
    required this.savedAt,
  });

  //affiche le titre ou le numero du brouillon par defaut
  String get displayTitle =>
      title.trim().isNotEmpty ? title.trim() : 'Brouillon #$draftNumber';
}

//convertit l'objet pour la base de données locale hive
class DraftModelAdapter extends TypeAdapter<DraftModel> {
  @override
  final int typeId = 0;

  @override
  //reconstruit l'objet depuis le stockage binaire
  DraftModel read(BinaryReader reader) {
    return DraftModel(
      uid: reader.readString(),
      draftNumber: reader.readInt(),
      title: reader.readString(),
      description: reader.readString(),
      price: reader.readBool() ? reader.readDouble() : null,
      category: reader.readBool() ? reader.readString() : null,
      condition: reader.readBool() ? reader.readString() : null,
      city: reader.readBool() ? reader.readString() : null,
      brand: reader.readBool() ? reader.readString() : null,
      modelName: reader.readBool() ? reader.readString() : null,
      size: reader.readBool() ? reader.readString() : null,
      color: reader.readBool() ? reader.readString() : null,
      imagePaths: List<String>.generate(
          reader.readInt(), (_) => reader.readString()),
      latitude: reader.readBool() ? reader.readDouble() : null,
      longitude: reader.readBool() ? reader.readDouble() : null,
      savedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  //enregistre les donnees sur le disque
  void write(BinaryWriter writer, DraftModel obj) {
    writer.writeString(obj.uid);
    writer.writeInt(obj.draftNumber);
    writer.writeString(obj.title);
    writer.writeString(obj.description);

    writer.writeBool(obj.price != null);
    if (obj.price != null) writer.writeDouble(obj.price!);

    writer.writeBool(obj.category != null);
    if (obj.category != null) writer.writeString(obj.category!);

    writer.writeBool(obj.condition != null);
    if (obj.condition != null) writer.writeString(obj.condition!);

    writer.writeBool(obj.city != null);
    if (obj.city != null) writer.writeString(obj.city!);

    writer.writeBool(obj.brand != null);
    if (obj.brand != null) writer.writeString(obj.brand!);

    writer.writeBool(obj.modelName != null);
    if (obj.modelName != null) writer.writeString(obj.modelName!);

    writer.writeBool(obj.size != null);
    if (obj.size != null) writer.writeString(obj.size!);

    writer.writeBool(obj.color != null);
    if (obj.color != null) writer.writeString(obj.color!);

    writer.writeInt(obj.imagePaths.length);
    for (final p in obj.imagePaths) writer.writeString(p);

    writer.writeBool(obj.latitude != null);
    if (obj.latitude != null) writer.writeDouble(obj.latitude!);

    writer.writeBool(obj.longitude != null);
    if (obj.longitude != null) writer.writeDouble(obj.longitude!);

    writer.writeInt(obj.savedAt.millisecondsSinceEpoch);
  }
}