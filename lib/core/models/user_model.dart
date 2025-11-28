class UserModel {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatar;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatar,
    required this.role,
    this.createdAt,
    this.updatedAt,
  });
  
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? email;
  }
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both direct user object and nested user object
    final userData = json['user'] ?? json;
    
    return UserModel(
      id: userData['id'] as String? ?? '',
      email: userData['email'] as String? ?? '',
      firstName: userData['firstName'] as String?,
      lastName: userData['lastName'] as String?,
      phone: userData['phone'] as String?,
      avatar: userData['avatar'] as String?,
      role: userData['role'] as String? ?? 'user',
      createdAt: userData['createdAt'] != null
          ? DateTime.parse(userData['createdAt'] as String)
          : null,
      updatedAt: userData['updatedAt'] != null
          ? DateTime.parse(userData['updatedAt'] as String)
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? avatar,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

