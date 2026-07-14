import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/core/manager/log_manager.dart';
import '../../../core/services/compliance/compliance_consent_api_client.dart';
import '../../../core/services/compliance/compliance_consent_providers.dart';
import '../../../game/controllers/onboarding_controller.dart';
import '../widgets/onboarding_step_shell.dart';

/// Onboarding step: exact-age verification + Terms/Privacy/Marketing consent,
/// with a parental-consent email flow for minors (under 13). Backed by
/// Synaptix.Compliance.Api.
///
/// Fail-open: the compliance service is optional in alpha (defaults to the API
/// host and may be undeployed). Backend errors are logged and never block the
/// user from completing onboarding — required consent is enforced client-side
/// and `isMinor` is derived from the entered age when the server is unreachable.
class AgeVerificationStep extends ConsumerStatefulWidget {
  final ModernOnboardingController controller;

  const AgeVerificationStep({super.key, required this.controller});

  /// Policy version recorded with each consent decision.
  static const policyVersion = '2026-01';

  /// Age below which parental consent is required (COPPA).
  static const minorThreshold = 13;

  @override
  ConsumerState<AgeVerificationStep> createState() =>
      _AgeVerificationStepState();
}

class _AgeVerificationStepState extends ConsumerState<AgeVerificationStep> {
  final _ageCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();

  int? _verifiedAge;
  bool? _isMinor;
  bool _verifying = false;

  bool _sendingParent = false;
  bool _parentRequested = false;

  bool _terms = false;
  bool _privacy = false;
  bool _marketing = false;
  bool _continuing = false;

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

  Future<void> _verifyAge() async {
    final age = int.tryParse(_ageCtrl.text.trim());
    if (age == null || age < 1 || age > 120) {
      _snack('Enter a valid age (1–120).');
      return;
    }
    setState(() => _verifying = true);
    bool minor = age < AgeVerificationStep.minorThreshold;
    try {
      // Best-effort: prefer the server's determination when reachable.
      minor = await _client.submitAge(age);
    } on ComplianceConsentApiException catch (e) {
      LogManager.debug(
          '[AgeVerificationStep] submitAge failed (fail-open): $e');
    } catch (e) {
      LogManager.debug('[AgeVerificationStep] submitAge error (fail-open): $e');
    } finally {
      if (mounted) {
        setState(() {
          _verifiedAge = age;
          _isMinor = minor;
          _verifying = false;
        });
      }
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
      if (mounted) setState(() => _parentRequested = true);
      _snack('Parental consent request sent to $email.');
    } on ComplianceConsentApiException catch (e) {
      // Fail-open: allow progress even if the email could not be dispatched.
      LogManager.debug('[AgeVerificationStep] parental consent failed: $e');
      if (mounted) setState(() => _parentRequested = true);
      _snack('We\'ll follow up on parental consent shortly.');
    } finally {
      if (mounted) setState(() => _sendingParent = false);
    }
  }

  bool get _canContinue {
    if (_verifiedAge == null || !_terms || !_privacy || _continuing) {
      return false;
    }
    if (_isMinor == true && !_parentRequested) return false;
    return true;
  }

  Future<void> _continue() async {
    setState(() => _continuing = true);
    // Best-effort consent recording — never blocks onboarding.
    for (final entry in <String, bool>{
      'TermsOfService': true,
      'PrivacyPolicy': true,
      'Marketing': _marketing,
    }.entries) {
      try {
        await _client.recordConsent(
          consentType: entry.key,
          consentGiven: entry.value,
          policyVersion: AgeVerificationStep.policyVersion,
        );
      } catch (e) {
        LogManager.debug(
            '[AgeVerificationStep] recordConsent ${entry.key}: $e');
      }
    }

    widget.controller.updateUserData({
      'declaredAge': _verifiedAge,
      'isMinor': _isMinor ?? false,
      'consentTos': true,
      'consentPrivacy': true,
      'consentMarketing': _marketing,
    });
    widget.controller.nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ageVerified = _verifiedAge != null;

    return OnboardingStepShell(
      hero: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text('🔒', style: TextStyle(fontSize: 40))),
      ),
      panelIllustration: const Text('🔒', style: TextStyle(fontSize: 120)),
      title: 'Verify your age',
      subtitle: 'This keeps the experience appropriate and compliant. '
          'Players under 13 need a parent or guardian\'s consent.',
      footer: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _canContinue ? _continue : null,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _continuing
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isMinor == true && !_parentRequested
                  ? 'Awaiting parental consent'
                  : 'Continue'),
        ),
      ),
      child: ListView(
        children: [
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
                onPressed: (_verifying || ageVerified) ? null : _verifyAge,
                child: _verifying
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Verify'),
              ),
            ],
          ),
          if (_isMinor == true) ...[
            const SizedBox(height: 20),
            _ParentalConsentCard(
              controller: _parentEmailCtrl,
              sending: _sendingParent,
              requested: _parentRequested,
              onSend: _requestParentConsent,
            ),
          ],
          const SizedBox(height: 16),
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
                Expanded(
                  child: Text('Parental consent required',
                      style: theme.textTheme.titleSmall),
                ),
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
                    : Text(
                        requested ? 'Request sent ✓' : 'Send consent request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
