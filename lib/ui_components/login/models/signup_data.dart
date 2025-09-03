import 'package:quiver/core.dart';
import 'package:trivia_tycoon/ui_components/login/models/term_of_service.dart';

class SignupData {
  final String? name;
  final String? password;
  final List<TermOfServiceResult> termsOfService;
  final Map<String, String>? additionalSignupData;

  SignupData.fromSignupForm({
    required this.name,
    required this.password,
    this.additionalSignupData,
    this.termsOfService = const [],
  });

  SignupData.fromProvider({
    required this.additionalSignupData,
    this.termsOfService = const [],
  })  : name = null,
        password = null;

  @override
  bool operator ==(Object other) {
    if (other is SignupData) {
      return name == other.name &&
          password == other.password &&
          additionalSignupData == other.additionalSignupData;
    }
    return false;
  }

  @override
  int get hashCode => hash3(name, password, additionalSignupData);
}