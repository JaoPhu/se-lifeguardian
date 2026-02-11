import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

class UserNotifier extends Notifier<User> {
  @override
  User build() {
    return const User(
      id: 'u1',
      name: 'Somchai Jaidee',
      username: 'somchai.j',
      email: 'somchai@example.com',
      avatarUrl: 'https://i.pravatar.cc/300?u=somchai',
      birthDate: '01/01/1980',
      age: '44',
      gender: 'Male',
      bloodType: 'O+',
      height: '175',
      weight: '70',
      medicalCondition: 'Hypertension',
      currentMedications: 'Amlodipine 5mg',
      drugAllergies: 'None',
      foodAllergies: 'Peanuts',
    );
  }

  void updateUser(User user) {
    state = user;
  }
}

final userProvider = NotifierProvider<UserNotifier, User>(UserNotifier.new);
