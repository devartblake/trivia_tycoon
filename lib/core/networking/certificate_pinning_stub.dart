import 'package:dio/dio.dart' show HttpClientAdapter;
import 'package:http/http.dart' as http;

import 'certificate_pinning.dart';

/// Web fallback: the browser owns TLS trust, so pinning is a no-op here. These
/// are only reached when the policy is inactive on web anyway (isActive is
/// false when kIsWeb), so returning defaults is correct.
http.Client createPinnedClient(CertificatePinningPolicy policy) => http.Client();

HttpClientAdapter? createPinnedDioAdapter(CertificatePinningPolicy policy) =>
    null;
