import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

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

  // Architecture layers are created as empty directories (no .gitkeep);
  // fill them in per feature (data_source, repository, model, use_case, ...).
  for (final dir in emptyLayers) {
    Directory(dir).createSync(recursive: true);
    created.add('$dir/');
  }

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

  // Read flutter_basic_kit_library's own pubspec and mirror its dependency
  // stack into the consumer app. This keeps the list a single source of truth:
  // updating flutter_basic_kit_library is enough — init needs no changes.
  // flutter_riverpod is already bundled via this package.
  await _syncBasicKitDependencies();

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

/// Reads flutter_basic_kit_library's pubspec (resolved as a transitive
/// dependency of this package) and adds the same runtime + dev dependencies to
/// the consumer app. flutter_basic_kit_library is the single source of truth —
/// updating it is automatically reflected here. Falls back to a built-in list
/// if it can't be located (e.g. offline / unusual setups).
Future<void> _syncBasicKitDependencies() async {
  final pubspec = _findBasicKitPubspec();
  Map<String, String> runtime;
  Map<String, String> dev;

  if (pubspec == null) {
    stdout.writeln(
      '\n! Could not locate flutter_basic_kit_library — using built-in list.',
    );
    runtime = _fallbackRuntime;
    dev = _fallbackDev;
  } else {
    final doc = loadYaml(pubspec.readAsStringSync());
    // State-management libs come from THIS kit (dependency + re-export), so
    // exclude them from the basic_kit mirror — a riverpod/bloc app must not get
    // provider (or the other kits' libs) dragged in.
    runtime = _extractDeps(
      doc is YamlMap ? doc['dependencies'] : null,
      denylist: _stateMgmtDenylist,
    );
    dev = _extractDeps(
      doc is YamlMap ? doc['dev_dependencies'] : null,
      denylist: _devDenylist,
    );
    stdout.writeln(
      '\nMirroring flutter_basic_kit_library dependencies '
      '(${runtime.length} runtime, ${dev.length} dev).',
    );
  }

  await _addDependencies(runtime);
  await _addDependencies(dev, dev: true);
}

/// Locates flutter_basic_kit_library's pubspec.yaml through the consumer app's
/// `.dart_tool/package_config.json`. Returns null if it isn't resolved.
File? _findBasicKitPubspec() {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;
  try {
    final json = jsonDecode(config.readAsStringSync()) as Map<String, dynamic>;
    final packages = json['packages'] as List<dynamic>;
    for (final entry in packages.cast<Map<String, dynamic>>()) {
      if (entry['name'] != 'flutter_basic_kit_library') continue;
      var rootUri = entry['rootUri'] as String;
      if (!rootUri.endsWith('/')) rootUri = '$rootUri/';
      final pubspecUri =
          config.absolute.uri.resolve(rootUri).resolve('pubspec.yaml');
      final pubspec = File.fromUri(pubspecUri);
      return pubspec.existsSync() ? pubspec : null;
    }
  } catch (_) {
    // Malformed config — fall through to the built-in fallback list.
  }
  return null;
}

/// Turns a pubspec `dependencies`/`dev_dependencies` node into a
/// {name: versionConstraint} map, keeping only simple hosted deps (a version
/// string) and dropping sdk/git/path entries plus anything in [denylist].
Map<String, String> _extractDeps(
  Object? node, {
  Set<String> denylist = const {},
}) {
  final deps = <String, String>{};
  if (node is! YamlMap) return deps;
  node.forEach((key, value) {
    final name = key.toString();
    if (denylist.contains(name)) return;
    if (value is String) deps[name] = value;
  });
  return deps;
}

/// Dev tools flutter_basic_kit_library declares that every Flutter app already
/// has — skip them so we don't fight the app's own versions.
const _devDenylist = {'flutter_test', 'flutter_lints'};

/// State-management libs that each kit already provides via its own dependency
/// and re-export. Never mirror these from basic_kit, or a riverpod/bloc app
/// would pick up provider (and vice-versa) it doesn't need.
const _stateMgmtDenylist = {
  'provider',
  'flutter_bloc',
  'bloc',
  'flutter_riverpod',
  'riverpod',
};

/// Used only when flutter_basic_kit_library can't be located. Empty constraint
/// means "let pub pick a compatible version".
const _fallbackRuntime = <String, String>{
  'go_router': '',
  'dio': '',
  'retrofit': '',
  'get_it': '',
  'injectable': '',
  'freezed_annotation': '',
  'json_annotation': '',
  'google_fonts': '',
  'curved_navigation_bar': '',
  'flutter_native_splash': '',
};
const _fallbackDev = <String, String>{
  'build_runner': '',
  'freezed': '',
  'json_serializable': '',
  'injectable_generator': '',
  'retrofit_generator': '',
};

/// Adds any of [deps] (name → version constraint; empty = unpinned) not already
/// present in `pubspec.yaml`. Never throws — on failure it prints manual
/// instructions so the scaffold still succeeds offline.
Future<void> _addDependencies(
  Map<String, String> deps, {
  bool dev = false,
}) async {
  if (deps.isEmpty) return;
  final label = dev ? 'dev dependencies' : 'dependencies';
  final flag = dev ? '--dev ' : '';
  final pubspec = File('pubspec.yaml');
  final contents = pubspec.existsSync() ? pubspec.readAsStringSync() : '';
  final missing = deps.keys
      .where((p) => !RegExp('^\\s+$p:', multiLine: true).hasMatch(contents))
      .toList();

  if (missing.isEmpty) {
    stdout.writeln('\n$label already present: ${deps.keys.join(', ')}');
    return;
  }

  final args = [
    for (final p in missing) (deps[p] ?? '').isEmpty ? p : '$p:${deps[p]}',
  ];
  stdout.writeln('\nAdding $label: ${missing.join(', ')} ...');
  try {
    final result = await Process.run(
      'flutter',
      ['pub', 'add', if (dev) '--dev', ...args],
      runInShell: true,
    );
    if (result.exitCode == 0) {
      stdout.writeln('  ✓ ${missing.join(', ')} added');
    } else {
      stdout.writeln('  ! `flutter pub add` failed:\n${result.stderr}');
      stdout.writeln('  → Add manually: flutter pub add $flag${args.join(' ')}');
    }
  } catch (_) {
    stdout.writeln('  ! Could not run `flutter`.');
    stdout.writeln('  → Add manually: flutter pub add $flag${args.join(' ')}');
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
