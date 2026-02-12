import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';
import 'storage_repository.dart';
import '../../authentication/providers/auth_providers.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final StorageRepository _storage;

  UserRepository(this._firestore, this._storage);

  Future<User?> fetchUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        return User(
          id: uid,
          name: data['name'] ?? '',
          username: data['username'] ?? '',
          email: data['email'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          avatarUrl: data['avatarUrl'] ?? '',
          birthDate: data['birthDate'] ?? '',
          age: data['age'] ?? '',
          gender: data['gender'] ?? '',
          bloodType: data['bloodType'] ?? '',
          height: data['height'] ?? '',
          weight: data['weight'] ?? '',
          medicalCondition: data['medicalCondition'] ?? '',
          currentMedications: data['currentMedications'] ?? '',
          drugAllergies: data['drugAllergies'] ?? '',
          foodAllergies: data['foodAllergies'] ?? '',
          inviteCode: data['inviteCode'],
          sessionId: data['sessionId'],
        );
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    return null;
  }

  Future<void> saveUser(User user) async {
    try {
      final uid = user.id;
      if (uid.isEmpty) {
        throw Exception('Cannot save user with empty ID');
      }

      final Map<String, dynamic> data = {
        'name': user.name,
        'username': user.username,
        'email': user.email.trim().toLowerCase(),
        'phoneNumber': user.phoneNumber,
        'avatarUrl': user.avatarUrl,
        'birthDate': user.birthDate,
        'age': user.age,
        'gender': user.gender,
        'bloodType': user.bloodType,
        'height': user.height,
        'weight': user.weight,
        'medicalCondition': user.medicalCondition,
        'currentMedications': user.currentMedications,
        'drugAllergies': user.drugAllergies,
        'foodAllergies': user.foodAllergies,
      };

      if (user.inviteCode != null) {
        data['inviteCode'] = user.inviteCode;
      } else {
        // Generate code if missing
        final code = await generateUniqueInviteCode();
        data['inviteCode'] = code;
      }

      await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user: $e');
      rethrow;
    }
  }

  Future<String> generateUniqueInviteCode() async {
    final random = Random();
    String code = '';
    bool isUnique = false;

    // We use 6 digits (1,000,000 possibilities) to drastically reduce collisions
    while (!isUnique) {
      final num = random.nextInt(1000000).toString().padLeft(6, '0');
      code = 'LG-$num';

      // Check uniqueness in Firestore
      final query = await _firestore
          .collection('users')
          .where('inviteCode', isEqualTo: code)
          .get();
      
      if (query.docs.isEmpty) {
        isUnique = true;
      }
    }
    return code;
  }

  Future<String> uploadAvatar(String uid, File file) async {
    final downloadUrl = await _storage.uploadProfileImage(uid, file);
    // Use set with merge: true instead of update() to support new users
    await _firestore.collection('users').doc(uid).set({'avatarUrl': downloadUrl}, SetOptions(merge: true));
    return downloadUrl;
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final firestore = FirebaseFirestore.instance;
  final storage = ref.watch(storageRepositoryProvider);
  return UserRepository(firestore, storage);
});

// Managing State
class UserNotifier extends StateNotifier<User> {
  final UserRepository _repo;
  final auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  String? _currentSessionId;
  StreamSubscription? _sessionSubscription;
  
  UserNotifier(this._repo, this._auth, this._firestore) : super(const User(
      id: '', name: '', username: '', email: '', phoneNumber: '', avatarUrl: '',
      birthDate: '', age: '', gender: '', bloodType: '',
      height: '', weight: '', medicalCondition: '',
      currentMedications: '', drugAllergies: '', foodAllergies: ''));

  Future<void> loadUser() async {
    final firebaseUser = _auth.currentUser;
    
    if (firebaseUser != null) {
      final uid = firebaseUser.uid;
      final user = await _repo.fetchUser(uid);
      
      if (user != null) {
        // Check if name/email is missing in Firestore but available in Auth
        bool needsUpdate = false;
        String updatedName = user.name;
        String updatedEmail = user.email;

        if (updatedName.isEmpty && firebaseUser.displayName != null && firebaseUser.displayName!.isNotEmpty) {
          updatedName = firebaseUser.displayName!;
          needsUpdate = true;
        }

        if (updatedEmail.isEmpty && firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
          updatedEmail = firebaseUser.email!;
          needsUpdate = true;
        }

        User finalUser = user;
        if (needsUpdate) {
          print('UserNotifier: Syncing missing profile data from Auth');
          finalUser = user.copyWith(name: updatedName, email: updatedEmail);
          // Don't await this to avoid blocking UI, but trigger save
          _repo.saveUser(finalUser);
        }

        state = finalUser;
        _currentSessionId = finalUser.sessionId;
        
        // Setup session listener
        _listenToSessionChanges(uid);

        // Auto-generate invite code if missing
        if (finalUser.inviteCode == null || finalUser.inviteCode!.isEmpty) {
          try {
            final code = await _repo.generateUniqueInviteCode();
            final updatedUserWithCode = finalUser.copyWith(inviteCode: code);
            await _repo.saveUser(updatedUserWithCode);
            state = updatedUserWithCode;
          } catch (e) {
            print('Error auto-generating invite code for existing user: $e');
          }
        }
      } else {
        // Doc doesn't exist yet, but we have a logged in user in Auth.
        // During registration, this is expected. We pre-fill ID and Email from Auth.
        state = User(
          id: firebaseUser.uid, 
          name: '', 
          username: '', 
          email: firebaseUser.email ?? '', 
          phoneNumber: '', 
          avatarUrl: '', 
          birthDate: '', 
          age: '', 
          gender: '', 
          bloodType: '', 
          height: '', 
          weight: '', 
          medicalCondition: '', 
          currentMedications: '', 
          drugAllergies: '', 
          foodAllergies: '');
      }
    } else {
      _currentSessionId = null;
      _sessionSubscription?.cancel();
      _sessionSubscription = null;
      // No user logged in, reset to initial state
      state = const User(
        id: '', name: '', username: '', email: '', phoneNumber: '', avatarUrl: '', 
        birthDate: '', age: '', gender: '', bloodType: '', height: '', weight: '', 
        medicalCondition: '', currentMedications: '', drugAllergies: '', foodAllergies: '');
    }
  }

  void _listenToSessionChanges(String uid) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists && snapshot.data() != null) {
        final serverSessionId = snapshot.data()!['sessionId'] as String?;
        if (serverSessionId != null) {
          if (_currentSessionId == null) {
            // Initial load from stream
            _currentSessionId = serverSessionId;
          } else if (serverSessionId != _currentSessionId) {
            // Mismatch! Someone else logged in.
            print('Session mismatch! Logging out. Local: $_currentSessionId, Server: $serverSessionId');
            await _auth.signOut();
            _sessionSubscription?.cancel();
            _sessionSubscription = null;
            _currentSessionId = null;
            state = const User(
              id: '', name: '', username: '', email: '', phoneNumber: '', avatarUrl: '', 
              birthDate: '', age: '', gender: '', bloodType: '', height: '', weight: '', 
              medicalCondition: '', currentMedications: '', drugAllergies: '', foodAllergies: '');
          }
        }
      }
    });
  }

  Future<void> updateUser(User user) async {
    state = user; 
    await _repo.saveUser(user);
    await loadUser();
  }
  
  void setUser(User user) {
    state = user;
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, User>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = FirebaseFirestore.instance;
  return UserNotifier(repo, firebaseAuth, firestore);
});
