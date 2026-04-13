class TermOfService {
  String id;
  bool mandatory;
  String text;
  String? linkUrl;
  String validationErrorMessage;
  bool initialValue;
  bool checked = false;
  TermOfService({
    required this.id,
    required this.mandatory,
    required this.text,
    this.linkUrl,
    this.initialValue = false,
    this.validationErrorMessage = 'Required',
  }) {
    checked = initialValue;
  }

}

class TermOfServiceResult {
  TermOfService term;
  bool accepted;
  TermOfServiceResult({required this.term, required this.accepted});
}