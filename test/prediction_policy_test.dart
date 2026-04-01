import 'package:flutter_test/flutter_test.dart';
import 'package:mitidawa/services/prediction_policy.dart';

void main() {
  group('PredictionPolicy.evaluate', () {
    test('returns confident prediction when confidence is >= 75% and label is in tested set', () {
      final result = PredictionPolicy.evaluate(
        maxProb: 0.80,
        predictedLabel: 'Neem',
        inTestedSet: true,
      );

      expect(result['plant'], 'Neem');
      expect(result['confidence'], 0.80);
      expect(result['isConfident'], true);
      expect(result.containsKey('message'), false);
    });

    test('returns low-confidence result (no plant) for confidence between 15% and 75%', () {
      final result = PredictionPolicy.evaluate(
        maxProb: 0.50,
        predictedLabel: 'Neem',
        inTestedSet: true,
      );

      expect(result['plant'], isNull);
      expect(result['confidence'], 0.50);
      expect(result['isConfident'], false);
      expect(
        result['message'],
        contains('Low confidence (50.0%). High Uncertainty. Try taking a clearer picture of the plant.'),
      );
    });

    test('returns non-plant result (no plant) for confidence below 15%', () {
      final result = PredictionPolicy.evaluate(
        maxProb: 0.10,
        predictedLabel: 'Neem',
        inTestedSet: true,
      );

      expect(result['plant'], isNull);
      expect(result['confidence'], 0.10);
      expect(result['isConfident'], false);
      expect(
        result['message'],
        'This does not look like one of the trained plants. Try a clearer leaf photo.',
      );
    });
  });
}
