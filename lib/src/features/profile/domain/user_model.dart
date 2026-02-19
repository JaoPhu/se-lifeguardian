class User {
  final String id;
  final String name;
  final String username;
  final String email;
  final String phoneNumber;
  final String avatarUrl;
  final String birthDate;
  final String age;
  final String gender;
  final String bloodType;
  final String height;
  final String weight;
  final String medicalCondition;
  final String currentMedications;
  final String drugAllergies;
  final String foodAllergies;
  final String? inviteCode;
  final String? sessionId;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.birthDate,
    required this.age,
    required this.gender,
    required this.bloodType,
    required this.height,
    required this.weight,
    required this.medicalCondition,
    required this.currentMedications,
    required this.drugAllergies,
    required this.foodAllergies,
    this.inviteCode,
    this.sessionId,
  });

  User copyWith({
    String? id,
    String? name,
    String? username,
    String? email,
    String? phoneNumber,
    String? avatarUrl,
    String? birthDate,
    String? age,
    String? gender,
    String? bloodType,
    String? height,
    String? weight,
    String? medicalCondition,
    String? currentMedications,
    String? drugAllergies,
    String? foodAllergies,
    String? inviteCode,
    String? sessionId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      birthDate: birthDate ?? this.birthDate,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      currentMedications: currentMedications ?? this.currentMedications,
      drugAllergies: drugAllergies ?? this.drugAllergies,
      foodAllergies: foodAllergies ?? this.foodAllergies,
      inviteCode: inviteCode ?? this.inviteCode,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  bool get isProfileComplete {
    return name.isNotEmpty &&
        username.isNotEmpty &&
        phoneNumber.isNotEmpty &&
        birthDate.isNotEmpty &&
        bloodType.isNotEmpty;
  }
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is User &&
      other.id == id &&
      other.name == name &&
      other.username == username &&
      other.email == email &&
      other.phoneNumber == phoneNumber &&
      other.avatarUrl == avatarUrl &&
      other.birthDate == birthDate &&
      other.age == age &&
      other.gender == gender &&
      other.bloodType == bloodType &&
      other.height == height &&
      other.weight == weight &&
      other.medicalCondition == medicalCondition &&
      other.currentMedications == currentMedications &&
      other.drugAllergies == drugAllergies &&
      other.foodAllergies == foodAllergies &&
      other.inviteCode == inviteCode &&
      other.sessionId == sessionId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
      name.hashCode ^
      username.hashCode ^
      email.hashCode ^
      phoneNumber.hashCode ^
      avatarUrl.hashCode ^
      birthDate.hashCode ^
      age.hashCode ^
      gender.hashCode ^
      bloodType.hashCode ^
      height.hashCode ^
      weight.hashCode ^
      medicalCondition.hashCode ^
      currentMedications.hashCode ^
      drugAllergies.hashCode ^
      foodAllergies.hashCode ^
      inviteCode.hashCode ^
      sessionId.hashCode;
  }
}
