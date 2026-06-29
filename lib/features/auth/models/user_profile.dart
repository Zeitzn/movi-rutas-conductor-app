import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  final String uuid;
  final String username;
  final String firstName;
  final String lastName;
  final String companyUuid;
  final String companyCode;

  const UserProfile({
    required this.uuid,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.companyUuid,
    required this.companyCode,
  });

  UserProfile copyWith({
    String? uuid,
    String? username,
    String? firstName,
    String? lastName,
    String? companyUuid,
    String? companyCode,
  }) {
    return UserProfile(
      uuid: uuid ?? this.uuid,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      companyUuid: companyUuid ?? this.companyUuid,
      companyCode: companyCode ?? this.companyCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'companyUuid': companyUuid,
      'companyCode': companyCode,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uuid: json['uuid'] as String,
      username: json['username'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      companyUuid: json['companyUuid'] as String,
      companyCode: json['companyCode'] as String,
    );
  }

  @override
  List<Object?> get props => [
    uuid,
    username,
    firstName,
    lastName,
    companyUuid,
    companyCode,
  ];

  @override
  String toString() {
    return 'UserProfile(uuid: $uuid, username: $username, '
        'firstName: $firstName, lastName: $lastName, '
        'companyUuid: $companyUuid, companyCode: $companyCode)';
  }
}
