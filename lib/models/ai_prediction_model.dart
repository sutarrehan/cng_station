class AiPredictionModel {
  final int estimatedWaitMinutes;
  final String confidence, source, warning;
  const AiPredictionModel({required this.estimatedWaitMinutes, this.confidence = 'low', this.source = 'local-heuristic', this.warning = 'Estimate only; not a live measurement.'});
  factory AiPredictionModel.fromMap(Map<String, dynamic> m) => AiPredictionModel(estimatedWaitMinutes: (m['estimated_wait_minutes'] as num?)?.toInt() ?? 0, confidence: '${m['confidence'] ?? 'low'}', source: '${m['source'] ?? 'unknown'}', warning: '${m['warning'] ?? 'Estimate only.'}');
  Map<String, dynamic> toMap() => {'estimated_wait_minutes': estimatedWaitMinutes, 'confidence': confidence, 'source': source, 'warning': warning};
}
