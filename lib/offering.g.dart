// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offering.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfferingAdapter extends TypeAdapter<Offering> {
  @override
  final int typeId = 0;

  @override
  Offering read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Offering(
      name: fields[0] as String,
      readableName: fields[1] as String,
      priceCents: fields[2] as int,
      imageUrl: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Offering obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.readableName)
      ..writeByte(2)
      ..write(obj.priceCents)
      ..writeByte(3)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
