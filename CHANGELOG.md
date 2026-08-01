## 0.0.6

_(요약: flutter_riverpod 3.x 허용, CHANGELOG 비ASCII 비율 정리)_

* Widened the `flutter_riverpod` constraint from `^2.6.1` to `">=2.6.1 <4.0.0"` so the package resolves against the latest stable 3.x release, not just 2.x. Verified against `flutter_riverpod` 3.4.2 with `flutter analyze` and `flutter test` (both this package and `example/`); the kit only relies on `Notifier`/`NotifierProvider`/`ref.watch`/`ref.read`/`ref.onDispose`, which are stable across 2.x and 3.x.
* Rewrote `CHANGELOG.md` primarily in English, with a short Korean summary line per version, to keep pub.dev's non-ASCII ratio check passing while staying readable in Korean.

## 0.0.5

_(요약: init이 테스트 뼈대도 함께 생성)_

* `init` now also generates test scaffolding: creates `test/presentation/<feature>/<feature>_view_model_test.dart` with an initial-state assertion and a `ShowSnackBar` UI event emission test, plus a guide comment for overriding providers with fakes as use cases grow. The consuming app's package name is read automatically from its pubspec.

## 0.0.4

_(요약: basic_kit의 pubspec을 읽어 의존성 자동 미러링)_

* `init` now reads `flutter_basic_kit_library`'s own `pubspec.yaml` directly and mirrors all of its runtime and dev dependencies into the consuming app via `flutter pub add`. The dependency list is no longer hardcoded; `flutter_basic_kit_library` is now the single source of truth, so adding or updating a library there flows through automatically without touching `init` (reflects `flutter_basic_kit_library ^0.0.3`, including `intl` and `flutter_secure_storage`).
* State-management libraries (`provider`/`flutter_bloc`/`flutter_riverpod`) are excluded from mirroring, since each kit already provides its own dependency and re-export, so `provider` no longer gets pulled into riverpod apps.
* data/domain layers are now created as empty directories, without `.gitkeep`.
* Added `executables:`, so after `dart pub global activate flutter_riverpod_kit` the shorter `riverpod_kit init [feature]` command is available.
* Added the `yaml` dependency, used by `init` to parse `flutter_basic_kit_library`'s pubspec.

## 0.0.3

_(요약: init 스캐폴딩 명령 추가)_

* Added the `dart run flutter_riverpod_kit:init [feature]` scaffolding command (`bin/init.dart`). Generates data/domain layer folders, a minimal runnable `presentation/<feature>` (state/action/ui_event/view_model(Notifier)/screen), `di/providers.dart`, and `core/routing/route_paths.dart` + `router.dart` (go_router) scaffolding, without overwriting existing files. Feature name defaults to `home`. Folder structure matches the provider/bloc kits.
* `init` now automatically runs `flutter pub add` for `go_router`. `flutter_riverpod` is already re-exported, so `provider` is not added.

## 0.0.2

_(요약: 라이브러리 진입점에 dartdoc 추가)_

* Added a `library;` directive with dartdoc to the library entry point (`lib/flutter_riverpod_kit.dart`).

## 0.0.1

_(요약: 초기 릴리스)_

* Initial release: added `Result`, `UseCase`, `UiEventEmitter<E>`. Configured `flutter_basic_kit_library` and `flutter_riverpod` dependencies.
* Structured `example/` into data/domain/presentation/di layers and added a mock-datasource-based photo search (home) feature using the State/Action/ViewModel(onAction) pattern.
