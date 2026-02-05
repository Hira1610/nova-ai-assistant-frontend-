// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalTaskAdapter extends TypeAdapter<LocalTask> {
  @override
  final int typeId = 0;

  @override
  LocalTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalTask(
      id: fields[0] as String,
      userId: fields[8] as String,
      title: fields[1] as String,
      type: fields[2] as String,
      createdAt: fields[3] as DateTime,
      notificationId: fields[9] as int,
      status: fields[7] as String,
      isSynced: fields[4] as bool,
      isCompleted: fields[5] as bool,
      remindAt: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LocalTask obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.isSynced)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.remindAt)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.userId)
      ..writeByte(9)
      ..write(obj.notificationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
