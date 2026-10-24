class UserModel {
  final String uid, name, email, phone, role, accountStatus, ownerApplicationStatus;
  const UserModel({required this.uid, this.name = '', this.email = '', this.phone = '', this.role = 'customer', this.accountStatus = 'active', this.ownerApplicationStatus = 'none'});
  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(uid: '${m['uid'] ?? ''}', name: '${m['name'] ?? ''}', email: '${m['email'] ?? ''}', phone: '${m['phone'] ?? ''}', role: '${m['role'] ?? 'customer'}', accountStatus: '${m['accountStatus'] ?? 'active'}', ownerApplicationStatus: '${m['ownerApplicationStatus'] ?? 'none'}');
  Map<String, dynamic> toMap() => {'uid': uid, 'name': name, 'email': email, 'phone': phone, 'role': role, 'accountStatus': accountStatus, 'ownerApplicationStatus': ownerApplicationStatus};
}
