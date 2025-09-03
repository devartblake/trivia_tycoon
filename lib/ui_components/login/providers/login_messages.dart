import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginMessages {
  LoginMessages({
    this.userHint,
    this.passwordHint = defaultPasswordHint,
    this.confirmPasswordHint = defaultConfirmPasswordHint,
    this.forgotPasswordButton = defaultForgotPasswordButton,
    this.loginButton = defaultLoginButton,
    this.signupButton = defaultSignupButton,
    this.recoverPasswordButton = defaultRecoverPasswordButton,
    this.recoverPasswordIntro = defaultRecoverPasswordIntro,
    this.recoverPasswordDescription = defaultRecoverPasswordDescription,
    this.goBackButton = defaultGoBackButton,
    this.confirmPasswordError = defaultConfirmPasswordError,
    this.recoverPasswordSuccess = defaultRecoverPasswordSuccess,
    this.tycoonToastTitleError = defaultTycoonToastTitleError,
    this.tycoonToastTitleSuccess = defaultTycoonToastTitleSuccess,
    this.signUpSuccess = defaultSignUpSuccess,
    this.providersTitleFirst = defaultProvidersTitleFirst,
    this.providersTitleSecond = defaultProvidersTitleSecond,
    this.additionalSignUpSubmitButton = defaultAdditionalSignUpSubmitButton,
    this.additionalSignUpFormDescription = defaultAdditionalSignUpFormDescription,
    this.confirmSignupIntro = defaultConfirmSignupIntro,
    this.confirmationCodeHint = defaultConfirmationCodeHint,
    this.confirmationCodeValidationError = defaultConfirmationCodeValidationError,
    this.resendCodeButton = defaultResendCodeButton,
    this.resendCodeSuccess = defaultResendCodeSuccess,
    this.confirmSignupButton = defaultConfirmSignupButton,
    this.confirmSignupSuccess = defaultConfirmSignupSuccess,
    this.confirmRecoverIntro = defaultConfirmRecoverIntro,
    this.recoveryCodeHint = defaultRecoveryCodeHint,
    this.recoveryCodeValidationError = defaultRecoveryCodeValidationError,
    this.setPasswordButton = defaultSetPasswordButton,
    this.confirmRecoverSuccess = defaultConfirmRecoverSuccess,
    this.recoverCodePasswordDescription = defaultRecoverCodePasswordDescription,
  });

  static const defaultPasswordHint = 'Password';
  static const defaultConfirmPasswordHint = 'Confirm Password';
  static const defaultForgotPasswordButton = 'Forgot Password?';
  static const defaultLoginButton = 'LOGIN';
  static const defaultSignupButton = 'SIGNUP';
  static const defaultRecoverPasswordButton = 'RECOVER';
  static const defaultRecoverPasswordIntro = 'Reset your password here';
  static const defaultRecoverPasswordDescription = 'We will send your plain-text password to this email account.';
  static const defaultRecoverCodePasswordDescription = 'We will send a password recovery code to your email.';
  static const defaultGoBackButton = 'BACK';
  static const defaultConfirmPasswordError = 'Password do not match!';
  static const defaultRecoverPasswordSuccess = 'An email has been sent';
  static const defaultTycoonToastTitleSuccess = 'Success';
  static const defaultTycoonToastTitleError = 'Error';
  static const defaultSignUpSuccess = 'An activation link has been sent';
  static const defaultProvidersTitleFirst = 'or login with';
  static const defaultProvidersTitleSecond = 'or';
  static const defaultAdditionalSignUpSubmitButton = 'SUBMIT';
  static const defaultAdditionalSignUpFormDescription = 'Please fill in this form to complete the signup';
  static const defaultConfirmRecoverIntro = 'The recovery code to set a new password was sent to your email.';
  static const defaultRecoveryCodeHint = 'Recovery Code';
  static const defaultRecoveryCodeValidationError = 'Recovery code is empty';
  static const defaultSetPasswordButton = 'SET PASSWORD';
  static const defaultConfirmRecoverSuccess = 'Password recovered.';
  static const defaultConfirmSignupIntro = 'A confirmation code was sent to your email. Please enter the code to confirm your account.';
  static const defaultConfirmationCodeHint = 'Confirmation Code';
  static const defaultConfirmationCodeValidationError = 'Confirmation code is empty';
  static const defaultResendCodeButton = 'Resend Code';
  static const defaultResendCodeSuccess = 'A new email has been sent.';
  static const defaultConfirmSignupButton = 'CONFIRM';
  static const defaultConfirmSignupSuccess = 'Account confirmed.';

  final String? userHint;
  final String additionalSignUpSubmitButton;
  final String additionalSignUpFormDescription;
  final String passwordHint;
  final String confirmPasswordHint;
  final String forgotPasswordButton;
  final String loginButton;
  final String signupButton;
  final String recoverPasswordButton;
  final String recoverPasswordIntro;
  final String recoverPasswordDescription;
  final String goBackButton;
  final String confirmPasswordError;
  final String recoverPasswordSuccess;
  final String tycoonToastTitleError;
  final String tycoonToastTitleSuccess;
  final String signUpSuccess;
  final String providersTitleFirst;
  final String providersTitleSecond;
  final String confirmRecoverIntro;
  final String recoveryCodeHint;
  final String recoveryCodeValidationError;
  final String setPasswordButton;
  final String confirmRecoverSuccess;
  final String confirmSignupIntro;
  final String confirmationCodeHint;
  final String confirmationCodeValidationError;
  final String resendCodeButton;
  final String resendCodeSuccess;
  final String confirmSignupButton;
  final String confirmSignupSuccess;
  final String recoverCodePasswordDescription;
}

final loginMessagesProvider = Provider<LoginMessages>((ref) => LoginMessages());
