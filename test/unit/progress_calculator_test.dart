import 'package:flutter_test/flutter_test.dart';
import 'package:learning_dashboard/features/courses/domain/progress_calculator.dart';

void main() {
  test('converts completed lessons to a whole percentage', () {
    expect(ProgressCalculator.percent(completed: 13, total: 20), 65);
    expect(ProgressCalculator.percent(completed: 20, total: 20), 100);
  });

  test('never reports 100% while a lesson is still pending', () {
    expect(ProgressCalculator.percent(completed: 199, total: 200), 99);
  });

  test('a course without lessons is 0%, not a division error', () {
    expect(ProgressCalculator.percent(completed: 0, total: 0), 0);
  });
}
