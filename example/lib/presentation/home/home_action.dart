/// Every user-triggered event the home screen can produce, dispatched
/// through `HomeViewModel.onAction`.
sealed class HomeAction {
  const HomeAction();
}

class Search extends HomeAction {
  const Search(this.query);
  final String query;
}
