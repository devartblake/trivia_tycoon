class QuestionCollectionEnvelope<T> {
  const QuestionCollectionEnvelope({
    required this.items,
    required this.meta,
  });

  final List<T> items;
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
      throw FormatException(
        'Invalid response from $endpoint: missing collection keys ${itemKeys.join(', ')}',
      );
    }

    final rawMeta = response['meta'];
    if (rawMeta == null) {
      if (requireMeta) {
        throw FormatException('Invalid response from $endpoint: missing meta');
      }
      return QuestionCollectionEnvelope<dynamic>(
        items: items,
        meta: const <String, dynamic>{},
      );
    }

    if (rawMeta is! Map) {
      throw FormatException('Invalid response from $endpoint: meta must be an object');
    }

    return QuestionCollectionEnvelope<dynamic>(
      items: items,
      meta: Map<String, dynamic>.from(rawMeta),
    );
  }
}
