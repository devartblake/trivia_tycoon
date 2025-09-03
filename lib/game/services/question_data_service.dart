import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/question_model.dart';

Future<List<QuestionModel>> loadQuestionsFromAsset(String category) async {
  final String jsonStr = await rootBundle.loadString('assets/data/questions/$category.json');
  final List<dynamic> data = json.decode(jsonStr);
  return data.map((e) => QuestionModel.fromJson(e)).toList();
}