import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/compliance/compliance_consent_api_client.dart';
import '../../core/services/compliance/compliance_consent_providers.dart';

/// Age verification + consent capture (COPPA/GDPR). Submits the player's
/// declared age, captures Terms/Privacy/Marketing consent, and — for minors —
/// initiates the parental-consent email flow. Backed by Synaptix.Compliance.Api.
class AgeGateScreen extends ConsumerStatefulWidget {
  const AgeGateScreen({super.key});

  /// Policy version recorded with each consent decision.
  static const policyVersion = '2026-01';

  @override
  ConsumerState<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends ConsumerState<AgeGateScreen> {
  final _ageCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();

  bool? _isMinor;
  bool _submittingAge = false;
  bool _sendingParent = false;
  bool _parentRequested = false;

  bool _terms = false;
  bool _privacy = false;
  bool _marketing = false;
  bool _savingConsent = false;

  ComplianceConsentApiClient get _client =>
      ref.read(complianceConsentApiClientProvider);

  @override
  void dispose() {
    _ageCtrl.dispose();
    _parentEmailCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _submitAge() async {
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age == null || age < 1 || age > 120) {
      _snack('Enter a valid age (1–120).');
      return;
    }
    setState(() => _submittingAge = true);
    try {
      final isMinor = await _client.submitAge(age);
      setState(() => _isMinor = isMinor);
    } on ComplianceConsentApiException catch (e) {
      _snack('Age verification failed: ${e.message}');
    } finally {
      if (mounted) setState(() => _submittingAge = false);
    }
  }

  Future<void> _requestParentConsent() async {
    final email = _parentEmailCtrl.text.trim();
    if (!email.contains('@')) {
      _snack('Enter a valid parent/guardian email.');
      return;
    }
    setState(() => _sendingParent = true);
    try {
      await _client.initiateParentalConsent(email);
      setState(() => _parentRequested = true);
      _snack('Parental consent request sent to $email.');
    } on ComplianceConsentApiException catch (e) {
      _snack('Could not send request: ${e.message}');
    } finally {
      if (mounted) setState(() => _sendingParent = false);
    }
  }

  Future<void> _saveConsent() async {
    if (!_terms || !_privacy) {
      _snack('Terms and Privacy consent are required to continue.');
      return;
    }
    setState(() => _savingConsent = true);
    try {
      await _client.recordConsent(
        consentType: 'TermsOfService',
        consentGiven: true,
        policyVersion: AgeGateScreen.policyVersion,
      );
      await _client.recordConsent(
        consentType: 'PrivacyPolicy',
        consentGiven: true,
        policyVersion: AgeGateScreen.policyVersion,
      );
      await _client.recordConsent(
        consentType: 'Marketing',
        consentGiven: _marketing,
        policyVersion: AgeGateScreen.policyVersion,
      );
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go('/home');
      }
    } on ComplianceConsentApiException catch (e) {
      _snack('Could not save consent: ${e.message}');
    } finally {
      if (mounted) setState(() => _savingConsent = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ageVerified = _isMinor != null;
    final minorBlocked = _isMinor == true && !_parentRequested;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify your age')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('How old are you?',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('We use this to keep the experience appropriate and '
              'compliant. Minors need a parent or guardian\'s consent.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageCtrl,
                  enabled: !ageVerified,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed:
                    (_submittingAge || ageVerified) ? null : _submitAge,
                child: _submittingAge
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Verify'),
              ),
            ],
          ),
          if (_isMinor == true) ...[
            const SizedBox(height: 24),
            _ParentalConsentCard(
              controller: _parentEmailCtrl,
              sending: _sendingParent,
              requested: _parentRequested,
              onSend: _requestParentConsent,
            ),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text('Consent', style: Theme.of(context).textTheme.titleMedium),
          CheckboxListTile(
            value: _terms,
            onChanged: (v) => setState(() => _terms = v ?? false),
            title: const Text('I agree to the Terms of Service'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            value: _privacy,
            onChanged: (v) => setState(() => _privacy = v ?? false),
            title: const Text('I agree to the Privacy Policy'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            value: _marketing,
            onChanged: (v) => setState(() => _marketing = v ?? false),
            title: const Text('Send me product updates (optional)'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (!ageVerified || minorBlocked || _savingConsent)
                  ? null
                  : _saveConsent,
              child: _savingConsent
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(minorBlocked
                      ? 'Awaiting parental consent'
                      : 'Save & Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentalConsentCard extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final bool requested;
  final VoidCallback onSend;

  const _ParentalConsentCard({
    required this.controller,
    required this.sending,
    required this.requested,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.family_restroom),
                const SizedBox(width: 8),
                Text('Parental consent required',
                    style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Because you\'re under 13, a parent or guardian must approve your '
              'account. We\'ll email them a consent link.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              enabled: !requested,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Parent/guardian email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: (sending || requested) ? null : onSend,
                child: sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(requested ? 'Request sent ✓' : 'Send consent request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
