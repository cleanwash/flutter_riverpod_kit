# flutter_riverpod_kit

`flutter_riverpod` 기반으로 **data / domain / presentation** 레이어를 분리하는 아키텍처와, `ref.watch()`로 화면에서 바로 상태를 읽는 기반 클래스(`Result`, `UseCase`, `UiEventEmitter`)를 제공하는 [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library) 확장 패키지입니다. [flutter_provider_kit](https://github.com/cleanwash/flutter_provider_kit)과 같은 폴더 구조를 riverpod으로 구현한 버전입니다.

## 포함된 것

- `Result<T>` — `Success`/`Failure` sealed class. Dart 3 패턴 매칭(`switch`)으로 처리
- `UseCase<Output, Params>` — `domain/use_case/`의 유스케이스가 상속하는 기반 클래스
- `UiEventEmitter<E>` — riverpod `Notifier`에 mixin해서 1회성 UI 이벤트(스낵바, 네비게이션 등)를 `state`와 분리해서 관리
- `flutter_riverpod` 패키지 전체를 재export (별도로 추가할 필요 없음)

화면에서는 별도 래퍼 위젯 없이 표준 riverpod 방식 그대로 `ref.watch(myProvider)`로 직접 읽으면 됩니다.

## 설치

```yaml
dependencies:
  flutter_riverpod_kit: ^0.0.1
```

## 추천 폴더 구조

`example/`에 아래 구조로 "사진 검색" 기능이 실제로 구현되어 있습니다 (데이터는 mock).

```
lib/
  data/
    data_source/
      photo_api.dart              # 외부 API 호출 (여기서는 mock)
    repository/
      photo_repository_impl.dart  # domain의 abstract interface를 implements
  domain/
    model/
      photo.dart                  # freezed 모델
    repository/
      photo_repository.dart       # abstract interface
    use_case/
      get_photos_use_case.dart    # UseCase<Output, Params> 상속
  presentation/
    home/
      components/
        photo_widget.dart         # home 전용 위젯
      home_screen.dart            # ref.watch(homeViewModelProvider)로 상태를 읽고, onAction(Action)으로 이벤트 전달
      home_action.dart            # 화면에서 발생 가능한 모든 사용자 액션 (sealed)
      home_state.dart             # 화면이 매번 읽는 상태
      home_ui_event.dart          # 스낵바/네비게이션 같은 1회성 이벤트
      home_view_model.dart        # Notifier<HomeState> + UiEventEmitter<HomeUiEvent>, 단일 진입점 onAction(Action)
  di/
    providers.dart                # riverpod Provider 그래프 (DI)
  main.dart
test/
  data/
    photo_api_test.dart
  ui/
    home_view_model_test.dart
```

### 레이어 규칙

- **domain**은 Flutter/riverpod에 의존하지 않는 순수 비즈니스 로직입니다. `repository/`엔 추상 인터페이스만 두고, 실제 구현은 `data/repository/`에서 `implements`합니다.
- **data**는 `domain`의 인터페이스를 구현하고, 실제 API/DB 호출은 `data_source/`에 격리합니다.
- **presentation**은 기능(feature) 단위 폴더(`home/`, `detail/` ...)로 나누고, 그 안에 `state`/`event`/`view_model`/`screen`/`components`를 함께 둡니다.
- **di**는 riverpod의 `Provider` 그래프 자체가 DI 컨테이너입니다 (`ref.watch(otherProvider)`로 의존성을 연결). `get_it`/`injectable`(flutter_basic_kit_library에 포함됨) 연동은 아직 보류 — 필요해지면 `di/`에 추가합니다.

## 사용 예시

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

`onAction`은 이 예제 코드의 컨벤션입니다 (riverpod의 `Notifier`가 이미 `state` get/set을 제공하므로, 패키지 차원에서 별도 base class를 강제하지 않습니다). 화면에서 상태를 바꾸고 싶을 때는 개별 public 메서드를 늘리지 않고, `onAction(Action)` 하나만 호출하는 컨벤션을 유지하세요.

전체 동작은 [`example/`](example)를 참고하세요.

## 앞으로 고려 중인 것

- `repository`/`use_case` CRUD 보일러플레이트를 NestJS CLI 스타일로 자동 생성하는 code generator (미착수, 별도 논의 예정)
- DI를 `get_it`/`injectable`로 전환할지 여부

## 관련 패키지

| 패키지 | 상태 |
|---|---|
| [flutter_basic_kit_library](https://pub.dev/packages/flutter_basic_kit_library) | 게시됨 |
| [flutter_provider_kit](https://github.com/cleanwash/flutter_provider_kit) | 게시됨 |
| flutter_riverpod_kit | 이 패키지 |
| flutter_bloc_kit | 준비 중 |

## 버전 관리

[Semantic Versioning](https://semver.org/lang/ko/)을 따릅니다. 변경 이력은 [CHANGELOG.md](CHANGELOG.md) 참고.

## Additional information

저장소: https://github.com/cleanwash/flutter_riverpod_kit
이슈/버그 제보: [GitHub Issues](https://github.com/cleanwash/flutter_riverpod_kit/issues)
