// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanAdapter extends TypeAdapter<Scan> {
  @override
  final int typeId = 3;

  @override
  Scan read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Scan()
      ..id = fields[0] as String
      ..barcode = fields[1] as String
      ..format = fields[2] as String
      ..action = fields[3] as String?
      ..notes = fields[4] as String?
      ..userId = fields[5] as String?
      ..scannedAt = fields[6] as DateTime
      ..createdAt = fields[7] as DateTime
      ..lastSyncAttempt = fields[8] as DateTime?
      ..syncStatus = fields[9] as int
      ..retryCount = fields[10] as int
      ..nextRetryAt = fields[11] as DateTime?
      ..lastError = fields[12] as String?
      ..serverId = fields[13] as String?;
  }

  @override
  void write(BinaryWriter writer, Scan obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.barcode)
      ..writeByte(2)
      ..write(obj.format)
      ..writeByte(3)
      ..write(obj.action)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.userId)
      ..writeByte(6)
      ..write(obj.scannedAt)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.lastSyncAttempt)
      ..writeByte(9)
      ..write(obj.syncStatus)
      ..writeByte(10)
      ..write(obj.retryCount)
      ..writeByte(11)
      ..write(obj.nextRetryAt)
      ..writeByte(12)
      ..write(obj.lastError)
      ..writeByte(13)
      ..write(obj.serverId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusHiveAdapter extends TypeAdapter<SyncStatusHive> {
  @override
  final int typeId = 4;

  @override
  SyncStatusHive read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatusHive.pending;
      case 1:
        return SyncStatusHive.syncing;
      case 2:
        return SyncStatusHive.synced;
      case 3:
        return SyncStatusHive.failed;
      default:
        return SyncStatusHive.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatusHive obj) {
    switch (obj) {
      case SyncStatusHive.pending:
        writer.writeByte(0);
        break;
      case SyncStatusHive.syncing:
        writer.writeByte(1);
        break;
      case SyncStatusHive.synced:
        writer.writeByte(2);
        break;
      case SyncStatusHive.failed:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
