// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referral_invite_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReferralInviteHiveAdapter extends TypeAdapter<ReferralInviteHive> {
  @override
  final int typeId = 10;

  @override
  ReferralInviteHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReferralInviteHive(
      id: fields[0] as String,
      referrerUserId: fields[1] as String,
      referralCode: fields[2] as String,
      createdAt: fields[3] as DateTime,
      expiresAt: fields[4] as DateTime,
      status: fields[5] as String,
      redeemedBy: fields[6] as String?,
      redeemedAt: fields[7] as DateTime?,
      inviteeName: fields[8] as String?,
      inviteeEmail: fields[9] as String?,
      isSynced: fields[10] as bool,
      serverId: fields[11] as String?,
      metadata: (fields[12] as Map?)?.cast<dynamic, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ReferralInviteHive obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.referrerUserId)
      ..writeByte(2)
      ..write(obj.referralCode)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.expiresAt)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.redeemedBy)
      ..writeByte(7)
      ..write(obj.redeemedAt)
      ..writeByte(8)
      ..write(obj.inviteeName)
      ..writeByte(9)
      ..write(obj.inviteeEmail)
      ..writeByte(10)
      ..write(obj.isSynced)
      ..writeByte(11)
      ..write(obj.serverId)
      ..writeByte(12)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferralInviteHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
