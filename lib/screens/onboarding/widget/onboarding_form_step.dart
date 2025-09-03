import 'package:flutter/material.dart';

class OnboardingFormStep extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onUserDataChanged;
  final VoidCallback onNext;

  const OnboardingFormStep({
    super.key,
    required this.onUserDataChanged,
    required this.onNext,
  });

  @override
  State<OnboardingFormStep> createState() => _OnboardingFormStepState();
}

class _OnboardingFormStepState extends State<OnboardingFormStep> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  String? _ageGroup;
  String? _country;
  bool _tryPremium = false;

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onUserDataChanged({
        'username': _usernameController.text,
        'ageGroup': _ageGroup,
        'country': _country,
        'isPremiumUser': _tryPremium,
      });
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.blueAccent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Tell us about yourself",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Username",
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Username is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _ageGroup,
                  decoration: const InputDecoration(
                    labelText: "Age Group",
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: "Under 13", child: Text("Under 13")),
                    DropdownMenuItem(value: "13-17", child: Text("13-17")),
                    DropdownMenuItem(value: "18-24", child: Text("18-24")),
                    DropdownMenuItem(value: "25+", child: Text("25+")),
                  ],
                  onChanged: (value) => setState(() => _ageGroup = value),
                  validator: (val) => val == null ? 'Please select an age group' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Country",
                    fillColor: Colors.white,
                    filled: true,
                  ),
                  onChanged: (val) => _country = val,
                  validator: (val) =>
                  val == null || val.isEmpty ? 'Country is required' : null,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: Icon(_tryPremium ? Icons.check_circle : Icons.star_border),
                  label: Text(_tryPremium ? 'Premium Selected' : 'Try Premium'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tryPremium ? Colors.amber : Colors.white,
                    foregroundColor: _tryPremium ? Colors.black : Colors.blue,
                  ),
                  onPressed: () => setState(() => _tryPremium = !_tryPremium),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text("Continue"),
          )
        ],
      ),
    );
  }
}
