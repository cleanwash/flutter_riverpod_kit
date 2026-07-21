import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod_kit/flutter_riverpod_kit.dart';

import 'components/photo_widget.dart';
import 'home_action.dart';
import 'home_ui_event.dart';
import 'home_view_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final StreamSubscription<HomeUiEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(homeViewModelProvider.notifier).uiEvent.listen(_handleEvent);
    Future.microtask(
      () => ref.read(homeViewModelProvider.notifier).onAction(const Search('flutter')),
    );
  }

  void _handleEvent(HomeUiEvent event) {
    switch (event) {
      case ShowErrorSnackBar(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ref.watch()로 상태를 직접 구독해서 화면에서 바로 사용합니다.
    final state = ref.watch(homeViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('flutter_riverpod_kit example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(homeViewModelProvider.notifier)
                .onAction(const Search('flutter')),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: state.photos.length,
              itemBuilder: (context, index) {
                return PhotoWidget(photo: state.photos[index]);
              },
            ),
    );
  }
}
