import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';
import 'auth_service.dart';

class ApiService {
  static final ApiService instance = ApiService._privateConstructor();
  ApiService._privateConstructor();

  late Dio _dio;
  final String baseUrl = 'https://echtgutebienen.de/api'; // Production API
  // Alternative URLs:
  // For local testing: 'https://echtgutebienen.test/api'
  // For network testing: 'http://192.168.178.90:80/api'
  // For localhost testing: 'http://localhost:8000/api'
  
  void initialize() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add authentication interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests if available
        final authHeader = AuthService.instance.getAuthHeader();
        if (authHeader != null) {
          options.headers['Authorization'] = authHeader;
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized responses
        if (error.response?.statusCode == 401) {
          print('API: Received 401 - token expired or invalid');
          // Let AuthService handle the logout
          await AuthService.instance.logout();
        }
        handler.next(error);
      },
    ));

    // Add interceptors for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (o) => print('API: $o'),
    ));
  }

  // Check network connectivity
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  // ✅ GET /api/codes - Retrieve all codes
  Future<List<Map<String, dynamic>>> getCodes() async {
    try {
      print('API: Fetching codes from server...');
      final response = await _dio.get('/codes');
      print('API: Successfully fetched ${response.data.length} codes');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      print('API Error (getCodes): ${e.message}');
      throw ApiException('Failed to fetch codes: ${e.message}');
    }
  }

  // ✅ PUT /api/codes/{id} - Update code status/notes
  Future<Map<String, dynamic>> updateCode(String id, {
    String? status,
    String? notes,
  }) async {
    try {
      print('API: Updating code $id with status: $status, notes: $notes');
      final response = await _dio.put('/codes/$id', data: {
        if (status != null) 'status': status,
        if (notes != null) 'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('API: Successfully updated code $id');
      return response.data;
    } on DioException catch (e) {
      print('API Error (updateCode): ${e.message}');
      throw ApiException('Failed to update code: ${e.message}');
    }
  }

  // ✅ GET /api/box/{barcode} - Get box information
  Future<Map<String, dynamic>> getBoxInfo(String barcode) async {
    try {
      print('API: Fetching box info for barcode: $barcode');
      final response = await _dio.get('/box/$barcode');
      print('API: Successfully fetched box info for $barcode');
      return response.data;
    } on DioException catch (e) {
      print('API Error (getBoxInfo): ${e.message}');
      throw ApiException('Failed to fetch box info: ${e.message}');
    }
  }

  // ✅ POST /api/scans - Submit new scan
  Future<Map<String, dynamic>> submitScan({
    required String barcode,
    required String format,
    String? action,
    String? notes,
    String? userId,
  }) async {
    try {
      print('API: Submitting new scan for barcode: $barcode');
      final response = await _dio.post('/scans', data: {
        'barcode': barcode,
        'format': format,
        'action': action ?? 'scanned',
        'notes': notes,
        'user_id': userId,
        'scanned_at': DateTime.now().toIso8601String(),
      });
      print('API: Successfully submitted scan for $barcode');
      return response.data;
    } on DioException catch (e) {
      print('API Error (submitScan): ${e.message}');
      throw ApiException('Failed to submit scan: ${e.message}');
    }
  }

  // Sync local codes to server
  Future<void> syncCodesToServer(List<Code> localCodes) async {
    if (!await isConnected()) {
      print('API: No internet connection, skipping sync');
      return;
    }

    print('API: Starting sync of ${localCodes.length} local codes');
    
    for (final code in localCodes) {
      try {
        await submitScan(
          barcode: code.text ?? '',
          format: code.formatName,
          notes: 'Synced from local storage',
        );
        print('API: Synced code: ${code.text}');
      } catch (e) {
        print('API: Failed to sync code ${code.text}: $e');
      }
    }
    
    print('API: Sync completed');
  }

  // Test all API endpoints manually
  Future<void> testAllEndpoints() async {
    print('\n🧪 === API ENDPOINT TESTING ===');
    
    if (!await isConnected()) {
      print('❌ No internet connection - cannot test APIs');
      return;
    }

    try {
      // Test 1: Submit a test scan
      print('\n1️⃣ Testing POST /api/scans...');
      await submitScan(
        barcode: 'TEST123456',
        format: 'QR_CODE',
        action: 'test_scan',
        notes: 'API test scan',
      );
      
      // Test 2: Get all codes
      print('\n2️⃣ Testing GET /api/codes...');
      final codes = await getCodes();
      print('Retrieved ${codes.length} codes');
      
      // Test 3: Get box info (with test barcode)
      print('\n3️⃣ Testing GET /api/box/{barcode}...');
      try {
        await getBoxInfo('TEST123456');
      } catch (e) {
        print('Box info test: $e (expected if box doesn\'t exist)');
      }
      
      // Test 4: Update a code (if codes exist)
      if (codes.isNotEmpty) {
        print('\n4️⃣ Testing PUT /api/codes/{id}...');
        final firstCode = codes.first;
        await updateCode(
          firstCode['id'].toString(),
          status: 'completed',
          notes: 'Updated via API test',
        );
      }
      
      print('\n✅ API testing completed successfully!');
      
    } catch (e) {
      print('\n❌ API testing failed: $e');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}