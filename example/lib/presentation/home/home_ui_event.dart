/// One-off effects the screen reacts to once (snackbar, navigation, ...),
/// as opposed to [HomeState] which the screen reads continuously.
sealed class HomeUiEvent {
  const HomeUiEvent();
}

class ShowErrorSnackBar extends HomeUiEvent {
  const ShowErrorSnackBar(this.message);
  final String message;
}
