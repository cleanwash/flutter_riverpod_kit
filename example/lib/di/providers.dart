import 'package:flutter_riverpod_kit/flutter_riverpod_kit.dart';

import '../data/data_source/photo_api.dart';
import '../data/repository/photo_repository_impl.dart';
import '../domain/repository/photo_repository.dart';
import '../domain/use_case/get_photos_use_case.dart';

// riverpod의 Provider 그래프 자체가 DI 컨테이너 역할을 합니다.
// get_it/injectable(flutter_basic_kit_library에 포함됨) 연동은 아직 보류.

final photoApiProvider = Provider<PhotoApi>((ref) => PhotoApi());

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl(ref.watch(photoApiProvider));
});

final getPhotosUseCaseProvider = Provider<GetPhotosUseCase>((ref) {
  return GetPhotosUseCase(ref.watch(photoRepositoryProvider));
});
