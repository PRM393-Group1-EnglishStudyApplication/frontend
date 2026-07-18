import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:prm_frontend/features/auth/presentation/providers/auth_providers.dart';
import 'package:prm_frontend/features/explanations/data/datasources/explanation_remote_data_source.dart';
import 'package:prm_frontend/features/explanations/data/models/explanation_model.dart';

final Provider<ExplanationRemoteDataSource> explanationRemoteDataSourceProvider =
    Provider<ExplanationRemoteDataSource>((Ref ref) {
  final Dio dio = ref.watch(authDioProvider);
  return ExplanationRemoteDataSourceImpl(dio);
});

typedef ExplanationRequest = ({String exerciseId, String userAnswer});

// FutureProvider.autoDispose.family - moi cap (exerciseId, userAnswer) la 1 request rieng,
// tu huy khi khong con widget nao lang nghe (dong bottom sheet).
final AutoDisposeFutureProviderFamily<ExplanationModel, ExplanationRequest> explanationProvider =
    FutureProvider.autoDispose.family<ExplanationModel, ExplanationRequest>((
  Ref ref,
  ExplanationRequest request,
) async {
  final ExplanationRemoteDataSource dataSource = ref.watch(explanationRemoteDataSourceProvider);
  return dataSource.explainWrongAnswer(request.exerciseId, request.userAnswer);
});
