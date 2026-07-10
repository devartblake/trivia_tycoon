import 'package:another_transformer_page_view/another_transformer_page_view.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

import '../../../../core/helpers/math_helper.dart';
import '../../../../core/helpers/matrix_helper.dart';

class CustomPageTransformer extends PageTransformer {
  @override
  Widget transform(Widget child, TransformInfo info) {
    final transform = perspective();
    final position = info.position!;
    final pageDt = 1 - position.abs();

    if (position > 0) {
      transform
        ..scaleByVector3(
            Vector3(lerp(0.6, 1.0, pageDt), lerp(0.6, 1.0, pageDt), 1.0))
        ..rotateY(position * -1.5);
    } else {
      transform
        ..scaleByVector3(
            Vector3(lerp(0.6, 1.0, pageDt), lerp(0.6, 1.0, pageDt), 1.0))
        ..rotateY(position * 1.5);
    }

    return Transform(
      alignment: Alignment.center,
      transform: transform,
      child: child,
    );
  }
}
