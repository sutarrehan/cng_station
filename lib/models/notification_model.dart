class NotificationModel {
  final String id, title, body, type;
  final bool read;
  const NotificationModel({required this.id, this.title = '', this.body = '', this.type = 'general', this.read = false});
  factory NotificationModel.fromMap(String id, Map<String, dynamic> m) => NotificationModel(id: id, title: '${m['title'] ?? ''}', body: '${m['body'] ?? ''}', type: '${m['type'] ?? 'general'}', read: m['read'] == true);
  Map<String, dynamic> toMap() => {'title': title, 'body': body, 'type': type, 'read': read};
}
