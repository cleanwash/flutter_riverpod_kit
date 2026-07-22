import 'dart:io';

/// Scaffolds the recommended `flutter_riverpod_kit` folder structure into the
/// current project's `lib/`, adds `go_router`, and generates a minimal,
/// ready-to-run feature wired to a router.
///
/// Usage (run from your app's project root):
///
/// ```bash
/// dart run flutter_riverpod_kit:init          # creates presentation/home/...
/// dart run flutter_riverpod_kit:init login    # creates presentation/login/...
/// ```
///
/// `flutter_riverpod` is already bundled (re-exported) by this package — no
/// `provider` dependency is needed — and the only extra dependency added is
/// `go_router`. Existing files are never overwritten.
Future<void> main(List<String> args) async {
  final feature = (args.isNotEmpty ? args.first : 'home').trim();
  if (!_isValidFeature(feature)) {
    stderr.writeln(
      "✗ Invalid feature name: '$feature'. Use snake_case letters/digits, "
      "e.g. `dart run flutter_riverpod_kit:init home`.",
    );
    exitCode = 64; // EX_USAGE
    return;
  }

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    stderr.writeln(
      "✗ No `lib/` directory here. Run this from your Flutter project root.",
    );
    exitCode = 66; // EX_NOINPUT
    return;
  }

  final className = _toPascalCase(feature);
  final camelName = _toCamelCase(feature);

  const emptyLayers = [
    'lib/data/data_source',
    'lib/data/repository',
    'lib/domain/model',
    'lib/domain/repository',
    'lib/domain/use_case',
  ];

  final files = <String, String>{
    for (final dir in emptyLayers) '$dir/.gitkeep': '',
    'lib/presentation/$feature/${feature}_state.dart': _stateStub(className),
    'lib/presentation/$feature/${feature}_action.dart': _actionStub(className),
    'lib/presentation/$feature/${feature}_ui_event.dart':
        _uiEventStub(className),
    'lib/presentation/$feature/${feature}_view_model.dart':
        _viewModelStub(className, camelName, feature),
    'lib/presentation/$feature/${feature}_screen.dart':
        _screenStub(className, camelName, feature),
    'lib/di/providers.dart': _diStub(),
    'lib/core/routing/route_paths.dart': _routePathsStub(camelName),
    'lib/core/routing/router.dart': _routerStub(className, camelName, feature),
  };

  final created = <String>[];
  final skipped = <String>[];

  files.forEach((path, contents) {
    final file = File(path);
    if (file.existsSync()) {
      skipped.add(path);
      return;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(contents);
    created.add(path);
  });

  stdout.writeln('flutter_riverpod_kit — scaffolding "$feature"\n');
  for (final path in created) {
    stdout.writeln('  + $path');
  }
  for (final path in skipped) {
    stdout.writeln('  · $path (exists, left untouched)');
  }

  await _addDependencies(const ['go_router']);

  stdout.writeln(
    '\n✓ Done. Wrap your app in `ProviderScope`, wire `router` '
    '(lib/core/routing/router.dart) into MaterialApp.router() to see '
    '${className}Screen run.',
  );
}

bool _isValidFeature(String name) =>
    RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name);

String _toPascalCase(String snake) => snake
    .split('_')
    .where((part) => part.isNotEmpty)
    .map((part) => part[0].toUpperCase() + part.substring(1))
    .join();

String _toCamelCase(String snake) {
  final pascal = _toPascalCase(snake);
  return pascal.isEmpty ? pascal : pascal[0].toLowerCase() + pascal.substring(1);
}

/// Adds any of [packages] not already present in `pubspec.yaml` via
/// `flutter pub add`. Never throws — on failure it prints manual instructions
/// so the scaffold still succeeds offline.
Future<void> _addDependencies(List<String> packages) async {
  final pubspec = File('pubspec.yaml');
  final contents = pubspec.existsSync() ? pubspec.readAsStringSync() : '';
  final missing = packages
      .where((p) => !RegExp('^\\s+$p:', multiLine: true).hasMatch(contents))
      .toList();

  if (missing.isEmpty) {
    stdout.writeln('\nDependencies already present: ${packages.join(', ')}');
    return;
  }

  stdout.writeln('\nAdding dependencies: ${missing.join(', ')} ...');
  try {
    final result =
        await Process.run('flutter', ['pub', 'add', ...missing], runInShell: true);
    if (result.exitCode == 0) {
      stdout.writeln('  ✓ ${missing.join(', ')} added');
    } else {
      stdout.writeln('  ! `flutter pub add` failed:\n${result.stderr}');
      stdout.writeln('  → Add manually: flutter pub add ${missing.join(' ')}');
    }
  } catch (_) {
    stdout.writeln('  ! Could not run `flutter`.');
    stdout.writeln('  → Add manually: flutter pub add ${missing.join(' ')}');
  }
}

String _stateStub(String c) => '''/// State the $c screen reads on every rebuild.
class ${c}State {
  const ${c}State({this.isLoading = false});

  final bool isLoading;

  ${c}State copyWith({bool? isLoading}) {
    return ${c}State(isLoading: isLoading ?? this.isLoading);
  }
}
''';

String _actionStub(String c) =>
    '''/// Every user-triggered event the $c screen can produce, dispatched
/// through `${c}ViewModel.onAction`.
sealed class ${c}Action {
  const ${c}Action();
}

/// Fired once when the screen first appears. Add more actions as needed.
class ${c}Started extends ${c}Action {
  const ${c}Started();
}
''';

String _uiEventStub(String c) =>
    '''/// One-off effects the screen reacts to once (snackbar, navigation, ...),
/// as opposed to `${c}State` which the screen reads continuously.
sealed class ${c}UiEvent {
  const ${c}UiEvent();
}

class ShowSnackBar extends ${c}UiEvent {
  const ShowSnackBar(this.message);
  final String message;
}
''';

String _viewModelStub(String c, String camel, String f) =>
    '''import 'package:flutter_riverpod_kit/flutter_riverpod_kit.dart';

import '${f}_action.dart';
import '${f}_state.dart';
import '${f}_ui_event.dart';

final ${camel}ViewModelProvider =
    NotifierProvider<${c}ViewModel, ${c}State>(${c}ViewModel.new);

class ${c}ViewModel extends Notifier<${c}State>
    with UiEventEmitter<${c}UiEvent> {
  @override
  ${c}State build() {
    ref.onDispose(closeUiEvent);
    // Read your use cases here, e.g.:
    // _getSomething = ref.watch(getSomethingUseCaseProvider);
    return const ${c}State();
  }

  /// Single entry point for every user-triggered action. Dispatch with a
  /// `switch` over the sealed [${c}Action] so new cases can't be missed.
  void onAction(${c}Action action) {
    switch (action) {
      case ${c}Started():
        _onStarted();
    }
  }

  Future<void> _onStarted() async {
    state = state.copyWith(isLoading: true);
    // TODO: call a use case, then update state.
    state = state.copyWith(isLoading: false);
    emitEvent(const ShowSnackBar('$c ready'));
  }
}
''';

String _screenStub(String c, String camel, String f) =>
    '''import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod_kit/flutter_riverpod_kit.dart';

import '${f}_action.dart';
import '${f}_ui_event.dart';
import '${f}_view_model.dart';

class ${c}Screen extends ConsumerStatefulWidget {
  const ${c}Screen({super.key});

  @override
  ConsumerState<${c}Screen> createState() => _${c}ScreenState();
}

class _${c}ScreenState extends ConsumerState<${c}Screen> {
  late final StreamSubscription<${c}UiEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription =
        ref.read(${camel}ViewModelProvider.notifier).uiEvent.listen(_handleEvent);
    Future.microtask(
      () => ref
          .read(${camel}ViewModelProvider.notifier)
          .onAction(const ${c}Started()),
    );
  }

  void _handleEvent(${c}UiEvent event) {
    switch (event) {
      case ShowSnackBar(:final message):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to state directly with ref.watch — no wrapper widget required.
    final state = ref.watch(${camel}ViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('$c')),
      body: Center(
        child: state.isLoading
            ? const CircularProgressIndicator()
            : const Text('$c screen'),
      ),
    );
  }
}
''';

String _diStub() =>
    '''// riverpod's Provider graph is your DI container.
// Declare shared providers here, e.g.:
//
// final photoApiProvider = Provider<PhotoApi>((ref) => PhotoApi());
// final photoRepositoryProvider = Provider<PhotoRepository>(
//   (ref) => PhotoRepositoryImpl(ref.watch(photoApiProvider)),
// );
''';

String _routePathsStub(String camel) =>
    '''/// Centralized route paths — reference these instead of raw path strings.
abstract final class RoutePaths {
  const RoutePaths._();

  static const String $camel = '/';
}
''';

String _routerStub(String c, String camel, String f) =>
    '''import 'package:go_router/go_router.dart';

import '../../presentation/$f/${f}_screen.dart';
import 'route_paths.dart';

/// App router. Plug into your app root (inside a `ProviderScope`):
///
/// ```dart
/// MaterialApp.router(routerConfig: router);
/// ```
final GoRouter router = GoRouter(
  routes: [
    GoRoute(
      path: RoutePaths.$camel,
      builder: (context, state) => const ${c}Screen(),
    ),
  ],
);
''';
