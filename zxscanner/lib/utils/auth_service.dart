import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService instance = AuthService._privateConstructor();
  AuthService._privateConstructor();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  String? _currentToken;
  User? _currentUser;

  // Getters
  String? get currentToken => _currentToken;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentToken != null && _currentUser != null;

  /// Initialize AuthService - load token and user from secure storage
  Future<void> initialize() async {
    await _loadTokenFromStorage();
    await _loadUserFromStorage();
  }

  /// Login with email and password
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      print('AuthService: Attempting login for: $email');
      
      final response = await Dio().post(
        '${ApiService.instance.baseUrl}/login',
        data: {
          'email': email,
          'password': password,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Extract token and user from response
        final String token = data['token'] as String;
        final Map<String, dynamic> userData = data['user'] as Map<String, dynamic>;
        final User user = User.fromJson(userData);

        // Store token and user securely
        await _storeToken(token);
        await _storeUser(user);

        // Update current state
        _currentToken = token;
        _currentUser = user;

        print('AuthService: Login successful for user: ${user.name}');
        return true;
      }
      
      print('AuthService: Login failed - unexpected status code: ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      print('AuthService: Login failed - ${e.response?.data ?? e.message}');
      return false;
    } catch (e) {
      print('AuthService: Login failed - unexpected error: $e');
      return false;
    }
  }

  /// Logout - clear token and user data
  Future<void> logout() async {
    try {
      // Call logout endpoint if we have a token
      if (_currentToken != null) {
        await Dio().post(
          '${ApiService.instance.baseUrl}/logout',
          options: Options(
            headers: {
              'Authorization': 'Bearer $_currentToken',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );
      }
    } catch (e) {
      print('AuthService: Logout API call failed: $e');
      // Continue with local logout even if API call fails
    }

    // Clear local storage
    await _clearStorage();
    
    // Clear current state
    _currentToken = null;
    _currentUser = null;
    
    print('AuthService: Logout completed');
  }

  /// Verify current token is still valid
  Future<bool> verifyToken() async {
    if (_currentToken == null) {
      return false;
    }

    try {
      final response = await Dio().get(
        '${ApiService.instance.baseUrl}/user',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_currentToken',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        // Update user data if different
        final userData = response.data as Map<String, dynamic>;
        final user = User.fromJson(userData);
        
        if (_currentUser == null || _currentUser != user) {
          await _storeUser(user);
          _currentUser = user;
        }
        
        return true;
      }
      
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token is invalid, clear it
        await logout();
        return false;
      }
      
      // For other errors, assume token might still be valid
      print('AuthService: Token verification failed: ${e.message}');
      return true; // Don't logout on network errors
    } catch (e) {
      print('AuthService: Token verification error: $e');
      return true; // Don't logout on unexpected errors
    }
  }

  /// Get the current auth token for API requests
  Future<String?> getAuthToken() async {
    if (_currentToken == null) {
      await _loadTokenFromStorage();
    }
    return _currentToken;
  }

  /// Get authorization header value
  String? getAuthHeader() {
    return _currentToken != null ? 'Bearer $_currentToken' : null;
  }

  // Private methods

  Future<void> _storeToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> _storeUser(User user) async {
    await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  Future<void> _loadTokenFromStorage() async {
    try {
      _currentToken = await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      print('AuthService: Failed to load token from storage: $e');
      _currentToken = null;
    }
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final userJson = await _secureStorage.read(key: _userKey);
      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        _currentUser = User.fromJson(userData);
      }
    } catch (e) {
      print('AuthService: Failed to load user from storage: $e');
      _currentUser = null;
    }
  }

  Future<void> _clearStorage() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
    } catch (e) {
      print('AuthService: Failed to clear storage: $e');
    }
  }
}

/// Exception for authentication-related errors
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  
  @override
  String toString() => 'AuthException: $message';
}