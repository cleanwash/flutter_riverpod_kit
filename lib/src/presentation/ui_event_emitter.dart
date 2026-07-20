import 'dart:async';

import 'package:flutter/foundation.dart';

/// Mix into a riverpod `Notifier<S>`/`AsyncNotifier<S>` to add a one-off
/// UI event channel (snackbar, navigation, ...) alongside the notifier's
/// regular `state`.
///
/// ```dart
/// class HomeViewModel extends Notifier<HomeState> with UiEventEmitter<HomeUiEvent> {
///   @override
///   HomeState build() {
///     ref.onDispose(closeUiEvent);
///     return const HomeState();
///   }
/// }
/// ```
mixin UiEventEmitter<E> {
  final StreamController<E> _uiEventController = StreamController<E>.broadcast();
  Stream<E> get uiEvent => _uiEventController.stream;

  @protected
  void emitEvent(E event) => _uiEventController.add(event);

  /// Call from `ref.onDispose` in `build()` so the stream closes with the
  /// provider.
  void closeUiEvent() => _uiEventController.close();
}
