import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:depd_mvvm_2025/data/app_exception.dart';
import 'package:depd_mvvm_2025/data/network/base_api_service.dart';
import 'package:depd_mvvm_2025/shared/shared.dart';

/// Implementasi BaseApiServices untuk menangani request GET, POST ke API RajaOngkir.
class NetworkApiServices implements BaseApiServices {
  // Gunakan http.Client() default daripada membuat custom
  // karena sudah handle network security config dari Android manifest
  /// Melakukan request GET ke endpoint
  /// Mengembalikan JSON ter-decode atau melempar AppException yang sesuai.
  @override
  Future<dynamic> getApiResponse(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      // Gunakan Uri.http bukan Uri.https untuk compatibility
      final uri = Uri.http(
        Const.baseUrl,
        Const.subUrl + endpoint,
        queryParams,
      );

      // Log request GET (untuk debug: URL + header).
      _logRequest('GET', uri, Const.apiKey);

      debugPrint("⏳ Memulai request HTTP...");

      // Set timeout untuk request dengan better error handling
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'key': Const.apiKey,
          'Accept': 'application/json',
          'Connection': 'keep-alive',
          'Host': 'rajaongkir.komerce.id', // Explicit Host header - penting untuk HTTP/1.1
        },
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint("❌ Timeout: Request tidak menerima respons dalam 60 detik");
          throw TimeoutException('Request timeout after 60 seconds');
        },
      );

      debugPrint("✓ Respons diterima: ${response.statusCode}");

      // Penanganan respons (status + decode JSON + pemetaan error).
      return _returnResponse(response);
    } on SocketException catch (e) {
      // Tidak ada koneksi jaringan atau DNS error.
      debugPrint('❌ SocketException: $e');
      throw NoInternetException('Network error: $e');
    } on TimeoutException catch (e) {
      // Waktu request melewati batas timeout.
      debugPrint('❌ TimeoutException: $e');
      throw FetchDataException('Network request timeout: $e');
    } on HttpException catch (e) {
      // HTTP client error (koneksi ditolak, certificate error, dll)
      debugPrint('❌ HttpException: $e');
      throw FetchDataException('HTTP Error: $e');
    } catch (e) {
      // Error tak terduga saat runtime.
      debugPrint('❌ Unexpected error: $e (Type: ${e.runtimeType})');
      throw FetchDataException('Unexpected error: $e');
    }
  }

  /// Melakukan request POST dengan body form-url-encoded.
  /// Mengembalikan JSON ter-decode atau melempar AppException yang sesuai.
  @override
  Future<dynamic> postApiResponse(String endpoint, dynamic data) async {
    try {
      // Gunakan Uri.http bukan Uri.https untuk compatibility
      final uri = Uri.http(Const.baseUrl, Const.subUrl + endpoint);

      // Log request POST termasuk payload body.
      _logRequest('POST', uri, Const.apiKey, data);

      debugPrint("⏳ Memulai POST request...");

      // Set timeout untuk request dengan better error handling
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'key': Const.apiKey,
          'Accept': 'application/json',
          'Connection': 'keep-alive',
          'Host': 'rajaongkir.komerce.id', // Explicit Host header - penting untuk HTTP/1.1
        },
        body: data,
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          debugPrint("❌ Timeout: POST request tidak menerima respons dalam 60 detik");
          throw TimeoutException('Request timeout after 60 seconds');
        },
      );

      debugPrint("✓ POST Respons diterima: ${response.statusCode}");

      // Delegasi parsing respons dan pemetaan error.
      return _returnResponse(response);
    } on SocketException catch (e) {
      // Perangkat offline atau network error
      debugPrint('❌ SocketException: $e');
      throw NoInternetException('Network error: $e');
    } on TimeoutException catch (e) {
      // Jaringan lambat atau server tidak merespon.
      debugPrint('❌ TimeoutException: $e');
      throw FetchDataException('Network request timeout: $e');
    } on HttpException catch (e) {
      // HTTP client error
      debugPrint('❌ HttpException: $e');
      throw FetchDataException('HTTP Error: $e');
    } on FormatException catch (e) {
      // Format respons tidak valid saat decode.
      debugPrint('❌ FormatException: $e');
      throw FetchDataException('Invalid response format: $e');
    } catch (e) {
      // Fallback umum.
      debugPrint('❌ Unexpected error: $e (Type: ${e.runtimeType})');
      throw FetchDataException('Unexpected error: $e');
    }
  }

  /// Print debug metadata request (method, URL, header, body).
  void _logRequest(String method, Uri uri, String apiKey, [dynamic data]) {
    debugPrint("═════════════════════════════════════════");
    debugPrint("== $method REQUEST ==");
    debugPrint("API Key: $apiKey");
    debugPrint("Host: ${uri.host}");
    debugPrint("Scheme: ${uri.scheme}");
    debugPrint("Final URL ($method): $uri");
    if (data != null) {
      debugPrint("Data body: $data");
    }
    debugPrint("═════════════════════════════════════════");
  }

  /// Print debug detail respons (status, content-type, body).
  void _logResponse(int statusCode, String? contentType, String body) {
    debugPrint("Status code: $statusCode");
    debugPrint("Content-Type: ${contentType ?? '-'}");

    if (body.isEmpty) {
      debugPrint("Body: <empty>");
    } else {
      String formattedBody;
      try {
        final decoded = jsonDecode(body);
        const encoder = JsonEncoder.withIndent('  ');
        formattedBody = encoder.convert(decoded);
      } catch (_) {
        formattedBody = body;
      }

      const maxLen = 8000;
      if (formattedBody.length > maxLen) {
        debugPrint(
          "Body (terpotong): ${formattedBody.substring(0, maxLen)}... [${formattedBody.length - maxLen} lebih karakter]",
        );
      } else {
        debugPrint("Body: $formattedBody");
      }
    }
    debugPrint("");
  }

  /// Memetakan HTTP response menjadi JSON ter-decode atau melempar exception bertipe.
  dynamic _returnResponse(http.Response response) {
    _logResponse(
      response.statusCode,
      response.headers['content-type'],
      response.body,
    );

    switch (response.statusCode) {
      case 200:
        try {
          final decoded = jsonDecode(response.body);
          // decoded null (tidak terjadi di Dart, tapi tetap dicek).
          if (decoded == null) throw FetchDataException('Empty JSON');
          return decoded;
        } catch (_) {
          // JSON tidak bisa di-decode pada status sukses.
          throw FetchDataException('Invalid JSON');
        }

      case 400:
        // Error dari sisi client: payload/parameter salah.
        throw BadRequestException(response.body);

      case 404:
        // Resource atau endpoint tidak ditemukan.
        throw NotFoundException('Not Found: ${response.body}');

      case 500:
        // Kegagalan dari sisi server.
        throw ServerErrorException('Server error: ${response.body}');

      default:
        // Status lain yang tidak ditangani.
        throw FetchDataException(
          'Unexpected status ${response.statusCode}: ${response.body}',
        );
    }
  }
}
