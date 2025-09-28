import 'package:flutter/material.dart';
import '../../../core/utils/input_validator.dart';

class SafeText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final bool softWrap;

  const SafeText(
      this.data, {
        super.key,
        this.style,
        this.textAlign,
        this.overflow,
        this.maxLines,
        this.softWrap = true,
      });

  @override
  Widget build(BuildContext context) {
    final safeData = InputValidator.safeString(data);

    return Text(
      safeData,
      style: style,
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
      softWrap: softWrap,
    );
  }
}