## 0.0.3

* `dart run flutter_riverpod_kit:init [feature]` 스캐폴딩 명령 추가(`bin/init.dart`). data/domain 레이어 폴더, 바로 실행되는 최소 `presentation/<feature>`(state/action/ui_event/view_model(Notifier)/screen), `di/providers.dart`, `core/routing/route_paths.dart`+`router.dart`(go_router) 뼈대를 생성하며, 기존 파일은 덮어쓰지 않음. feature명 기본값은 `home`. 폴더 구조는 provider/bloc kit과 동일.
* init 실행 시 `go_router`를 자동으로 `flutter pub add` 함. `flutter_riverpod`은 이미 re-export되므로 `provider`는 추가하지 않음.

## 0.0.2

* 라이브러리 진입점(`lib/flutter_riverpod_kit.dart`)에 dartdoc과 함께 `library;` 지시문 추가.

## 0.0.1

* 초기 릴리스: `Result`, `UseCase`, `UiEventEmitter<E>` 추가. `flutter_basic_kit_library`, `flutter_riverpod` 의존성 구성.
* `example/`을 data/domain/presentation/di 레이어 구조로 구성하고, mock 데이터소스 기반 사진 검색(home) 기능을 State/Action/ViewModel(onAction) 패턴으로 추가.
