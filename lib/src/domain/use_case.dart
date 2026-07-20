/// Base class for a single-purpose domain use case, following the
/// `domain/use_case/` convention. Implement [call] and inject the
/// repository interface the use case depends on (typically via a
/// `Provider` in `di/`).
abstract class UseCase<Output, Params> {
  const UseCase();

  Future<Output> call(Params params);
}
