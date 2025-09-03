part of 'auth_card_builder.dart';

class _AdditionalSignUpCard extends ConsumerStatefulWidget {
  _AdditionalSignUpCard({
    super.key,
    required this.formFields,
    required this.onBack,
    this.loginTheme,
    required this.onSubmitCompleted,
    required this.loadingController,
    required this.initialIsoCode,
  }) {
    if (formFields.isEmpty) {
      throw RangeError('The formFields array must not be empty');
    } else if (formFields.length > 6) {
      throw RangeError(
        'More than 6 formFields are not displayable, you provided ${formFields.length}',
      );
    }
  }

  final List<UserFormField> formFields;
  final VoidCallback onBack;
  final VoidCallback onSubmitCompleted;
  final LoginTheme? loginTheme;
  final AnimationController loadingController;
  final String? initialIsoCode;

  @override
  ConsumerState<_AdditionalSignUpCard> createState() => _AdditionalSignUpCardState();
}

class _AdditionalSignUpCardState extends ConsumerState<_AdditionalSignUpCard>
    with TickerProviderStateMixin {
  final GlobalKey<FormState> _formCompleteSignupKey = GlobalKey();
  late Map<String, TextEditingController> _nameControllers;
  late List<AnimationController> _fieldAnimationControllers = [];
  late AnimationController _submitController;
  late Animation<double> _buttonScaleAnimation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _nameControllers = {
      for (final formField in widget.formFields)
        formField.keyName: TextEditingController(
          text: formField.defaultValue,
        ),
    };

    if (_nameControllers.length != widget.formFields.length) {
      throw ArgumentError(
        'Some of the formFields have duplicated names, and this is not allowed.',
      );
    }

    _fieldAnimationControllers = widget.formFields
        .map(
          (e) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      ),
    )
        .toList();

    _submitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _buttonScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.loadingController,
        curve: const Interval(.4, 1.0, curve: Curves.easeOutBack),
      ),
    );
  }

  @override
  void dispose() {
    for (final element in _fieldAnimationControllers) {
      element.dispose();
    }
    _submitController.dispose();
    super.dispose();
  }

  Future<bool> _submit() async {
    FocusScope.of(context).unfocus();

    final messages = ref.read(loginMessagesProvider);
    final auth = ref.read(authProvider);

    if (!_formCompleteSignupKey.currentState!.validate()) {
      return false;
    }

    _formCompleteSignupKey.currentState!.save();
    await _submitController.forward();
    setState(() => _isSubmitting = true);

    String? error;
    auth.additionalSignupData =
        _nameControllers.map((key, value) => MapEntry(key, value.text));

    switch (auth.authType) {
      case AuthType.provider:
        error = await auth.onSignup!(
          SignupData.fromProvider(
            additionalSignupData: auth.additionalSignupData,
          ),
        );
        break;
      case AuthType.userPassword:
        error = await auth.onSignup!(
          SignupData.fromSignupForm(
            name: auth.email,
            password: auth.password,
            additionalSignupData: auth.additionalSignupData,
            termsOfService: auth.getTermsOfServiceResults(),
          ),
        );
        break;
    }

    if (context.mounted) {
      await _submitController.reverse();
    }

    if (!isNullOrEmpty(error)) {
      if (context.mounted) {
        showErrorToast(context, messages.tycoonToastTitleError, error!);
      }
      setState(() => _isSubmitting = false);
      return false;
    } else {
      if (context.mounted) {
        showSuccessToast(
          context,
          messages.tycoonToastTitleSuccess,
          messages.signUpSuccess,
          const Duration(seconds: 4),
        );
      }

      setState(() => _isSubmitting = false);
      widget.onSubmitCompleted();
      return true;
    }
  }

  Widget _buildFields(double width) {
    return Column(
      children: widget.formFields.map((UserFormField formField) {
        return Column(
          children: [
            const SizedBox(height: 10),
            AnimatedTextFormField(
              userType: formField.userType,
              controller: _nameControllers[formField.keyName],
              loadingController: widget.loadingController,
              width: width,
              labelText: formField.displayName,
              prefixIcon: formField.icon ?? const Icon(FontAwesomeIcons.solidCircleUser),
              keyboardType: getKeyboardType(formField.userType),
              autofillHints: [getAutofillHints(formField.userType)],
              textInputAction: formField.keyName == widget.formFields.last.keyName
                  ? TextInputAction.done
                  : TextInputAction.next,
              validator: formField.fieldValidator,
              tooltip: formField.tooltip,
              initialIsoCode: widget.initialIsoCode,
            ),
            const SizedBox(height: 5),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, LoginMessages messages) {
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: AnimatedButton(
        controller: _submitController,
        text: messages.additionalSignUpSubmitButton,
        onPressed: !_isSubmitting ? _submit : null,
      ),
    );
  }

  Widget _buildBackButton(
      ThemeData theme,
      LoginMessages messages,
      LoginTheme? loginTheme,
      ) {
    final calculatedTextColor =
    (theme.cardTheme.color!.computeLuminance() < 0.5)
        ? Colors.white
        : theme.primaryColor;
    return ScaleTransition(
      scale: _buttonScaleAnimation,
      child: MaterialButton(
        onPressed: !_isSubmitting
            ? () {
          _formCompleteSignupKey.currentState!.save();
          widget.onBack();
        }
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textColor: loginTheme?.switchAuthTextColor ?? calculatedTextColor,
        child: Text(messages.goBackButton),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messages = ref.watch(loginMessagesProvider);
    final deviceSize = MediaQuery.of(context).size;
    final cardWidth = min(deviceSize.width * 0.75, 360.0);
    const cardPadding = 16.0;
    final textFieldWidth = cardWidth - cardPadding * 2;

    return FittedBox(
      child: Card(
        child: Container(
          padding: const EdgeInsets.only(
            left: cardPadding,
            top: cardPadding + 10.0,
            right: cardPadding,
            bottom: cardPadding,
          ),
          width: cardWidth,
          alignment: Alignment.center,
          child: Form(
            key: _formCompleteSignupKey,
            child: Column(
              children: [
                ScaleTransition(
                  scale: _buttonScaleAnimation,
                  child: Text(
                    messages.additionalSignUpFormDescription,
                    key: kRecoverPasswordIntroKey,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                _buildFields(textFieldWidth),
                const SizedBox(height: 5),
                _buildSubmitButton(theme, messages),
                _buildBackButton(theme, messages, widget.loginTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }
}