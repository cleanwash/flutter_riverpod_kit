import 'package:example/di/providers.dart';
import 'package:example/domain/model/photo.dart';
import 'package:example/domain/repository/photo_repository.dart';
import 'package:example/presentation/home/home_action.dart';
import 'package:example/presentation/home/home_ui_event.dart';
import 'package:example/presentation/home/home_view_model.dart';
import 'package:flutter_riverpod_kit/flutter_riverpod_kit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePhotoRepository implements PhotoRepository {
  _FakePhotoRepository(this.result);
  final Result<List<Photo>> result;

  @override
  Future<Result<List<Photo>>> getPhotos({required String query}) async {
    return result;
  }
}

void main() {
  test('Search action populates photos on success', () async {
    const photos = [Photo(id: 1, imageUrl: 'url', tags: 'cat')];
    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(
          _FakePhotoRepository(const Result.success(photos)),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(homeViewModelProvider.notifier).onAction(const Search('cat'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(homeViewModelProvider).photos, photos);
    expect(container.read(homeViewModelProvider).isLoading, isFalse);
  });

  test('Search action emits ShowErrorSnackBar on failure', () async {
    final container = ProviderContainer(
      overrides: [
        photoRepositoryProvider.overrideWithValue(
          _FakePhotoRepository(const Result.failure('network error')),
        ),
      ],
    );
    addTearDown(container.dispose);

    final events = <HomeUiEvent>[];
    container.read(homeViewModelProvider.notifier).uiEvent.listen(events.add);

    container.read(homeViewModelProvider.notifier).onAction(const Search('cat'));
    await Future<void>.delayed(Duration.zero);

    expect(container.read(homeViewModelProvider).isLoading, isFalse);
    expect(events, hasLength(1));
    expect(events.first, isA<ShowErrorSnackBar>());
  });
}
