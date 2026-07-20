import 'package:flutter_riverpod_kit/flutter_riverpod_kit.dart';
import 'package:flutter_test/flutter_test.dart';

sealed class _CounterEvent {}

class _Bumped extends _CounterEvent {}

class _CounterNotifier extends Notifier<int> with UiEventEmitter<_CounterEvent> {
  @override
  int build() {
    ref.onDispose(closeUiEvent);
    return 0;
  }

  void increment() {
    state += 1;
    emitEvent(_Bumped());
  }
}

final _counterProvider = NotifierProvider<_CounterNotifier, int>(_CounterNotifier.new);

class _DoubleUseCase extends UseCase<int, int> {
  @override
  Future<int> call(int params) async => params * 2;
}

void main() {
  test('starts with the initial state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(_counterProvider), 0);
  });

  test('increment updates state and emits a ui event', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final events = <_CounterEvent>[];
    container.read(_counterProvider.notifier).uiEvent.listen(events.add);

    container.read(_counterProvider.notifier).increment();
    await Future<void>.delayed(Duration.zero);

    expect(container.read(_counterProvider), 1);
    expect(events, hasLength(1));
  });

  test('Result.success and Result.failure pattern match', () {
    const success = Result<int>.success(1);
    const failure = Result<int>.failure('err');

    expect(switch (success) { Success(:final data) => data, Failure() => -1 }, 1);
    expect(
      switch (failure) { Success() => -1, Failure(:final error) => error },
      'err',
    );
  });

  test('UseCase can be implemented and called', () async {
    final useCase = _DoubleUseCase();
    final result = await useCase(21);
    expect(result, 42);
  });
}
