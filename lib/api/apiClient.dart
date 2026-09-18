import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final BaseOptions options = BaseOptions(
  baseUrl: 'https://inversiones-zafiro.com/devodigital/api',
  // baseUrl: 'https://89.117.72.48/devodigital/api',
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 30),
  sendTimeout: const Duration(seconds: 30),
  headers: {
    'Content-Type': 'application/json'
  },
);

final Dio apiClient = Dio(options)
..interceptors.addAll(
  [LogInterceptor(requestHeader: true, requestBody: false, responseBody:  false),
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        const storage = FlutterSecureStorage();
        final token = await storage.read(key: 'ihEc.9TNJtihHZ');

        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if(error.response?.statusCode == 401) {
          const storage = FlutterSecureStorage();
          await storage.delete(key: 'ihEc.9TNJtihHZ');
        }

        return handler.next(error);
      }
    ),
  ]
);