import 'package:flutter_riverpod_kit/flutter_riverpod_kit.dart';

import '../../di/providers.dart';
import '../../domain/use_case/get_photos_use_case.dart';
import 'home_action.dart';
import 'home_state.dart';
import 'home_ui_event.dart';

final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

class HomeViewModel extends Notifier<HomeState> with UiEventEmitter<HomeUiEvent> {
  late final GetPhotosUseCase _getPhotosUseCase;

  @override
  HomeState build() {
    ref.onDispose(closeUiEvent);
    _getPhotosUseCase = ref.watch(getPhotosUseCaseProvider);
    return const HomeState();
  }

  /// Single entry point for every user-triggered action. Dispatch with a
  /// `switch` over the sealed [HomeAction] so new cases can't be missed.
  void onAction(HomeAction action) {
    switch (action) {
      case Search(:final query):
        _search(query);
    }
  }

  Future<void> _search(String query) async {
    state = state.copyWith(isLoading: true);

    switch (await _getPhotosUseCase(query)) {
      case Success(:final data):
        state = state.copyWith(photos: data, isLoading: false);
      case Failure(:final error):
        state = state.copyWith(isLoading: false);
        emitEvent(ShowErrorSnackBar(error.toString()));
    }
  }
}
