class PredictionPolicy {
  static const double confidenceThreshold = 0.60;
  static const double nonPlantThreshold = 0.15;

  static Map<String, dynamic> evaluate({
    required double maxProb,
    required String predictedLabel,
    required bool inTestedSet,
  }) {
    if (maxProb >= confidenceThreshold && inTestedSet) {
      return {'plant': predictedLabel, 'confidence': maxProb, 'isConfident': true};
    } else if (maxProb < nonPlantThreshold) {
      return {
        'plant': null,
        'confidence': maxProb,
        'isConfident': false,
        'message': 'This does not look like one of the trained plants. Try a clearer leaf photo.',
      };
    } else {
      return {
        'plant': null,
        'confidence': maxProb,
        'isConfident': false,
        'message': 'Low confidence (${(maxProb * 100).toStringAsFixed(1)}%). High Uncertainty. Try taking a clearer picture of the plant.',
      };
    }
  }
}
