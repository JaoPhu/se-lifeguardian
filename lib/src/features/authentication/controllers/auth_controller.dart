import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../../profile/data/user_repository.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this.ref) : super(const AsyncData(null));
  final Ref ref;

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).registerWithEmail(email, password);
      await ref.read(userProvider.notifier).loadUser();
    });
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      await ref.read(userProvider.notifier).loadUser();
    });
  }

  Future<void> forgot(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendPasswordReset(email);
    });
  }

  // ✅ ปรับปรุงให้แยก Login / Register
  Future<void> loginWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithGoogle(isLogin: true);
      await ref.read(userProvider.notifier).loadUser();
    });
  }

  Future<void> registerWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithGoogle(isLogin: false);
      await ref.read(userProvider.notifier).loadUser();
    });
  }

  // ✅ ปรับปรุงให้แยก Login / Register
  Future<void> loginWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithApple(isLogin: true);
      await ref.read(userProvider.notifier).loadUser();
    });
  }

  Future<void> registerWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signInWithApple(isLogin: false);
      await ref.read(userProvider.notifier).loadUser();
    });
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signOut();
      await ref.read(userProvider.notifier).loadUser();
    });
  }

  Future<void> deleteAccount({String? password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).deleteAccount(password: password);
      await ref.read(userProvider.notifier).loadUser();
    });
  }
}
