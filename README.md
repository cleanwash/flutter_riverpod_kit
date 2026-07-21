# flutter_riverpod_kit

*Read this in other languages: [한국어](README.ko.md)*

A [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library) extension that provides a `flutter_riverpod`-based architecture separating **data / domain / presentation** layers, plus base classes (`Result`, `UseCase`, `UiEventEmitter`) built around reading state directly with `ref.watch()`. It mirrors [flutter_provider_kit](https://github.com/cleanwash/flutter_provider_kit)'s folder structure, implemented with riverpod.

## What's included

- `Result<T>` — a `Success`/`Failure` sealed class, handled with Dart 3 pattern matching (`switch`)
- `UseCase<Output, Params>` — base class the use cases under `domain/use_case/` extend
- `UiEventEmitter<E>` — a mixin for a riverpod `Notifier` that manages one-off UI events (snackbars, navigation) separately from `state`
- Re-exports the whole `flutter_riverpod` package (no need to add it separately)

Screens don't need a wrapper widget — read state the standard riverpod way, with `ref.watch(myProvider)`.

## Install

```yaml
dependencies:
  flutter_riverpod_kit: ^0.0.1
```

## Recommended folder structure

`example/` implements a "photo search" feature end to end (with mock data) using this structure.

```
lib/
  data/
    data_source/
      photo_api.dart              # external API calls (mocked here)
    repository/
      photo_repository_impl.dart  # implements the domain's abstract interface
  domain/
    model/
      photo.dart                  # freezed model
    repository/
      photo_repository.dart       # abstract interface
    use_case/
      get_photos_use_case.dart    # extends UseCase<Output, Params>
  presentation/
    home/
      components/
        photo_widget.dart         # widget local to home
      home_screen.dart            # reads state via ref.watch(homeViewModelProvider), dispatches via onAction(Action)
      home_action.dart            # every user action the screen can produce (sealed)
      home_state.dart             # the state the screen reads on every rebuild
      home_ui_event.dart          # one-off events like snackbars/navigation
      home_view_model.dart        # Notifier<HomeState> + UiEventEmitter<HomeUiEvent>, single onAction(Action) entry point
  di/
    providers.dart                # the riverpod Provider graph (DI)
  main.dart
test/
  data/
    photo_api_test.dart
  ui/
    home_view_model_test.dart
```

### Layer rules

- **domain** is pure business logic with no dependency on Flutter or riverpod. `repository/` holds only abstract interfaces; the real implementation lives in `data/repository/`.
- **data** implements `domain`'s interfaces and isolates real API/DB calls inside `data_source/`.
- **presentation** is split into per-feature folders (`home/`, `detail/`, ...), each bundling its own `state`/`event`/`view_model`/`screen`/`components`.
- **di** is riverpod's own `Provider` graph acting as the DI container (dependencies are wired with `ref.watch(otherProvider)`). `get_it`/`injectable` integration (already bundled via flutter_basic_kit_library) is on hold — add it under `di/` if it's ever needed.

## Usage

```dart
final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);

class HomeViewModel extends Notifier<HomeState> with UiEventEmitter<HomeUiEvent> {
  late final GetPhotosUseCase _getPhotosUseCase;

  @override
  HomeState build() {
    ref.onDispose(closeUiEvent);
    _getPhotosUseCase = ref.watch(getPhotosUseCaseProvider);
    return const HomeState();
  }

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
```

```dart
// screen
final state = ref.watch(homeViewModelProvider);
ref.read(homeViewModelProvider.notifier).onAction(const Search('flutter'));
```

`onAction` is this example's own convention (riverpod's `Notifier` already provides `state` get/set, so the package doesn't impose an extra base class on top of it). When a screen needs to change state, keep dispatching through a single `onAction(Action)` instead of growing more public methods.

See [`example/`](example) for the full working app.

## Under consideration

- A NestJS-CLI-style code generator for `repository`/`use_case` CRUD boilerplate (not started, to be discussed separately)
- Whether to move DI to `get_it`/`injectable`

## Related packages

| Package | Status |
|---|---|
| [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library) | Published |
| [flutter_provider_kit](https://pub.dev/packages/flutter_provider_kit) | Published |
| flutter_riverpod_kit | this package |
| [flutter_bloc_kit](https://pub.dev/packages/flutter_bloc_kit) | Published |

## Versioning

This package follows [Semantic Versioning](https://semver.org/). See [CHANGELOG.md](CHANGELOG.md) for the full history.

## Additional information

- Repository: https://github.com/cleanwash/flutter_riverpod_kit
- Issues: https://github.com/cleanwash/flutter_riverpod_kit/issues
