part of 'shared.dart';

class Const {
  // Base URL - gunakan domain name bukan IP agar Host header berfungsi dengan baik
  static const String baseUrl = "rajaongkir.komerce.id";
  
  static const String subUrl = "/api/v1/";
  
  // API Key dari Shipping Cost (Komerce) - valid, tidak ada expiry
  // Hardcoded fallback karena .env tidak work reliable di web/emulator
  static String apiKey = "Pdtt1zeX3033b8c6728a617fU84JewYV";
}
