class QueueModel {
  final String stationId;
  final int waitingCount, servingCount, completedCount;
  const QueueModel({required this.stationId, this.waitingCount = 0, this.servingCount = 0, this.completedCount = 0});
  factory QueueModel.fromTokenStatuses(String stationId, Iterable<String> statuses) {
    var waiting = 0, serving = 0, completed = 0;
    for (final status in statuses) {
      if (status == 'waiting') waiting++;
      if (status == 'called' || status == 'serving') serving++;
      if (status == 'completed') completed++;
    }
    return QueueModel(stationId: stationId, waitingCount: waiting, servingCount: serving, completedCount: completed);
  }
  Map<String, dynamic> toMap() => {'stationId': stationId, 'waitingCount': waitingCount, 'servingCount': servingCount, 'completedCount': completedCount};
}
