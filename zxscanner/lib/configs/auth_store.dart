import 'package:mobx/mobx.dart';
import '../models/user.dart';
import '../utils/auth_service.dart';

part 'auth_store.g.dart';

class AuthStore = AuthStoreBase with _$AuthStore;

abstract class AuthStoreBase with Store {
  final AuthService _authService = AuthService.instance;

  @observable
  bool isLoading = false;

  @observable
  bool isAuthenticated = false;

  @observable
  User? currentUser;

  @observable
  String? errorMessage;

  @action
  Future<void> initialize() async {
    await _authService.initialize();
    isAuthenticated = _authService.isAuthenticated;
    currentUser = _authService.currentUser;
    
    // Verify token if we think we're authenticated
    if (isAuthenticated) {
      await verifyAuthentication();
    }
  }

  @action
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading = true;
    errorMessage = null;
    
    try {
      final success = await _authService.login(
        email: email,
        password: password,
      );
      
      if (success) {
        isAuthenticated = true;
        currentUser = _authService.currentUser;
        errorMessage = null;
      } else {
        errorMessage = 'Invalid email or password';
      }
      
      return success;
    } catch (e) {
      errorMessage = 'Login failed: ${e.toString()}';
      return false;
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> logout() async {
    isLoading = true;
    
    try {
      await _authService.logout();
      isAuthenticated = false;
      currentUser = null;
      errorMessage = null;
    } catch (e) {
      errorMessage = 'Logout failed: ${e.toString()}';
    } finally {
      isLoading = false;
    }
  }

  @action
  Future<void> verifyAuthentication() async {
    if (!isAuthenticated) return;
    
    try {
      final isValid = await _authService.verifyToken();
      
      if (!isValid) {
        isAuthenticated = false;
        currentUser = null;
        errorMessage = 'Session expired. Please log in again.';
      } else {
        currentUser = _authService.currentUser;
      }
    } catch (e) {
      print('AuthStore: Token verification failed: $e');
      // Don't logout on verification errors unless token is definitely invalid
    }
  }

  @action
  void clearError() {
    errorMessage = null;
  }

  @computed
  String get userName => currentUser?.name ?? '';

  @computed
  String get userEmail => currentUser?.email ?? '';
}

// Global auth store instance
final AuthStore authStore = AuthStore();