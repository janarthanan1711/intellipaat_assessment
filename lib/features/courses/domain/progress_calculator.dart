abstract final class ProgressCalculator {
  /// Whole-number completion percentage in 0–100.
  ///
  /// Rounds down, so a course reads 100% only when every lesson is done
  /// (199/200 is 99%, not a misleading 100%).
  static int percent({required int completed, required int total}) {
    if (total <= 0) return 0;
    return clamp(completed * 100 ~/ total);
  }

  static int clamp(int percent) => percent.clamp(0, 100);
}
