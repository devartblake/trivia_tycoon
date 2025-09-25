class WsEnvelope {
  final String op;     // "hello", "presence", "room.join", "match.turn", "ack", ...
  final int? seq;      // server sequence number
  final int ts;        // server/client timestamp (ms)
  final Map<String, dynamic>? data;

  WsEnvelope({required this.op, this.seq, required this.ts, this.data});

  Map<String, dynamic> toJson() => {
    'op': op,
    if (seq != null) 'seq': seq,
    'ts': ts,
    if (data != null) 'data': data,
  };

  static WsEnvelope fromJson(Map<String, dynamic> j) => WsEnvelope(
    op: j['op'],
    seq: j['seq'],
    ts: j['ts'],
    data: (j['data'] as Map?)?.cast<String, dynamic>(),
  );
}