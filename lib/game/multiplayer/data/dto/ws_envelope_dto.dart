/// Transport-layer envelope for all WebSocket frames.
///
/// Expected shape:
/// { "op": "match.turn_started", "ts": 1732200123456, "data": {...}, "seq": 42, "reqId": "abc123" }
class WsEnvelopeDto {
  final String op;
  final int ts;
  final Map<String, dynamic>? data;
  final int? seq;
  final String? reqId;

  const WsEnvelopeDto({
    required this.op,
    required this.ts,
    this.data,
    this.seq,
    this.reqId,
  });

  /// Safe JSON parse: tolerates missing fields and non-Map `data`.
  factory WsEnvelopeDto.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    Map<String, dynamic>? casted;
    if (rawData is Map) {
      casted = rawData.map((k, v) => MapEntry(k.toString(), v));
    } else {
      casted = null;
    }

    final op = (json['op'] ?? '').toString();
    final ts = _asInt(json['ts']) ?? DateTime.now().millisecondsSinceEpoch;
    final seq = _asInt(json['seq']);
    final reqId = json['reqId']?.toString();

    return WsEnvelopeDto(op: op, ts: ts, data: casted, seq: seq, reqId: reqId);
  }

  Map<String, dynamic> toJson() => {
    'op': op,
    'ts': ts,
    if (data != null) 'data': data,
    if (seq != null) 'seq': seq,
    if (reqId != null) 'reqId': reqId,
  };

  WsEnvelopeDto copyWith({
    String? op,
    int? ts,
    Map<String, dynamic>? data,
    bool clearData = false,
    int? seq,
    bool clearSeq = false,
    String? reqId,
    bool clearReqId = false,
  }) {
    return WsEnvelopeDto(
      op: op ?? this.op,
      ts: ts ?? this.ts,
      data: clearData ? null : (data ?? this.data),
      seq: clearSeq ? null : (seq ?? this.seq),
      reqId: clearReqId ? null : (reqId ?? this.reqId),
    );
  }

  @override
  String toString() =>
      'WsEnvelopeDto(op: $op, ts: $ts, seq: $seq, reqId: $reqId, hasData: ${data != null})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is WsEnvelopeDto &&
              runtimeType == other.runtimeType &&
              op == other.op &&
              ts == other.ts &&
              _mapEq(data, other.data) &&
              seq == other.seq &&
              reqId == other.reqId;

  @override
  int get hashCode => Object.hash(op, ts, _mapHash(data), seq, reqId);
}

// --------- helpers ---------

int? _asInt(Object? v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

bool _mapEq(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  if (a.length != b.length) return false;
  for (final k in a.keys) {
    if (!b.containsKey(k)) return false;
    final av = a[k], bv = b[k];
    if (av is Map && bv is Map) {
      if (!_mapEq(av.cast<String, dynamic>(), bv.cast<String, dynamic>())) return false;
    } else if (av != bv) {
      return false;
    }
  }
  return true;
}

int _mapHash(Map<String, dynamic>? m) {
  if (m == null) return 0;
  var h = 0;
  m.forEach((k, v) {
    h = h ^ Object.hash(k, v is Map ? _mapHash(v.cast<String, dynamic>()) : v);
  });
  return h;
}
