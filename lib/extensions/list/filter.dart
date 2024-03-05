// Extend any Stream with T where we can acce3ss T
// Stream containing a stream T where it must pass filter
extension Filter<T> on Stream<List<T>> {
  Stream<List<T>> filter(bool Function(T) where) =>
      map((items) => items.where(where).toList());
}
