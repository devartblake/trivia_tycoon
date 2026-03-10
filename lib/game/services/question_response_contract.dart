class QuestionContractException implements Exception {
  const QuestionContractException({
    required this.endpoint,
    required this.reason,
  });

  final String endpoint;
  final String reason;

  @override
  String toString() => 'QuestionContractException[$endpoint]: $reason';
}

class QuestionCollectionEnvelope<T> {
  const QuestionCollectionEnvelope({
    required this.items,
    required this.meta,
  });

  final List<T> items;
  final Map<String, dynamic> meta;
}

class QuestionObjectEnvelope {
  const QuestionObjectEnvelope({
    required this.data,
    required this.meta,
  });

  final Map<String, dynamic> data;
  final Map<String, dynamic> meta;
}

class QuestionResponseContract {
  static QuestionCollectionEnvelope<dynamic> parseCollection(
    Map<String, dynamic> response, {
    required String endpoint,
    required List<String> itemKeys,
    bool requireMeta = false,
  }) {
    List<dynamic>? items;
    for (final key in itemKeys) {
      final candidate = response[key];
      if (candidate is List) {
        items = candidate;
        break;
      }
    }

    if (items == null) {
      throw QuestionContractException(
        endpoint: endpoint,
        reason: 'missing collection keys: ${itemKeys.join(', ')}',
      );
    }

    final meta = _parseMeta(response, endpoint: endpoint, requireMeta: requireMeta);
    return QuestionCollectionEnvelope<dynamic>(items: items, meta: meta);
  }

  static QuestionObjectEnvelope parseObject(
    Map<String, dynamic> response, {
    required String endpoint,
    List<String> requiredKeys = const [],
    List<String> anyOfKeys = const [],
    bool requireMeta = false,
  }) {
    if (response.isEmpty) {
      throw QuestionContractException(endpoint: endpoint, reason: 'empty object payload');
    }

    for (final key in requiredKeys) {
      if (!response.containsKey(key)) {
        throw QuestionContractException(endpoint: endpoint, reason: 'missing required key: $key');
      }
    }

    if (anyOfKeys.isNotEmpty && !anyOfKeys.any(response.containsKey)) {
      throw QuestionContractException(
        endpoint: endpoint,
        reason: 'missing one-of keys: ${anyOfKeys.join(', ')}',
      );
    }

    final meta = _parseMeta(response, endpoint: endpoint, requireMeta: requireMeta);
    return QuestionObjectEnvelope(data: response, meta: meta);
  }

  static Map<String, dynamic> _parseMeta(
    Map<String, dynamic> response, {
    required String endpoint,
    required bool requireMeta,
  }) {
    final rawMeta = response['meta'];
    if (rawMeta == null) {
      if (requireMeta) {
        throw QuestionContractException(endpoint: endpoint, reason: 'missing meta');
      }
      return const <String, dynamic>{};
    }

    if (rawMeta is! Map) {
      throw QuestionContractException(endpoint: endpoint, reason: 'meta must be an object');
    }

    return Map<String, dynamic>.from(rawMeta);
  }
}
