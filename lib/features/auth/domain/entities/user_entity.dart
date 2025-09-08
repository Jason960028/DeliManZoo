import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    uid,
    email,
    displayName,
    photoURL,
    createdAt,
    updatedAt,
  ];

  @override
  String toString() {
    return 'UserEntity(uid: $uid, email: $email, displayName: $displayName, photoURL: $photoURL, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  UserEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}