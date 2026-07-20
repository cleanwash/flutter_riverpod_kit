import '../../domain/model/photo.dart';

class HomeState {
  const HomeState({
    this.photos = const [],
    this.isLoading = false,
  });

  final List<Photo> photos;
  final bool isLoading;

  HomeState copyWith({List<Photo>? photos, bool? isLoading}) {
    return HomeState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
