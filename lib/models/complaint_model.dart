class ComplaintModel {
  final String id, customerId, category, description, status;
  const ComplaintModel({required this.id, required this.customerId, this.category = 'Other', this.description = '', this.status = 'open'});
  factory ComplaintModel.fromMap(String id, Map<String, dynamic> m) => ComplaintModel(id: id, customerId: '${m['customerId'] ?? ''}', category: '${m['category'] ?? 'Other'}', description: '${m['description'] ?? ''}', status: '${m['status'] ?? 'open'}');
  Map<String, dynamic> toMap() => {'customerId': customerId, 'category': category, 'description': description, 'status': status};
}
